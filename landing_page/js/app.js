/* MASHWAR (مشوار — Qatar) Lean Investor Landing Page Interactions */
(function () {
  const CORRIDORS = {
    al_khor: {
      origin_ar: "الدوحة (الخليج الغربي / لوسيل)",
      origin_en: "Doha (West Bay / Lusail)",
      dest_ar: "الخور (وسط المدينة / رأس لفان)",
      dest_en: "Al Khor / Ras Laffan",
      dist_ar: "56 كم · ~45 دقيقة",
      dist_en: "56 km · ~45 mins",
      seat_ar: "25 ر.ق / مقعد",
      seat_en: "25 QAR / seat",
      seat_vs_ar: "توفير 75% مقابل 105 ر.ق تاكسي خاص",
      seat_vs_en: "Save 75% vs 105 QAR private charter",
      parcel_ar: "35 ر.ق · خلال ساعتين",
      parcel_en: "35 QAR · 2h Transit",
      parcel_vs_ar: "مقابل 24–48 ساعة شحن مستودعات",
      parcel_vs_en: "vs 24–48h traditional courier",
      driver_ar: "110 – 160 ر.ق / رحلة ذهاب",
      driver_en: "110 – 160 QAR / trip",
      driver_vs_ar: "3 مقاعد + طردان على نفس الطريق",
      driver_vs_en: "3 seats + 2 urgent parcels en route"
    },
    mesaieed: {
      origin_ar: "الدوحة / الوكرة",
      origin_en: "Doha / Al Wakrah",
      dest_ar: "المنطقة الصناعية مسيعيد",
      dest_en: "Mesaieed Industrial City",
      dist_ar: "48 كم · ~38 دقيقة",
      dist_en: "48 km · ~38 mins",
      seat_ar: "22 ر.ق / مقعد",
      seat_en: "22 QAR / seat",
      seat_vs_ar: "توفير 76% مقابل 92 ر.ق تاكسي خاص",
      seat_vs_en: "Save 76% vs 92 QAR private charter",
      parcel_ar: "30 ر.ق · خلال ساعتين",
      parcel_en: "30 QAR · 2h Transit",
      parcel_vs_ar: "توصيل فوري للمصانع والعقود",
      parcel_vs_en: "Direct industrial plant & contract handoff",
      driver_ar: "96 – 140 ر.ق / رحلة",
      driver_en: "96 – 140 QAR / trip",
      driver_vs_ar: "مربوطة بتنقلات المهندسين والموظفين",
      driver_vs_en: "Anchored by daily staff commuters"
    },
    industrial: {
      origin_ar: "المنطقة الصناعية الدوحة",
      origin_en: "Doha Industrial Area",
      dest_ar: "الوكرة ومدينة بروة",
      dest_en: "Al Wakrah & Barwa City",
      dist_ar: "28 كم · ~25 دقيقة",
      dist_en: "28 km · ~25 mins",
      seat_ar: "15 ر.ق / مقعد",
      seat_en: "15 QAR / seat",
      seat_vs_ar: "توفير 70% مقابل 52 ر.ق رحلة خاصة",
      seat_vs_en: "Save 70% vs 52 QAR charter",
      parcel_ar: "25 ر.ق · خلال 90 دقيقة",
      parcel_en: "25 QAR · 90m Express",
      parcel_vs_ar: "مثالي لقطع غيار الورش والمحلات",
      parcel_vs_en: "Ideal for B2B auto spare parts & SMEs",
      driver_ar: "75 – 115 ر.ق / مسار",
      driver_en: "75 – 115 QAR / route",
      driver_vs_ar: "توريد سريع بين الورش والمخازن",
      driver_vs_en: "High-frequency workshop & warehouse runs"
    },
    dukhan: {
      origin_ar: "الدوحة (وسط المدينة / الريان)",
      origin_en: "Doha (Central / Al Rayyan)",
      dest_ar: "دخان وأم باب",
      dest_en: "Dukhan & Umm Bab",
      dist_ar: "84 كم · ~60 دقيقة",
      dist_en: "84 km · ~60 mins",
      seat_ar: "35 ر.ق / مقعد",
      seat_en: "35 QAR / seat",
      seat_vs_ar: "توفير 78% مقابل 160 ر.ق تاكسي خاص",
      seat_vs_en: "Save 78% vs 160 QAR private charter",
      parcel_ar: "45 ر.ق · خلال 3 ساعات",
      parcel_en: "45 QAR · 3h Same-Day",
      parcel_vs_ar: "تغطية الغرب القطري في نفس اليوم",
      parcel_vs_en: "Same-day Western Qatar highway fulfillment",
      driver_ar: "150 – 210 ر.ق / رحلة",
      driver_en: "150 – 210 QAR / trip",
      driver_vs_ar: "أعلى عائد كيلومتري على خط الشحانية–دخان",
      driver_vs_en: "Highest corridor yield along Shahaniya–Dukhan"
    }
  };

  const SCREENS = [
    "./assets/mobile/10_tab_home_screen.png",
    "./assets/mobile/11_tab_board_screen.png",
    "./assets/mobile/19_ride_details_screen.png",
    "./assets/mobile/34_parcel_tracking_screen.png",
    "./assets/mobile/52_wallet_screen.png",
    "./assets/mobile/47_vehicle_registration_screen.png",
    "./assets/mobile/50_emergency_sos_sheet.png"
  ];

  const WEB_SCREENS = {
    home: { src: "./assets/web/01_web_home_desktop.png", url: "https://app.mashwar.qa/home" },
    kpis: { src: "./assets/web/06_admin_dashboard_kpis.png", url: "https://admin.mashwar.qa/dashboard-kpis" },
    kyc: { src: "./assets/web/07_admin_driver_verifications.png", url: "https://admin.mashwar.qa/driver-verifications" }
  };

  let currentLang = "ar";
  let currentCorridor = "al_khor";

  function renderCorridor(key) {
    currentCorridor = key;
    const c = CORRIDORS[key];
    if (!c) return;
    const s = currentLang;
    document.getElementById("cor-origin-name").textContent = c[`origin_${s}`];
    document.getElementById("cor-dest-name").textContent = c[`dest_${s}`];
    document.getElementById("cor-dist-badge").textContent = c[`dist_${s}`];
    document.getElementById("cor-k1-val").textContent = c[`seat_${s}`];
    document.getElementById("cor-k1-vs").textContent = c[`seat_vs_${s}`];
    document.getElementById("cor-k2-val").textContent = c[`parcel_${s}`];
    document.getElementById("cor-k2-vs").textContent = c[`parcel_vs_${s}`];
    document.getElementById("cor-k3-val").textContent = c[`driver_${s}`];
    document.getElementById("cor-k3-vs").textContent = c[`driver_vs_${s}`];
  }

  function applyLanguage(lang) {
    currentLang = lang;
    const dict = window.MASHWAR_I18N[lang];
    if (!dict) return;

    document.documentElement.lang = lang;
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
    document.title = dict.page_title;

    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (dict[key] !== undefined) el.textContent = dict[key];
    });

    document.querySelectorAll("[data-cor-ar]").forEach((btn) => {
      btn.textContent = btn.getAttribute(lang === "ar" ? "data-cor-ar" : "data-cor-en");
    });

    renderCorridor(currentCorridor);
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
  }

  function initRevealObserver() {
    const els = Array.from(document.querySelectorAll(".reveal"));
    if (!("IntersectionObserver" in window)) {
      els.forEach((e) => e.classList.add("is-visible"));
      return;
    }
    const revealVisibleOrPassed = () => {
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
    window.addEventListener("scroll", revealVisibleOrPassed, { passive: true });
    revealVisibleOrPassed();
  }

  function initSpotlightCards() {
    if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    document.querySelectorAll(".spotlight-card").forEach((card) => {
      card.addEventListener("mousemove", (e) => {
        const rect = card.getBoundingClientRect();
        card.style.setProperty("--mx", `${e.clientX - rect.left}px`);
        card.style.setProperty("--my", `${e.clientY - rect.top}px`);
      });
    });
  }

  function initSwitchers() {
    document.querySelectorAll("[data-corridor]").forEach((btn) => {
      btn.addEventListener("click", () => {
        document.querySelectorAll("[data-corridor]").forEach((b) => b.classList.toggle("is-active", b === btn));
        renderCorridor(btn.getAttribute("data-corridor"));
      });
    });

    const stageImg = document.getElementById("mobile-screen-img");
    const setMobileScreen = (idx) => {
      document.querySelectorAll("[data-screen-idx]").forEach((b) => b.classList.toggle("is-active", Number(b.getAttribute("data-screen-idx")) === idx));
      if (stageImg && SCREENS[idx]) {
        stageImg.style.opacity = "0.25";
        setTimeout(() => {
          stageImg.src = SCREENS[idx];
          stageImg.style.opacity = "1";
        }, 110);
      }
    };
    document.querySelectorAll("[data-screen-idx]").forEach((btn) => {
      btn.addEventListener("click", () => setMobileScreen(Number(btn.getAttribute("data-screen-idx"))));
    });

    const webImg = document.getElementById("web-stage-img");
    const webUrl = document.getElementById("web-stage-url");
    document.querySelectorAll("[data-web-tab]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const k = btn.getAttribute("data-web-tab");
        document.querySelectorAll("[data-web-tab]").forEach((b) => b.classList.toggle("is-active", b === btn));
        if (webImg && WEB_SCREENS[k]) {
          webImg.src = WEB_SCREENS[k].src;
          if (webUrl) webUrl.textContent = WEB_SCREENS[k].url;
        }
      });
    });
  }

  function initDownloadAndForm() {
    const dlModal = document.getElementById("download-modal");
    const dlClose = document.getElementById("download-modal-close");
    const dlReqBtn = document.getElementById("modal-request-build");
    const isLocalHost = ["localhost", "127.0.0.1"].includes(window.location.hostname);

    const openDl = () => {
      if (!dlModal) return;
      dlModal.classList.add("is-open");
      dlModal.setAttribute("aria-hidden", "false");
    };
    const closeDl = () => {
      if (!dlModal) return;
      dlModal.classList.remove("is-open");
      dlModal.setAttribute("aria-hidden", "true");
    };

    const localLaunch = document.getElementById("modal-local-launch");
    if (localLaunch) {
      localLaunch.style.display = isLocalHost ? "inline-flex" : "none";
    }

    document.querySelectorAll("[data-open-download]").forEach((btn) => btn.addEventListener("click", openDl));
    document.querySelectorAll("[data-live-web-btn]").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        if (!isLocalHost) {
          e.preventDefault();
          openDl();
        }
      });
    });

    if (dlClose) dlClose.addEventListener("click", closeDl);
    if (dlModal) dlModal.addEventListener("click", (e) => { if (e.target === dlModal) closeDl(); });
    document.addEventListener("keydown", (e) => { if (e.key === "Escape") closeDl(); });

    if (dlReqBtn) {
      dlReqBtn.addEventListener("click", () => {
        closeDl();
        const form = document.getElementById("investor-form");
        if (form) form.scrollIntoView({ behavior: "smooth" });
        const sel = document.getElementById("inv-interest");
        if (sel) sel.selectedIndex = 1;
        const nameInput = document.getElementById("inv-name");
        if (nameInput) nameInput.focus();
      });
    }

    const form = document.getElementById("investor-form");
    const status = document.getElementById("investor-form-status");
    if (form && status) {
      form.addEventListener("submit", (e) => {
        e.preventDefault();
        status.classList.add("is-visible");
        form.reset();
      });
    }
  }

  function init() {
    const langBtn = document.getElementById("lang-toggle-btn");
    if (langBtn) {
      langBtn.addEventListener("click", () => applyLanguage(currentLang === "ar" ? "en" : "ar"));
    }
    initHeaderScroll();
    initMobileDrawer();
    initRevealObserver();
    initSpotlightCards();
    initSwitchers();
    initDownloadAndForm();
    applyLanguage("ar");
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
