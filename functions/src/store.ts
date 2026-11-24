import type { Firestore, Transaction } from 'firebase-admin/firestore';

export type StoreDoc = Record<string, unknown>;

export interface WhereFilter {
  field: string;
  op: '==';
  value: unknown;
}

export interface QueryMatch<T extends StoreDoc = StoreDoc> {
  id: string;
  data: T;
}

export interface StoreTransaction {
  get<T extends StoreDoc = StoreDoc>(collection: string, id: string): Promise<T | null>;
  query<T extends StoreDoc = StoreDoc>(
    collection: string,
    filters: WhereFilter[],
  ): Promise<Array<QueryMatch<T>>>;
  set<T extends StoreDoc = StoreDoc>(collection: string, id: string, data: T): Promise<void>;
  update(collection: string, id: string, patch: Record<string, unknown>): Promise<void>;
}

export interface DataStore {
  runTransaction<R>(fn: (tx: StoreTransaction) => Promise<R>): Promise<R>;
}

function cloneDoc<T>(value: T): T {
  return structuredClone(value);
}

/**
 * Transactional in-memory Firestore-compatible store for deterministic Node tests.
 * Enforces Firestore's reads-before-writes rule and rolls back all writes on throw.
 */
export class InMemoryStore implements DataStore {
  private readonly collections = new Map<string, Map<string, StoreDoc>>();

  public seed<T extends StoreDoc>(collection: string, id: string, data: T): void {
    const col = this.ensureCollection(this.collections, collection);
    col.set(id, cloneDoc(data));
  }

  public getDoc<T extends StoreDoc = StoreDoc>(collection: string, id: string): T | null {
    const doc = this.collections.get(collection)?.get(id);
    return doc ? (cloneDoc(doc) as T) : null;
  }

  public listCollection<T extends StoreDoc = StoreDoc>(
    collection: string,
  ): Array<QueryMatch<T>> {
    const col = this.collections.get(collection);
    if (!col) return [];
    const results: Array<QueryMatch<T>> = [];
    for (const [id, data] of col.entries()) {
      results.push({ id, data: cloneDoc(data) as T });
    }
    return results;
  }

  public async runTransaction<R>(fn: (tx: StoreTransaction) => Promise<R>): Promise<R> {
    const working = new Map<string, Map<string, StoreDoc>>();
    for (const [colName, colDocs] of this.collections.entries()) {
      const copied = new Map<string, StoreDoc>();
      for (const [docId, docData] of colDocs.entries()) {
        copied.set(docId, cloneDoc(docData));
      }
      working.set(colName, copied);
    }

    let hasWritten = false;
    const assertReadsBeforeWrites = () => {
      if (hasWritten) {
        throw new Error('Firestore transactions require all reads to execute before writes.');
      }
    };

    const tx: StoreTransaction = {
      get: async <T extends StoreDoc = StoreDoc>(
        collection: string,
        id: string,
      ): Promise<T | null> => {
        assertReadsBeforeWrites();
        const doc = working.get(collection)?.get(id);
        return doc ? (cloneDoc(doc) as T) : null;
      },
      query: async <T extends StoreDoc = StoreDoc>(
        collection: string,
        filters: WhereFilter[],
      ): Promise<Array<QueryMatch<T>>> => {
        assertReadsBeforeWrites();
        const col = working.get(collection);
        if (!col) return [];
        const matches: Array<QueryMatch<T>> = [];
        for (const [id, data] of col.entries()) {
          const ok = filters.every((f) => data[f.field] === f.value);
          if (ok) {
            matches.push({ id, data: cloneDoc(data) as T });
          }
        }
        return matches;
      },
      set: async <T extends StoreDoc = StoreDoc>(
        collection: string,
        id: string,
        data: T,
      ): Promise<void> => {
        hasWritten = true;
        const col = this.ensureCollection(working, collection);
        col.set(id, cloneDoc(data));
      },
      update: async (
        collection: string,
        id: string,
        patch: Record<string, unknown>,
      ): Promise<void> => {
        hasWritten = true;
        const col = working.get(collection);
        const existing = col?.get(id);
        if (!existing) {
          throw new Error(`Document '${collection}/${id}' does not exist for update.`);
        }
        col!.set(id, { ...existing, ...cloneDoc(patch) });
      },
    };

    const result = await fn(tx);

    // Commit staged snapshot atomically only after fn completes cleanly.
    this.collections.clear();
    for (const [colName, colDocs] of working.entries()) {
      this.collections.set(colName, colDocs);
    }
    return result;
  }

  private ensureCollection(
    root: Map<string, Map<string, StoreDoc>>,
    name: string,
  ): Map<string, StoreDoc> {
    let col = root.get(name);
    if (!col) {
      col = new Map<string, StoreDoc>();
      root.set(name, col);
    }
    return col;
  }
}

/**
 * Production Cloud Firestore Admin SDK store adapter.
 */
export class FirestoreStore implements DataStore {
  constructor(private readonly db: Firestore) {}

  public async runTransaction<R>(fn: (tx: StoreTransaction) => Promise<R>): Promise<R> {
    return this.db.runTransaction(async (fsTx: Transaction) => {
      const tx: StoreTransaction = {
        get: async <T extends StoreDoc = StoreDoc>(
          collection: string,
          id: string,
        ): Promise<T | null> => {
          const snap = await fsTx.get(this.db.collection(collection).doc(id));
          if (!snap.exists) return null;
          return snap.data() as T;
        },
        query: async <T extends StoreDoc = StoreDoc>(
          collection: string,
          filters: WhereFilter[],
        ): Promise<Array<QueryMatch<T>>> => {
          let q: FirebaseFirestore.Query = this.db.collection(collection);
          for (const f of filters) {
            q = q.where(f.field, f.op, f.value);
          }
          const snap = await fsTx.get(q);
          return snap.docs.map((d) => ({
            id: d.id,
            data: d.data() as T,
          }));
        },
        set: async <T extends StoreDoc = StoreDoc>(
          collection: string,
          id: string,
          data: T,
        ): Promise<void> => {
          fsTx.set(this.db.collection(collection).doc(id), data);
        },
        update: async (
          collection: string,
          id: string,
          patch: Record<string, unknown>,
        ): Promise<void> => {
          fsTx.update(this.db.collection(collection).doc(id), patch);
        },
      };
      return fn(tx);
    });
  }
}
