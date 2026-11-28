/* MASHWAR (مشوار — Qatar) Public-First Interactions, Live Map & Savings Calculator */
(function () {
  const CORRIDORS = {
    doha_alkhor: {
      origin_ar: "الدوحة (مشيرب / الخليج الغربي)",
      origin_en: "Doha (Msheireb / West Bay)",
      dest_ar: "الخور (الكورنيش / رأس لفان)",
      dest_en: "Al Khor (Corniche / Ras Laffan)",
      fromLat: 25.2854,
      fromLng: 51.5310,
      toLat: 25.6804,
      toLng: 51.4969,
      distKm: 52,
      etaMin: 38,
      hwy_ar: "طريق الخور الساحلي",
      hwy_en: "Al Khor Coastal Rd",
      defaultMode: "trip",
      soloQar: 110,
      mashwarQar: 30,
      driverEarnQar: 125,
      co2KgPerTrip: 5.8
    },
    doha_alwakrah: {
      origin_ar: "الدوحة (وسط المدينة / السد)",
      origin_en: "Doha (Central / Al Sadd)",
      dest_ar: "الوكرة ومدينة بروة",
      dest_en: "Al Wakrah & Barwa City",
      fromLat: 25.2854,
      fromLng: 51.5310,
      toLat: 25.1715,
      toLng: 51.6034,
      distKm: 22,
      etaMin: 22,
      hwy_ar: "طريق الوكرة السريع",
      hwy_en: "Al Wakrah Expressway",
      defaultMode: "parcel",
      soloQar: 55,
      mashwarQar: 18,
      driverEarnQar: 78,
      co2KgPerTrip: 2.6
    },
    lusail_industrial: {
      origin_ar: "مارينا لوسيل ومواقع الأبراج",
      origin_en: "Lusail Marina & Project Sites",
      dest_ar: "المنطقة الصناعية (شارع 10)",
      dest_en: "Industrial Area (Street 10)",
      fromLat: 25.4300,
      fromLng: 51.4900,
      toLat: 25.1903,
      toLng: 51.4426,
      distKm: 36,
      etaMin: 29,
      hwy_ar: "طريق الدوحة السريع",
      hwy_en: "Doha Expressway",
      defaultMode: "supply",
      soloQar: 140,
      mashwarQar: 48,
      driverEarnQar: 145,
      co2KgPerTrip: 4.4
    },
    alrayyan_westbay: {
      origin_ar: "الريان (المدينة التعليمية)",
      origin_en: "Al Rayyan (Education City)",
      dest_ar: "الخليج الغربي وأبراج الدوحة",
      dest_en: "West Bay & Doha Towers",
      fromLat: 25.3136,
      fromLng: 51.4342,
      toLat: 25.3260,
      toLng: 51.5310,
      distKm: 19,
      etaMin: 21,
      hwy_ar: "محور الريان – الكورنيش",
      hwy_en: "Al Rayyan – Corniche Axis",
      defaultMode: "trip",
      soloQar: 48,
      mashwarQar: 16,
      driverEarnQar: 72,
      co2KgPerTrip: 2.2
    },
    alkhor_lusail: {
      origin_ar: "الخور (وسط المدينة)",
      origin_en: "Al Khor (Town Center)",
      dest_ar: "لوسيل (المدينة الترفيهية / مارينا)",
      dest_en: "Lusail (Marina / Boulevard)",
      fromLat: 25.6804,
      fromLng: 51.4969,
      toLat: 25.4300,
      toLng: 51.4900,
      distKm: 39,
      etaMin: 28,
      hwy_ar: "طريق الخور الساحلي",
      hwy_en: "Al Khor Coastal Highway",
      defaultMode: "trip",
      soloQar: 85,
      mashwarQar: 24,
      driverEarnQar: 105,
      co2KgPerTrip: 4.6
    }
  };

  /* 5 Consumer App Walkthrough Screens ONLY */
  const SCREENS = [
    "./assets/mobile/app_home_hero.png",
    "./assets/mobile/app_live_map_picker.png",
    "./assets/mobile/app_ride_details.png",
    "./assets/mobile/app_parcel_otp.png",
    "./assets/mobile/app_worksite_supply.png"
  ];

  const state = {
    lang: "ar",
    corridor: "doha_alkhor",
    mapStyle: "standard", // standard | light | satellite | night
    mapMode: "trip",      // trip | parcel | supply
    calcRole: "rider",    // rider | driver
    tripsPerMonth: 16,
    screenIdx: 0
  };

  function fmtQar(val) {
    const rounded = Math.round(val).toLocaleString("en-US");
    return state.lang === "ar" ? `${rounded} ر.ق` : `${rounded} QAR`;
  }

  function buildCorridorMapUrl(c) {
    const lang = state.lang;
    const params = new URLSearchParams({
      fromLat: String(c.fromLat),
      fromLng: String(c.fromLng),
      fromName: c[`origin_${lang}`],
      toLat: String(c.toLat),
      toLng: String(c.toLng),
      toName: c[`dest_${lang}`],
      mode: state.mapMode || c.defaultMode || "trip",
      style: state.mapStyle || "standard",
      traffic: "1",
      lang: lang,
      nearby: "1",
      gps: "0",
      dist: String(c.distKm),
      eta: String(c.etaMin),
      hwy: c[`hwy_${lang}`]
    });
    return `./maps/mashwar_live_map.html?${params.toString()}`;
  }

  function renderCalculator() {
    const c = CORRIDORS[state.corridor];
    if (!c) return;
    const isAr = state.lang === "ar";
    const trips = state.tripsPerMonth;
    const dict = window.MASHWAR_I18N[state.lang] || {};

    const tripsValEl = document.getElementById("calc-trips-val");
    if (tripsValEl) tripsValEl.textContent = String(trips);

    document.querySelectorAll("[data-calc-preset]").forEach((btn) => {
      btn.classList.toggle("is-active", Number(btn.getAttribute("data-calc-preset")) === trips);
    });

    const monthlyLbl = document.getElementById("calc-monthly-lbl");
    const monthlyVal = document.getElementById("calc-monthly-val");
    const monthlySub = document.getElementById("calc-monthly-sub");
    const annualLbl = document.getElementById("calc-annual-lbl");
    const annualVal = document.getElementById("calc-annual-val");
    const co2Val = document.getElementById("calc-co2-val");
    const benchVal = document.getElementById("calc-benchmark-val");
    const benchSub = document.getElementById("calc-benchmark-sub");

    const annualCo2 = Math.round(c.co2KgPerTrip * trips * 12).toLocaleString("en-US");
    if (co2Val) co2Val.textContent = isAr ? `${annualCo2} كجم` : `${annualCo2} kg`;

    if (state.calcRole === "rider") {
      const perTripSave = Math.max(0, c.soloQar - c.mashwarQar);
      const monthlySave = perTripSave * trips;
      const annualSave = monthlySave * 12;

      if (monthlyLbl) monthlyLbl.textContent = dict.calc_kpi_monthly_rider || "";
      if (monthlyVal) monthlyVal.textContent = fmtQar(monthlySave);
      if (monthlySub) {
        monthlySub.textContent = isAr
          ? `${fmtQar(c.mashwarQar)} عبر مشوار بدلاً من ${fmtQar(c.soloQar)} للتنقّل أو التوصيل الفردي`
          : `${fmtQar(c.mashwarQar)} via MASHWAR vs. ${fmtQar(c.soloQar)} solo ride or rush run`;
      }
      if (annualLbl) annualLbl.textContent = dict.calc_kpi_annual_rider || "";
      if (annualVal) annualVal.textContent = fmtQar(annualSave);
      if (benchVal) {
        benchVal.textContent = isAr
          ? `${fmtQar(c.mashwarQar)} / طلب`
          : `${fmtQar(c.mashwarQar)} / trip`;
      }
      if (benchSub) {
        benchSub.textContent = isAr
          ? `توفير ${fmtQar(perTripSave)} في كل رحلة`
          : `Saves ${fmtQar(perTripSave)} per trip`;
      }
    } else {
      const monthlyEarn = c.driverEarnQar * trips;
      const annualEarn = monthlyEarn * 12;

      if (monthlyLbl) monthlyLbl.textContent = dict.calc_kpi_monthly_driver || "";
      if (monthlyVal) monthlyVal.textContent = fmtQar(monthlyEarn);
      if (monthlySub) {
        monthlySub.textContent = isAr
          ? `متوسط ${fmtQar(c.driverEarnQar)} لكل مسار (مقاعد شاغرة + طرد أو توريد على الطريق)`
          : `Avg. ${fmtQar(c.driverEarnQar)} per corridor run (spare seats + route parcel or supply)`;
      }
      if (annualLbl) annualLbl.textContent = dict.calc_kpi_annual_driver || "";
      if (annualVal) annualVal.textContent = fmtQar(annualEarn);
      if (benchVal) {
        benchVal.textContent = isAr
          ? `${fmtQar(c.driverEarnQar)} / مسار`
          : `${fmtQar(c.driverEarnQar)} / run`;
      }
      if (benchSub) {
        benchSub.textContent = isAr
          ? `تسوية مباشرة على طريق ${c.hwy_ar}`
          : `Direct settlement along ${c.hwy_en}`;
      }
    }
  }

  function renderCorridor(updateIframe) {
    const c = CORRIDORS[state.corridor];
    if (!c) return;
    const isAr = state.lang === "ar";

    const originEl = document.getElementById("cor-origin-name");
    const destEl = document.getElementById("cor-dest-name");
    const distEl = document.getElementById("cor-dist-badge");

    if (originEl) originEl.textContent = c[`origin_${state.lang}`];
    if (destEl) destEl.textContent = c[`dest_${state.lang}`];
    if (distEl) {
      distEl.textContent = isAr
        ? `${c.distKm} كم · ~${c.etaMin} دقيقة`
        : `${c.distKm} km · ~${c.etaMin} mins`;
    }

    document.querySelectorAll("[data-corridor]").forEach((btn) => {
      btn.classList.toggle("is-active", btn.getAttribute("data-corridor") === state.corridor);
    });
    document.querySelectorAll("[data-map-style]").forEach((btn) => {
      btn.classList.toggle("is-active", btn.getAttribute("data-map-style") === state.mapStyle);
    });
    document.querySelectorAll("[data-cor-mode]").forEach((btn) => {
      btn.classList.toggle("is-active", btn.getAttribute("data-cor-mode") === state.mapMode);
    });

    if (updateIframe !== false) {
      const iframe = document.getElementById("corridor-live-map");
      if (iframe) {
        iframe.src = buildCorridorMapUrl(c);
      }
    }

    renderCalculator();
  }

  function applyLanguage(lang) {
    state.lang = lang;
    const dict = window.MASHWAR_I18N && window.MASHWAR_I18N[lang];
    if (!dict) return;

    document.documentElement.lang = lang;
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
    document.title = dict.page_title;

    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (dict[key] !== undefined) el.textContent = dict[key];
    });

    document.querySelectorAll("[data-i18n-placeholder]").forEach((el) => {
      const key = el.getAttribute("data-i18n-placeholder");
      if (dict[key] !== undefined) el.setAttribute("placeholder", dict[key]);
    });

    document.querySelectorAll("[data-cor-ar]").forEach((btn) => {
      btn.textContent = btn.getAttribute(lang === "ar" ? "data-cor-ar" : "data-cor-en");
    });

    renderCorridor(true);
    if (window.MASHWAR_CHARTS) window.MASHWAR_CHARTS.setLang(lang);
  }

  function initHeaderScroll() {
    const header = document.getElementById("site-header");
    const progressBar = document.getElementById("scroll-progress-bar");
    const onScroll = () => {
      const y = window.scrollY || document.documentElement.scrollTop;
      if (header) header.classList.toggle("is-scrolled", y > 24);
      if (progressBar) {
        const docH = document.documentElement.scrollHeight - window.innerHeight;
        progressBar.style.width = `${docH > 0 ? Math.min(100, (y / docH) * 100) : 0}%`;
      }
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }

  function initMobileDrawer() {
    const drawer = document.getElementById("mobile-drawer");
    const openBtn = document.getElementById("mobile-menu-open");
    const closeBtn = document.getElementById("mobile-menu-close");
    if (!drawer || !openBtn || !closeBtn) return;

    const toggle = (open) => {
      drawer.classList.toggle("is-open", open);
      drawer.setAttribute("aria-hidden", String(!open));
    };

    openBtn.addEventListener("click", () => toggle(true));
    closeBtn.addEventListener("click", () => toggle(false));
    drawer.querySelectorAll("a").forEach((a) => a.addEventListener("click", () => toggle(false)));
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") toggle(false);
    });
  }

  function initRevealObserver() {
    const els = Array.from(document.querySelectorAll(".reveal"));
    if (!("IntersectionObserver" in window)) {
      els.forEach((e) => e.classList.add("is-visible"));
      return;
    }
    const revealPassed = () => {
      const vh = window.innerHeight || document.documentElement.clientHeight;
      els.forEach((el) => {
        if (el.classList.contains("is-visible")) return;
        if (el.getBoundingClientRect().top <= vh * 0.96) el.classList.add("is-visible");
      });
    };
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.02 }
    );
    els.forEach((el) => io.observe(el));
    window.addEventListener("scroll", revealPassed, { passive: true });
    revealPassed();
  }

  function initCorridorAndCalculator() {
    document.querySelectorAll("[data-corridor]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const key = btn.getAttribute("data-corridor");
        if (!CORRIDORS[key]) return;
        state.corridor = key;
        state.mapMode = CORRIDORS[key].defaultMode || "trip";
        renderCorridor(true);
      });
    });

    document.querySelectorAll("[data-map-style]").forEach((btn) => {
      btn.addEventListener("click", () => {
        state.mapStyle = btn.getAttribute("data-map-style") || "standard";
        renderCorridor(true);
      });
    });

    document.querySelectorAll("[data-cor-mode]").forEach((btn) => {
      btn.addEventListener("click", () => {
        state.mapMode = btn.getAttribute("data-cor-mode") || "trip";
        renderCorridor(true);
      });
    });

    document.querySelectorAll("[data-calc-role]").forEach((btn) => {
      btn.addEventListener("click", () => {
        state.calcRole = btn.getAttribute("data-calc-role") || "rider";
        document.querySelectorAll("[data-calc-role]").forEach((b) =>
          b.classList.toggle("is-active", b === btn)
        );
        renderCalculator();
      });
    });

    const slider = document.getElementById("calc-trips-slider");
    if (slider) {
      slider.addEventListener("input", () => {
        state.tripsPerMonth = Math.max(1, Math.min(22, Number(slider.value) || 1));
        renderCalculator();
      });
    }

    document.querySelectorAll("[data-calc-preset]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const val = Number(btn.getAttribute("data-calc-preset")) || 12;
        state.tripsPerMonth = val;
        if (slider) slider.value = String(val);
        renderCalculator();
      });
    });
  }

  function initConsumerShowcase() {
    const stageImg = document.getElementById("mobile-screen-img");
    const prevBtn = document.getElementById("showcase-prev");
    const nextBtn = document.getElementById("showcase-next");

    const setScreen = (idx) => {
      const normalized = ((idx % SCREENS.length) + SCREENS.length) % SCREENS.length;
      state.screenIdx = normalized;

      document.querySelectorAll("[data-screen-idx]").forEach((b) =>
        b.classList.toggle("is-active", Number(b.getAttribute("data-screen-idx")) === normalized)
      );
      document.querySelectorAll("[data-screen-dot]").forEach((d) =>
        d.classList.toggle("is-active", Number(d.getAttribute("data-screen-dot")) === normalized)
      );

      if (stageImg && SCREENS[normalized]) {
        stageImg.style.opacity = "0.25";
        setTimeout(() => {
          stageImg.src = SCREENS[normalized];
          stageImg.style.opacity = "1";
        }, 110);
      }
    };

    document.querySelectorAll("[data-screen-idx]").forEach((btn) => {
      btn.addEventListener("click", () => setScreen(Number(btn.getAttribute("data-screen-idx"))));
    });
    document.querySelectorAll("[data-screen-dot]").forEach((dot) => {
      dot.addEventListener("click", () => setScreen(Number(dot.getAttribute("data-screen-dot"))));
    });
    if (prevBtn) prevBtn.addEventListener("click", () => setScreen(state.screenIdx - 1));
    if (nextBtn) nextBtn.addEventListener("click", () => setScreen(state.screenIdx + 1));
  }

  function initExecutiveTabs() {
    const tabBtns = document.querySelectorAll("[data-exec-tab]");
    tabBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        const target = btn.getAttribute("data-exec-tab");
        tabBtns.forEach((b) => b.classList.toggle("is-active", b === btn));
        document.querySelectorAll(".exec-panel").forEach((panel) => {
          panel.classList.toggle("is-active", panel.id === `exec-panel-${target}`);
        });
        if (target === "financials" && window.MASHWAR_CHARTS) {
          window.MASHWAR_CHARTS.renderAll();
        }
      });
    });
  }

  function initPortalLinksAndTracks() {
    const isLocalLanding =
      (window.location.hostname === "127.0.0.1" || window.location.hostname === "localhost") &&
      window.location.port === "8088";
    const consumerUrl = isLocalLanding ? "http://127.0.0.1:8080/" : "/";
    const adminUrl = isLocalLanding ? "http://127.0.0.1:8080/admin/" : "/admin/";

    document.querySelectorAll("[data-live-web-btn]").forEach((link) => {
      link.setAttribute("href", consumerUrl);
    });
    document.querySelectorAll("[data-live-admin-btn]").forEach((link) => {
      link.setAttribute("href", adminUrl);
    });

    document.querySelectorAll("[data-contact-track]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const trackIdx = Number(btn.getAttribute("data-contact-track")) || 0;
        const contactSection = document.getElementById("contact");
        if (contactSection) contactSection.scrollIntoView({ behavior: "smooth" });
        const sel = document.getElementById("inv-interest");
        if (sel && sel.options[trackIdx]) {
          sel.selectedIndex = trackIdx;
        }
        const nameInput = document.getElementById("inv-name");
        if (nameInput) setTimeout(() => nameInput.focus(), 380);
      });
    });
  }

  function init() {
    const langBtn = document.getElementById("lang-toggle-btn");
    if (langBtn) {
      langBtn.addEventListener("click", () => applyLanguage(state.lang === "ar" ? "en" : "ar"));
    }

    initHeaderScroll();
    initMobileDrawer();
    initRevealObserver();
    initCorridorAndCalculator();
    initConsumerShowcase();
    initExecutiveTabs();
    initPortalLinksAndTracks();
    applyLanguage("ar");
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
