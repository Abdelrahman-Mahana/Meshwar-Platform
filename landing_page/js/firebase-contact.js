import { initializeApp } from "https://www.gstatic.com/firebasejs/11.4.0/firebase-app.js";
import {
  getFirestore,
  collection,
  doc,
  setDoc,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/11.4.0/firebase-firestore.js";

const firebaseConfig = {
  projectId: "mashwar-qatar-2026-ec99d",
  appId: "1:820084343406:web:ad6ce9779a06584bd35c7f",
  storageBucket: "mashwar-qatar-2026-ec99d.firebasestorage.app",
  apiKey: "AIzaSyB-wPAJ3Dy4cMkuyaRcnYCh6kn6kk5vzTc",
  authDomain: "mashwar-qatar-2026-ec99d.firebaseapp.com",
  messagingSenderId: "820084343406",
  measurementId: "G-S2DSLPL6RB",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const INQUIRIES_COLLECTION = "investor_inquiries";
const NOTIFY_ENDPOINT = "https://formsubmit.co/ajax/abdelrahmanmahana01@gmail.com";
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function getCurrentLang() {
  return document.documentElement.lang === "en" ? "en" : "ar";
}

function getI18nText(key, fallbackAr, fallbackEn) {
  const lang = getCurrentLang();
  const dict = window.MASHWAR_I18N && window.MASHWAR_I18N[lang];
  if (dict && typeof dict[key] === "string" && dict[key].trim()) {
    return dict[key];
  }
  return lang === "en" ? fallbackEn : fallbackAr;
}

function setStatusState({ statusEl, statusRefEl, errorEl, type, message, refCode }) {
  if (!statusEl || !errorEl) return;
  if (type === "success") {
    errorEl.textContent = "";
    errorEl.classList.remove("is-visible");
    const textSpan = statusEl.querySelector('[data-i18n="f_success"]');
    if (textSpan) {
      textSpan.textContent = message;
    } else {
      statusEl.textContent = message;
    }
    if (statusRefEl) {
      statusRefEl.textContent = refCode ? `(#${refCode})` : "";
    }
    statusEl.classList.add("is-visible");
    return;
  }
  statusEl.classList.remove("is-visible");
  errorEl.textContent = message;
  errorEl.classList.add("is-visible");
}

function notifyFounderEmail(payload, shortRef) {
  const emailBody = {
    _subject: `MASHWAR Qatar — New Inquiry #${shortRef} (${payload.fullName})`,
    _replyto: payload.email,
    _template: "table",
    _captcha: "false",
    Reference_ID: `#${shortRef}`,
    Firestore_Doc_ID: payload.id,
    Full_Name: payload.fullName,
    Organization: payload.organization,
    Email: payload.email,
    Phone: payload.phone || "Not provided",
    Inquiry_Type: payload.inquiryType,
    Language: (payload.lang || "ar").toUpperCase(),
    Notes: payload.notes || "None",
    Page_URL: payload.pageUrl || window.location.href,
    Submitted_At_UTC: payload.createdAtIso,
  };

  return fetch(NOTIFY_ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify(emailBody),
  }).catch(() => null);
}

function initInvestorContactForm() {
  const form = document.getElementById("investor-form");
  const statusEl = document.getElementById("investor-form-status");
  const statusRefEl = document.getElementById("investor-form-ref");
  const errorEl = document.getElementById("investor-form-error");
  const submitBtn = document.getElementById("investor-submit-btn");

  if (!form || !statusEl || !errorEl || !submitBtn) return;
  if (form.dataset.firebaseBound === "1") return;
  form.dataset.firebaseBound = "1";

  let isSubmitting = false;

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (isSubmitting) return;

    const honeypot = (document.getElementById("inv-website")?.value || "").trim();
    if (honeypot) {
      form.reset();
      return;
    }

    const fullName = (document.getElementById("inv-name")?.value || "").trim();
    const organization = (document.getElementById("inv-org")?.value || "").trim();
    const email = (document.getElementById("inv-email")?.value || "").trim();
    const phone = (document.getElementById("inv-phone")?.value || "").trim();
    const interestEl = document.getElementById("inv-interest");
    const inquiryType = (
      interestEl?.options?.[interestEl.selectedIndex]?.textContent ||
      interestEl?.value ||
      ""
    ).trim();
    const notes = (document.getElementById("inv-notes")?.value || "").trim();

    if (
      fullName.length < 2 ||
      organization.length < 1 ||
      email.length < 5 ||
      !EMAIL_RE.test(email) ||
      inquiryType.length < 2
    ) {
      setStatusState({
        statusEl,
        errorEl,
        type: "error",
        message: getI18nText(
          "f_err_validation",
          "يرجى التأكد من إدخال الاسم والجهة وبريد إلكتروني صحيح قبل الإرسال.",
          "Please provide a valid name, organization, and email address before submitting."
        ),
      });
      return;
    }

    isSubmitting = true;
    submitBtn.disabled = true;
    submitBtn.setAttribute("aria-busy", "true");
    submitBtn.textContent = getI18nText(
      "f_sending",
      "جاري إرسال طلبك وتأمينه...",
      "Sending and securing your inquiry..."
    );

    try {
      const inquiryRef = doc(collection(db, INQUIRIES_COLLECTION));
      const lang = getCurrentLang();
      const createdAtIso = new Date().toISOString();
      const pageUrl = String(window.location.href || "").trim().slice(0, 300);

      const record = {
        id: inquiryRef.id,
        fullName: fullName.slice(0, 120),
        organization: organization.slice(0, 160),
        email: email.slice(0, 160),
        inquiryType: inquiryType.slice(0, 200),
        lang,
        source: "landing_page",
        status: "new",
        createdAtIso,
        createdAt: serverTimestamp(),
      };

      if (phone) record.phone = phone.slice(0, 30);
      if (notes) record.notes = notes.slice(0, 2000);
      if (pageUrl) record.pageUrl = pageUrl;

      await setDoc(inquiryRef, record);

      const shortRef = inquiryRef.id.slice(0, 6).toUpperCase();
      // Dispatch instant free email notification without blocking Firestore confirmation.
      void notifyFounderEmail(record, shortRef);

      const baseSuccess = getI18nText(
        "f_success",
        "تم استلام طلبك وحفظه بنجاح! سيتواصل معك فريق مشوار قطر قريباً، ويمكنك أيضاً مراسلتنا مباشرة على ops@mashwar.qa.",
        "Your inquiry has been saved! The MASHWAR Qatar team will follow up shortly, or you can email ops@mashwar.qa directly."
      );

      setStatusState({
        statusEl,
        statusRefEl,
        errorEl,
        type: "success",
        message: baseSuccess,
        refCode: shortRef,
      });
      form.reset();
    } catch (err) {
      console.error("[MASHWAR Firebase Contact]", err);
      setStatusState({
        statusEl,
        statusRefEl,
        errorEl,
        type: "error",
        message: getI18nText(
          "f_err",
          "تعذر حفظ الطلب حالياً. يرجى مراسلتنا مباشرة على ops@mashwar.qa.",
          "Unable to save your inquiry right now. Please contact ops@mashwar.qa directly."
        ),
      });
    } finally {
      isSubmitting = false;
      submitBtn.disabled = false;
      submitBtn.removeAttribute("aria-busy");
      submitBtn.textContent = getI18nText(
        "f_submit",
        "إرسال طلب التواصل",
        "Send Contact Request"
      );
    }
  });
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initInvestorContactForm);
} else {
  initInvestorContactForm();
}
