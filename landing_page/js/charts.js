/* Interactive Executive SVG Financial Charts, Dynamic KPI/Tranche Cards & Simulator */
(function () {
  const DATA = window.MASHWAR_FINANCIALS;
  if (!DATA) return;

  const state = {
    scenario: "base", // "base" | "stress"
    currency: "USD",  // "USD" | "QAR"
    lang: "ar"
  };

  const tooltipEl = () => document.getElementById("chart-tooltip");

  function mult() {
    return state.currency === "QAR" ? DATA.usdToQar : 1;
  }

  function sym() {
    return state.currency === "QAR" ? (state.lang === "ar" ? "ر.ق " : "QAR ") : "$";
  }

  function fmtMoney(usdVal, compact) {
    const v = usdVal * mult();
    const sign = v < 0 ? "-" : "";
    const abs = Math.abs(v);
    if (compact) {
      if (abs >= 1e6) return `${sign}${sym()}${(abs / 1e6).toFixed(2)}M`;
      if (abs >= 1e3) return `${sign}${sym()}${(abs / 1e3).toFixed(1)}K`;
    }
    return `${sign}${sym()}${Math.round(abs).toLocaleString("en-US")}`;
  }

  function fmtAxisK(valInK) {
    const sign = valInK < 0 ? "-" : "";
    const abs = Math.abs(valInK);
    const s = state.currency === "QAR" ? "QAR " : "$";
    if (abs >= 1000) return `${sign}${s}${(abs / 1000).toFixed(1)}M`;
    return `${sign}${s}${Math.round(abs)}K`;
  }

  function showTip(evt, html) {
    const tip = tooltipEl();
    if (!tip) return;
    tip.innerHTML = html;
    tip.classList.add("is-visible");
    const pad = 14;
    let left = evt.clientX + pad;
    let top = evt.clientY - 12;
    const rect = tip.getBoundingClientRect();
    if (left + rect.width > window.innerWidth - 10) left = evt.clientX - rect.width - pad;
    if (top + rect.height > window.innerHeight - 10) top = window.innerHeight - rect.height - 10;
    if (top < 10) top = 10;
    tip.style.left = `${left}px`;
    tip.style.top = `${top}px`;
  }

  function hideTip() {
    const tip = tooltipEl();
    if (tip) tip.classList.remove("is-visible");
  }

  function renderMacroAndTrancheCards() {
    const model = DATA[state.scenario];
    const y3 = model.years[2];
    const isAr = state.lang === "ar";

    const tamEl = document.getElementById("kpi-tam-val");
    const samEl = document.getElementById("kpi-sam-val");
    const somEl = document.getElementById("kpi-som-val");
    const somSubEl = document.getElementById("kpi-som-sub");

    if (tamEl) tamEl.textContent = fmtMoney(model.tam_usd, true);
    if (samEl) samEl.textContent = fmtMoney(model.sam_usd, true);
    if (somEl) somEl.textContent = `${fmtMoney(y3.gmv, true)} GMV`;
    if (somSubEl) {
      somSubEl.textContent = isAr
        ? `${y3.end_corridors} محوراً تنفّذ ${y3.tx.toLocaleString("en-US")} معاملة سنوياً + ${y3.end_b2b} حساب شركات (صافي إيراد ${fmtMoney(y3.net_rev, true)}).`
        : `${y3.end_corridors} corridors executing ${y3.tx.toLocaleString("en-US")} annual transactions + ${y3.end_b2b} B2B accounts (${fmtMoney(y3.net_rev, true)} Net Revenue).`;
    }

    DATA.tranches.forEach((tr, idx) => {
      const el = document.getElementById(`tranche-amt-${idx + 1}`);
      if (el) el.textContent = `${fmtMoney(tr.amount, state.currency === "QAR")} (${tr.pct}%)`;
    });
  }

  function renderChart1() {
    const host = document.getElementById("chart-gmv-revenue");
    if (!host) return;
    const model = DATA[state.scenario];
    const quarters = model.quarters;
    const factor = mult() / 1000.0;

    const W = 740, H = 315;
    const m = { top: 32, right: 62, bottom: 38, left: 62 };
    const pw = W - m.left - m.right;
    const ph = H - m.top - m.bottom;

    const maxGmv = Math.max(...quarters.map((q) => q.gmv * factor), 10) * 1.20;
    const maxRev = Math.max(...quarters.map((q) => q.net_rev * factor), 10) * 1.32;

    const step = pw / quarters.length;
    const barW = step * 0.54;

    let svg = `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Quarterly GMV and Net Revenue Chart">`;
    svg += `<defs>
      <linearGradient id="gmvBarGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="#14B8A6"/>
        <stop offset="100%" stop-color="#0B1F33"/>
      </linearGradient>
      <linearGradient id="revAreaGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="#F59E0B" stop-opacity="0.28"/>
        <stop offset="100%" stop-color="#F59E0B" stop-opacity="0.0"/>
      </linearGradient>
    </defs>`;

    for (let i = 0; i <= 4; i++) {
      const y = m.top + ph - (ph * i) / 4;
      const gmvTick = (maxGmv * i) / 4;
      const revTick = (maxRev * i) / 4;
      svg += `<line x1="${m.left}" y1="${y}" x2="${W - m.right}" y2="${y}" stroke="#E2E8F0" stroke-dasharray="${i === 0 ? "" : "4 4"}"/>`;
      svg += `<text x="${m.left - 8}" y="${y + 4}" text-anchor="end" font-size="10.5" fill="#475569" font-weight="700">${fmtAxisK(gmvTick)}</text>`;
      svg += `<text x="${W - m.right + 8}" y="${y + 4}" text-anchor="start" font-size="10.5" fill="#B45309" font-weight="700">${fmtAxisK(revTick)}</text>`;
    }

    const linePts = [];
    quarters.forEach((q, idx) => {
      const cx = m.left + step * idx + step / 2;
      const bh = ((q.gmv * factor) / maxGmv) * ph;
      const by = m.top + ph - bh;
      const ry = m.top + ph - ((q.net_rev * factor) / maxRev) * ph;
      linePts.push({ x: cx, y: ry, q, idx });

      svg += `<rect x="${cx - barW / 2}" y="${by}" width="${barW}" height="${Math.max(bh, 2)}" rx="6" fill="url(#gmvBarGrad)" opacity="0.92"/>`;
      svg += `<text x="${cx}" y="${H - 12}" text-anchor="middle" font-size="11" fill="#0B1F33" font-weight="700">${q.label}</text>`;
    });

    const pathD = linePts.map((p, i) => `${i === 0 ? "M" : "L"}${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(" ");
    const areaD = `${pathD} L${linePts[linePts.length - 1].x.toFixed(1)},${m.top + ph} L${linePts[0].x.toFixed(1)},${m.top + ph} Z`;
    svg += `<path d="${areaD}" fill="url(#revAreaGrad)"/>`;
    svg += `<path d="${pathD}" fill="none" stroke="#F59E0B" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>`;

    linePts.forEach((p, idx) => {
      svg += `<circle cx="${p.x}" cy="${p.y}" r="4.5" fill="#F59E0B" stroke="#0B1F33" stroke-width="1.8"/>`;
      if (idx === 3 || idx === 7 || idx === 11) {
        const lbl = fmtMoney(p.q.net_rev, true);
        const pwBox = Math.max(48, lbl.length * 6.8);
        svg += `<rect x="${p.x - pwBox / 2}" y="${p.y - 25}" width="${pwBox}" height="17" rx="5" fill="#FEF3C7" stroke="#F59E0B" stroke-width="0.9"/>`;
        svg += `<text x="${p.x}" y="${p.y - 13}" text-anchor="middle" font-size="10" fill="#78350F" font-weight="800">${lbl}</text>`;
      }
      const colX = m.left + step * idx;
      svg += `<rect x="${colX}" y="${m.top}" width="${step}" height="${ph}" fill="transparent" class="c1-col" data-idx="${idx}" style="cursor:pointer"/>`;
    });

    svg += `</svg>`;
    host.innerHTML = svg;

    host.querySelectorAll(".c1-col").forEach((el) => {
      const idx = Number(el.getAttribute("data-idx"));
      const q = quarters[idx];
      el.addEventListener("mousemove", (evt) => {
        const isAr = state.lang === "ar";
        showTip(
          evt,
          `<div style="font-weight:800;color:#FBBF24;margin-bottom:4px">${q.label} · ${q.corridors} ${isAr ? "محاور" : "Corridors"}</div>` +
            `<div>GMV: <strong>${fmtMoney(q.gmv)}</strong></div>` +
            `<div>${isAr ? "صافي الإيراد:" : "Net Revenue:"} <strong>${fmtMoney(q.net_rev)}</strong></div>` +
            `<div>${isAr ? "المعاملات:" : "Transactions:"} <strong>${q.tx.toLocaleString("en-US")}</strong></div>`
        );
      });
      el.addEventListener("mouseleave", hideTip);
    });
  }

  function renderChart2() {
    const svgHost = document.getElementById("chart-rev-donut");
    const barsHost = document.getElementById("chart-rev-bars");
    if (!svgHost || !barsHost) return;

    const y3 = DATA[state.scenario].years[2];
    const isAr = state.lang === "ar";
    const items = [
      {
        key: "b2b",
        label: isAr ? "باقات الشركات والمقاولين (B2B)" : "Contractor & Business Plans (B2B)",
        val: y3.rev_b2b,
        color: "#0F766E"
      },
      {
        key: "parcels",
        label: isAr ? "طرود المسار (كود تسليم ثنائي)" : "Route Parcels (Dual-OTP)",
        val: y3.rev_parcels,
        color: "#F59E0B"
      },
      {
        key: "seats",
        label: isAr ? "الرحلات التشاركية بين المدن" : "Intercity Shared Rides",
        val: y3.rev_seats,
        color: "#0B1F33"
      },
      {
        key: "board",
        label: isAr ? "توريد المواقع والمشتريات الموثّقة" : "Worksite Supply & Receipt Runs",
        val: y3.rev_board,
        color: "#0284C7"
      }
    ];
    const total = items.reduce((s, x) => s + x.val, 0) || 1;

    const R = 74, C = 2 * Math.PI * R;
    let offset = 0;
    let svg = `<svg viewBox="0 0 210 210" style="max-width:205px" role="img" aria-label="Year 3 Revenue Mix Donut">`;
    svg += `<circle cx="105" cy="105" r="${R}" fill="none" stroke="#E2E8F0" stroke-width="26"/>`;

    items.forEach((item) => {
      const pct = item.val / total;
      const dash = pct * C;
      svg += `<circle class="donut-seg" cx="105" cy="105" r="${R}" fill="none" stroke="${item.color}" stroke-width="26" stroke-dasharray="${dash.toFixed(2)} ${(C - dash).toFixed(2)}" stroke-dashoffset="${(-offset).toFixed(2)}" transform="rotate(-90 105 105)" data-key="${item.key}" style="cursor:pointer;transition:stroke-width 180ms ease"/>`;
      offset += dash;
    });

    svg += `<text id="donut-center-val" x="105" y="102" text-anchor="middle" font-size="18" font-weight="900" fill="#0B1F33">${fmtMoney(y3.gross_rev, true)}</text>`;
    svg += `<text id="donut-center-lbl" x="105" y="121" text-anchor="middle" font-size="10.5" font-weight="700" fill="#475569">${isAr ? "إجمالي إيراد السنة 3" : "Y3 Gross Revenue"}</text>`;
    svg += `</svg>`;
    svgHost.innerHTML = svg;

    barsHost.innerHTML = items
      .map((item) => {
        const pctStr = `${((item.val / total) * 100).toFixed(1)}%`;
        return `<div class="donut-bar-row" data-key="${item.key}">
          <div class="donut-bar-row__top">
            <span>${item.label}</span>
            <span class="num">${pctStr} · ${fmtMoney(item.val, true)}</span>
          </div>
          <div class="donut-bar-track">
            <div class="donut-bar-fill" style="width:${pctStr};background:${item.color}"></div>
          </div>
        </div>`;
      })
      .join("");

    const centerVal = document.getElementById("donut-center-val");
    const centerLbl = document.getElementById("donut-center-lbl");
    const bindHover = (key) => {
      const it = items.find((x) => x.key === key);
      if (!it || !centerVal || !centerLbl) return;
      centerVal.textContent = `${((it.val / total) * 100).toFixed(1)}%`;
      centerLbl.textContent = fmtMoney(it.val, true);
    };
    const resetHover = () => {
      if (!centerVal || !centerLbl) return;
      centerVal.textContent = fmtMoney(y3.gross_rev, true);
      centerLbl.textContent = isAr ? "إجمالي إيراد السنة 3" : "Y3 Gross Revenue";
    };

    svgHost.querySelectorAll(".donut-seg").forEach((seg) => {
      const k = seg.getAttribute("data-key");
      seg.addEventListener("mouseenter", () => { seg.setAttribute("stroke-width", "31"); bindHover(k); });
      seg.addEventListener("mouseleave", () => { seg.setAttribute("stroke-width", "26"); resetHover(); });
    });
    barsHost.querySelectorAll(".donut-bar-row").forEach((row) => {
      const k = row.getAttribute("data-key");
      row.addEventListener("mouseenter", () => bindHover(k));
      row.addEventListener("mouseleave", resetHover);
    });
  }

  function renderChart3() {
    const host = document.getElementById("chart-cash-runway");
    if (!host) return;
    const model = DATA[state.scenario];
    const months = model.months;
    const factor = mult() / 1000.0;
    const isAr = state.lang === "ar";

    const W = 980, H = 295;
    const m = { top: 30, right: 24, bottom: 38, left: 68 };
    const pw = W - m.left - m.right;
    const ph = H - m.top - m.bottom;

    const vals = months.flatMap((x) => [x.ending_cash * factor, x.ebitda * factor]);
    const minVal = Math.min(...vals, -25 * factor) * 1.15;
    const maxVal = Math.max(...vals, 100 * factor) * 1.20;
    const range = maxVal - minVal || 1;

    const toX = (month) => m.left + ((month - 1) / (months.length - 1)) * pw;
    const toY = (valK) => m.top + ((maxVal - valK) / range) * ph;

    let svg = `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="36-Month Cash Runway and Breakeven Chart">`;
    svg += `<defs>
      <linearGradient id="cashAreaGrad" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="#0F766E" stop-opacity="0.28"/>
        <stop offset="100%" stop-color="#0F766E" stop-opacity="0.02"/>
      </linearGradient>
    </defs>`;

    for (let i = 0; i <= 4; i++) {
      const val = minVal + (range * i) / 4;
      const y = toY(val);
      svg += `<line x1="${m.left}" y1="${y}" x2="${W - m.right}" y2="${y}" stroke="#E2E8F0" stroke-dasharray="4 4"/>`;
      svg += `<text x="${m.left - 8}" y="${y + 4}" text-anchor="end" font-size="10.5" fill="#475569" font-weight="700">${fmtAxisK(val)}</text>`;
    }

    const y0 = toY(0);
    svg += `<line x1="${m.left}" y1="${y0}" x2="${W - m.right}" y2="${y0}" stroke="#94A3B8" stroke-width="1.3"/>`;

    const cashPts = months.map((x) => ({ x: toX(x.month), y: toY(x.ending_cash * factor), m: x }));
    const ebitPts = months.map((x) => ({ x: toX(x.month), y: toY(x.ebitda * factor) }));

    const cashD = cashPts.map((p, i) => `${i === 0 ? "M" : "L"}${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(" ");
    const cashAreaD = `${cashD} L${cashPts[cashPts.length - 1].x.toFixed(1)},${y0.toFixed(1)} L${cashPts[0].x.toFixed(1)},${y0.toFixed(1)} Z`;
    const ebitD = ebitPts.map((p, i) => `${i === 0 ? "M" : "L"}${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(" ");

    svg += `<path d="${cashAreaD}" fill="url(#cashAreaGrad)"/>`;
    svg += `<path d="${cashD}" fill="none" stroke="#0F766E" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>`;
    svg += `<path d="${ebitD}" fill="none" stroke="#0B1F33" stroke-width="2" stroke-dasharray="6 4"/>`;

    const be = model.breakeven_month;
    if (be) {
      const beX = toX(be);
      svg += `<line x1="${beX}" y1="${m.top}" x2="${beX}" y2="${m.top + ph}" stroke="#D97706" stroke-width="1.8" stroke-dasharray="4 4"/>`;
      svg += `<text x="${beX + 7}" y="${m.top + 14}" font-size="11" font-weight="800" fill="#B45309">${isAr ? "التعادل التشغيلي" : "EBITDA Breakeven"}: M${be}</text>`;
    }

    DATA.tranches.forEach((t) => {
      const pt = cashPts[t.month - 1];
      svg += `<circle cx="${pt.x}" cy="${pt.y}" r="6" fill="#F59E0B" stroke="#0B1F33" stroke-width="2"/>`;
      svg += `<text x="${pt.x + 8}" y="${pt.y - 10}" font-size="10.5" font-weight="800" fill="#0B1F33">${t.label} (+${fmtMoney(t.amount, true)})</text>`;
    });

    [1, 6, 12, 18, 24, 30, 36].forEach((mn) => {
      svg += `<text x="${toX(mn)}" y="${H - 12}" text-anchor="middle" font-size="11" fill="#475569" font-weight="700">M${mn}</text>`;
    });

    const cw = pw / months.length;
    months.forEach((x, i) => {
      svg += `<rect x="${toX(x.month) - cw / 2}" y="${m.top}" width="${cw}" height="${ph}" fill="transparent" class="c3-col" data-idx="${i}" style="cursor:pointer"/>`;
    });

    svg += `</svg>`;
    host.innerHTML = svg;

    host.querySelectorAll(".c3-col").forEach((el) => {
      const idx = Number(el.getAttribute("data-idx"));
      const mo = months[idx];
      el.addEventListener("mousemove", (evt) => {
        showTip(
          evt,
          `<div style="font-weight:800;color:#2DD4BF;margin-bottom:4px">${isAr ? `الشهر ${mo.month}` : `Month ${mo.month}`} · ${mo.corridors} ${isAr ? "محاور" : "Corridors"}</div>` +
            `<div>${isAr ? "الرصيد النقدي:" : "Ending Cash:"} <strong>${fmtMoney(mo.ending_cash)}</strong></div>` +
            `<div>EBITDA: <strong>${fmtMoney(mo.ebitda)}</strong></div>` +
            `<div>${isAr ? "الإيراد الشهري:" : "Monthly Rev:"} <strong>${fmtMoney(mo.net_rev)}</strong></div>`
        );
      });
      el.addEventListener("mouseleave", hideTip);
    });
  }

  function renderPnlTable() {
    const tbody = document.getElementById("fin-table-body");
    if (!tbody) return;
    const ys = DATA[state.scenario].years;
    const isAr = state.lang === "ar";
    const rows = [
      { label: isAr ? "المحاور النشطة بنهاية العام" : "Active Corridors (Year End)", vals: [ys[0].end_corridors, ys[1].end_corridors, ys[2].end_corridors], cum: "14" },
      { label: isAr ? "إجمالي المعاملات السنوية" : "Completed Transactions", vals: ys.map((y) => y.tx.toLocaleString("en-US")), cum: (ys[0].tx + ys[1].tx + ys[2].tx).toLocaleString("en-US") },
      { label: isAr ? "إجمالي قيمة التعاملات (GMV)" : "Gross Merchandise Value (GMV)", vals: ys.map((y) => fmtMoney(y.gmv)), cum: fmtMoney(ys[0].gmv + ys[1].gmv + ys[2].gmv) },
      { label: isAr ? "صافي إيرادات المنصة" : "Net Platform Revenue", vals: ys.map((y) => fmtMoney(y.net_rev)), cum: fmtMoney(ys[0].net_rev + ys[1].net_rev + ys[2].net_rev), hi: true },
      { label: isAr ? "هامش الربح الإجمالي" : "Gross Profit (Margin %)", vals: ys.map((y) => `${fmtMoney(y.gross_profit)} (${((y.gross_profit / y.net_rev) * 100).toFixed(0)}%)`), cum: fmtMoney(ys[0].gross_profit + ys[1].gross_profit + ys[2].gross_profit) },
      { label: isAr ? "الربح التشغيلي (EBITDA)" : "Operating EBITDA", vals: ys.map((y) => fmtMoney(y.ebitda)), cum: fmtMoney(ys[0].ebitda + ys[1].ebitda + ys[2].ebitda) },
      { label: isAr ? "الرصيد النقدي بنهاية العام" : "Ending Cash Balance", vals: ys.map((y) => fmtMoney(y.ending_cash)), cum: fmtMoney(ys[2].ending_cash), hi: true }
    ];

    const thead = document.getElementById("fin-table-head");
    if (thead) {
      thead.innerHTML = isAr
        ? `<tr><th>البند المالي (${state.currency})</th><th>السنة 1 (M1–12)</th><th>السنة 2 (M13–24)</th><th>السنة 3 (M25–36)</th><th>الإجمالي / النهاية</th></tr>`
        : `<tr><th>Line Item (${state.currency})</th><th>Year 1 (M1–12)</th><th>Year 2 (M13–24)</th><th>Year 3 (M25–36)</th><th>3Y Cumulative / End</th></tr>`;
    }

    tbody.innerHTML = rows
      .map((r) => `<tr class="${r.hi ? "is-highlight" : ""}"><td>${r.label}</td><td>${r.vals[0]}</td><td>${r.vals[1]}</td><td>${r.vals[2]}</td><td>${r.cum}</td></tr>`)
      .join("");
  }

  function updateSimulator() {
    const sCor = document.getElementById("sim-corridors");
    const sOrd = document.getElementById("sim-orders");
    const sB2b = document.getElementById("sim-b2b");
    if (!sCor || !sOrd || !sB2b) return;

    const cor = Number(sCor.value);
    const ord = Number(sOrd.value);
    const b2b = Number(sB2b.value);

    const corVal = document.getElementById("sim-corridors-val");
    const ordVal = document.getElementById("sim-orders-val");
    const b2bVal = document.getElementById("sim-b2b-val");
    if (corVal) corVal.textContent = cor;
    if (ordVal) ordVal.textContent = ord;
    if (b2bVal) b2bVal.textContent = b2b;

    const blendedTicket = 0.54 * 7.5 + 0.30 * 9.5 + 0.16 * 14.0;
    const blendedTake = 0.54 * 0.11 + 0.46 * 0.18;
    const annualTxGmv = cor * ord * 365 * blendedTicket;
    const annualCommRev = annualTxGmv * blendedTake;
    const annualB2bRev = b2b * 79 * 12;
    const totalRev = annualCommRev + annualB2bRev;
    const driverPayout = annualTxGmv - annualCommRev;
    const b2bShare = totalRev > 0 ? (annualB2bRev / totalRev) * 100 : 0;

    const gmvOut = document.getElementById("sim-gmv-out");
    const revOut = document.getElementById("sim-rev-out");
    const drvOut = document.getElementById("sim-driver-out");
    const b2bOut = document.getElementById("sim-b2b-pct-out");
    if (gmvOut) gmvOut.textContent = fmtMoney(annualTxGmv, true);
    if (revOut) revOut.textContent = fmtMoney(totalRev, true);
    if (drvOut) drvOut.textContent = fmtMoney(driverPayout, true);
    if (b2bOut) b2bOut.textContent = `${b2bShare.toFixed(1)}%`;
  }

  function renderAllCharts() {
    renderMacroAndTrancheCards();
    renderChart1();
    renderChart2();
    renderChart3();
    renderPnlTable();
    updateSimulator();
  }

  function init() {
    document.querySelectorAll("[data-scenario]").forEach((btn) => {
      btn.addEventListener("click", () => {
        state.scenario = btn.getAttribute("data-scenario");
        document.querySelectorAll("[data-scenario]").forEach((b) => b.classList.toggle("is-active", b === btn));
        renderAllCharts();
      });
    });

    document.querySelectorAll("[data-currency]").forEach((btn) => {
      btn.addEventListener("click", () => {
        state.currency = btn.getAttribute("data-currency");
        document.querySelectorAll("[data-currency]").forEach((b) => b.classList.toggle("is-active", b === btn));
        renderAllCharts();
      });
    });

    ["sim-corridors", "sim-orders", "sim-b2b"].forEach((id) => {
      const el = document.getElementById(id);
      if (el) el.addEventListener("input", updateSimulator);
    });

    renderAllCharts();
  }

  window.MASHWAR_CHARTS = {
    setLang(lang) {
      state.lang = lang;
      renderAllCharts();
    },
    renderAll: renderAllCharts
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
