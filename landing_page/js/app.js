/* MASHWAR (مشوار — Qatar) Landing Page Interactions & Live Corridor Uber Map */
(function () {
  const CORRIDORS = {
    al_khor: {
      origin_ar: "الدوحة (مشيرب / الخليج الغربي)",
      origin_en: "Doha (Msheireb / West Bay)",
      dest_ar: "الخور (الكورنيش / رأس لفان)",
      dest_en: "Al Khor (Corniche / Ras Laffan)",
      fromLat: 25.2854,
      fromLng: 51.5310,
      toLat: 25.6804,
      toLng: 51.4969,
      distKm: 52,
      etaMin: 39,
      hwy_ar: "طريق الخور الساحلي",
      hwy_en: "Al Khor Coastal Rd",
      defaultMode: "trip",
      dist_ar: "52 كم · ~39 دقيقة",
      dist_en: "52 km · ~39 mins",
      seat_ar: "25 – 35 ر.ق / مقعد",
      seat_en: "25 – 35 QAR / seat",
      seat_vs_ar: "أوفر بحوالي 70% من المشوار الخاص (105+ ر.ق)",
      seat_vs_en: "About 70% less than a private ride (105+ QAR)",
      parcel_ar: "20 – 35 ر.ق · نفس اليوم",
      parcel_en: "20 – 35 QAR · Same-Day",
      parcel_vs_ar: "مباشرة مع مسافر بكودين OTP بدون مخازن فرز",
      parcel_vs_en: "Direct with a traveler + dual 4-digit OTP",
      driver_ar: "110 – 160 ر.ق / رحلة ذهاب",
      driver_en: "110 – 160 QAR / trip",
      driver_vs_ar: "مقاعد فاضية + طرد أو مستند على نفس الطريق",
      driver_vs_en: "Spare seats + a parcel along the route you drive"
    },
    lusail_supply: {
      origin_ar: "المنطقة الصناعية (شارع 10)",
      origin_en: "Doha Industrial Area (St 10)",
      dest_ar: "مارينا لوسيل ومواقع الأبراج",
      dest_en: "Lusail Marina & Project Sites",
      fromLat: 25.1903,
      fromLng: 51.4426,
      toLat: 25.4300,
      toLng: 51.4900,
      distKm: 36,
      etaMin: 29,
      hwy_ar: "طريق الدوحة السريع / محور سلوى",
      hwy_en: "Doha Expressway / Salwa Axis",
      defaultMode: "supply",
      dist_ar: "36 كم · ~29 دقيقة",
      dist_en: "36 km · ~29 mins",
      seat_ar: "18 ر.ق / مقعد",
      seat_en: "18 QAR / seat",
      seat_vs_ar: "مثالي لتنقل المهندسين والفنيين اليومي",
      seat_vs_en: "Practical daily ride for site engineers & technicians",
      parcel_ar: "45 – 60 ر.ق · توريد موقع بفاتورة",
      parcel_en: "45 – 60 QAR · Receipt-Verified Supply",
      parcel_vs_ar: "صورة الفاتورة من المحل + كود تسليم من 6 خانات",
      parcel_vs_en: "Store invoice photo + 6-char SHA-256 handover code",
      driver_ar: "120 – 185 ر.ق / مشوار",
      driver_en: "120 – 185 QAR / run",
      driver_vs_ar: "توريد مواد كهرباء وسباكة ومعدات مباشرة للموقع",
      driver_vs_en: "Direct electrical, plumbing & tool supply runs"
    },
    mesaieed: {
      origin_ar: "الدوحة / الوكرة",
      origin_en: "Doha / Al Wakrah",
      dest_ar: "مدينة مسيعيد الصناعية",
      dest_en: "Mesaieed Industrial City",
      fromLat: 25.2854,
      fromLng: 51.5310,
      toLat: 24.9923,
      toLng: 51.5507,
      distKm: 48,
      etaMin: 38,
      hwy_ar: "طريق الوكرة – مسيعيد",
      hwy_en: "Al Wakrah – Mesaieed Rd",
      defaultMode: "trip",
      dist_ar: "48 كم · ~38 دقيقة",
      dist_en: "48 km · ~38 mins",
      seat_ar: "22 ر.ق / مقعد",
      seat_en: "22 QAR / seat",
      seat_vs_ar: "مقارنة بـ ~90 ر.ق للمشوار الفردي",
      seat_vs_en: "Compared to ~90 QAR for a solo trip",
      parcel_ar: "30 ر.ق · خلال ساعتين",
      parcel_en: "30 QAR · ~2h Handoff",
      parcel_vs_ar: "تسليم مباشر لمواقع المصانع بكود OTP",
      parcel_vs_en: "Direct industrial plant handoff with OTP",
      driver_ar: "95 – 140 ر.ق / رحلة",
      driver_en: "95 – 140 QAR / trip",
      driver_vs_ar: "مبني على دوام الموظفين والمهندسين اليومي",
      driver_vs_en: "Built around daily shift commuters"
    },
    industrial: {
      origin_ar: "المنطقة الصناعية الدوحة",
      origin_en: "Doha Industrial Area",
      dest_ar: "الوكرة ومدينة بروة",
      dest_en: "Al Wakrah & Barwa City",
      fromLat: 25.1903,
      fromLng: 51.4426,
      toLat: 25.1715,
      toLng: 51.6034,
      distKm: 28,
      etaMin: 24,
      hwy_ar: "طريق المنطقة الصناعية – الوكرة",
      hwy_en: "Industrial – Al Wakrah Link",
      defaultMode: "parcel",
      dist_ar: "28 كم · ~24 دقيقة",
      dist_en: "28 km · ~24 mins",
      seat_ar: "15 ر.ق / مقعد",
      seat_en: "15 QAR / seat",
      seat_vs_ar: "توفير واضح عن المشوار الخاص (~52 ر.ق)",
      seat_vs_en: "Clear savings vs ~52 QAR solo ride",
      parcel_ar: "25 ر.ق · خلال 90 دقيقة",
      parcel_en: "25 QAR · ~90m Express",
      parcel_vs_ar: "ممتاز لقطع غيار الورش والمحلات بفاتورة واضحة",
      parcel_vs_en: "Handy for workshop spare parts & store receipts",
      driver_ar: "75 – 115 ر.ق / مسار",
      driver_en: "75 – 115 QAR / route",
      driver_vs_ar: "طلبات سريعة متكررة بين الورش والفروع",
      driver_vs_en: "Frequent short runs between workshops & shops"
    },
    dukhan: {
      origin_ar: "الدوحة (وسط المدينة / الريان)",
      origin_en: "Doha (Central / Al Rayyan)",
      dest_ar: "دخان وأم باب",
      dest_en: "Dukhan & Umm Bab",
      fromLat: 25.2854,
      fromLng: 51.5310,
      toLat: 25.4281,
      toLng: 50.7822,
      distKm: 84,
      etaMin: 60,
      hwy_ar: "طريق دخان السريع",
      hwy_en: "Dukhan Highway",
      defaultMode: "trip",
      dist_ar: "84 كم · ~60 دقيقة",
      dist_en: "84 km · ~60 mins",
      seat_ar: "35 ر.ق / مقعد",
      seat_en: "35 QAR / seat",
      seat_vs_ar: "أوفر بحوالي 75% من المشوار الخاص (160 ر.ق)",
      seat_vs_en: "Around 75% cheaper than a 160 QAR private ride",
      parcel_ar: "45 ر.ق · خلال 3 ساعات",
      parcel_en: "45 QAR · Within 3h",
      parcel_vs_ar: "تغطية الغرب القطري بدون انتظار شحن اليوم التالي",
      parcel_vs_en: "Covers western Qatar without next-day courier wait",
      driver_ar: "150 – 210 ر.ق / رحلة",
      driver_en: "150 – 210 QAR / trip",
      driver_vs_ar: "يغطي تكلفة المشوار الطويل على خط الشحانية–دخان",
      driver_vs_en: "Offsets long-haul fuel along Shahaniya–Dukhan"
    }
  };

  const SCREENS = [
    "./assets/mobile/10_tab_home_screen.png",
    "./assets/mobile/19_ride_details_screen.png",
    "./assets/mobile/34_parcel_tracking_screen.png",
    "./assets/mobile/11_tab_board_screen.png",
    "./assets/mobile/28_post_ad_screen.png",
    "./assets/mobile/47_vehicle_registration_screen.png",
    "./assets/mobile/35_pickup_code_dialog.png",
    "./assets/mobile/50_emergency_sos_sheet.png",
    "./assets/mobile/67_service_escrow_screen.png"
  ];

  const WEB_SCREENS = {
    app_home: { src: "./assets/web/app_home_live_map.png", url: "https://app.mashwar.qa/home" },
    app_traffic: { src: "./assets/web/app_fullscreen_traffic_map.png", url: "https://app.mashwar.qa/map?traffic=live" },
    app_ride: { src: "./assets/web/app_ride_details_live.png", url: "https://app.mashwar.qa/trips/ride-details" },
    app_supply: { src: "./assets/web/app_worksite_supply_live.png", url: "https://app.mashwar.qa/supply/request-details" },
    admin_dash: { src: "./assets/web/admin_live_dashboard.png", url: "https://admin.mashwar.qa/dashboard" },
    admin_ops: { src: "./assets/web/admin_live_login_dark.png", url: "https://admin.mashwar.qa/login" }
  };

  let currentLang = "ar";
  let currentCorridor = "al_khor";
  let currentMapMode = "trip";

  function buildCorridorMapUrl(c, mode, lang) {
    const params = new URLSearchParams({
      fromLat: String(c.fromLat),
      fromLng: String(c.fromLng),
      fromName: c[`origin_${lang}`],
      toLat: String(c.toLat),
      toLng: String(c.toLng),
      toName: c[`dest_${lang}`],
      mode: mode || c.defaultMode || "trip",
      style: "google",
      traffic: "1",
      lang: lang,
      nearby: "1",
      dist: String(c.distKm),
      eta: String(c.etaMin),
      hwy: c[`hwy_${lang}`]
    });
    return `./maps/mashwar_uber_map.html?${params.toString()}`;
  }

  function renderCorridor(key, overrideMode) {
    currentCorridor = key;
    const c = CORRIDORS[key];
    if (!c) return;
    currentMapMode = overrideMode || c.defaultMode || "trip";
    const s = currentLang;

    const setText = (id, val) => {
      const el = document.getElementById(id);
      if (el) el.textContent = val;
    };

    setText("cor-origin-name", c[`origin_${s}`]);
    setText("cor-dest-name", c[`dest_${s}`]);
    setText("cor-dist-badge", c[`dist_${s}`]);
    setText("cor-k1-val", c[`seat_${s}`]);
    setText("cor-k1-vs", c[`seat_vs_${s}`]);
    setText("cor-k2-val", c[`parcel_${s}`]);
    setText("cor-k2-vs", c[`parcel_vs_${s}`]);
    setText("cor-k3-val", c[`driver_${s}`]);
    setText("cor-k3-vs", c[`driver_vs_${s}`]);

    document.querySelectorAll("[data-cor-mode]").forEach((btn) => {
      btn.classList.toggle("is-active", btn.getAttribute("data-cor-mode") === currentMapMode);
    });

    const iframe = document.getElementById("corridor-live-map");
    if (iframe) {
      iframe.src = buildCorridorMapUrl(c, currentMapMode, s);
    }
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

    renderCorridor(currentCorridor, currentMapMode);
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

    document.querySelectorAll("[data-cor-mode]").forEach((btn) => {
      btn.addEventListener("click", () => {
        renderCorridor(currentCorridor, btn.getAttribute("data-cor-mode"));
      });
    });

    const stageImg = document.getElementById("mobile-screen-img");
    const setMobileScreen = (idx) => {
      document.querySelectorAll("[data-screen-idx]").forEach((b) =>
        b.classList.toggle("is-active", Number(b.getAttribute("data-screen-idx")) === idx)
      );
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
          webImg.style.opacity = "0.35";
          setTimeout(() => {
            webImg.src = WEB_SCREENS[k].src;
            webImg.style.opacity = "1";
            if (webUrl) webUrl.textContent = WEB_SCREENS[k].url;
          }, 90);
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
    const localAdminLaunch = document.getElementById("modal-local-admin-launch");
    if (localAdminLaunch) {
      localAdminLaunch.style.display = isLocalHost ? "inline-flex" : "none";
    }

    document.querySelectorAll("[data-open-download]").forEach((btn) => btn.addEventListener("click", openDl));
    document.querySelectorAll("[data-live-web-btn], [data-live-admin-btn]").forEach((btn) => {
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
