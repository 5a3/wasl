/* ==========================================================================
   Wasl Lee (وصل لي) - Main Interactive & Bilingual Logic
   ========================================================================== */

const translations = {
  ar: {
    navHome: "الرئيسية",
    navFeatures: "المميزات",
    navContacts: "التواصل والإدارة",
    navPrivacy: "سياسة الخصوصية",
    btnDownload: "تحميل التطبيق 📲",
    heroBadge: "🚀 المنصة الأولى للتوصيل السريع والوجبات الطازجة",
    heroTitle: "طلبك من مقهى جدة <span>يصلك بغمضة عين!</span>",
    heroDesc: "تطبيق وصل لي يضمن لك تصفح قائمة الوجبات السريعة، إكمال الطلب في ثوانٍ، وتتبع حالة وجبتك لحظة بلحظة حتى باب منزلك.",
    btnDownloadNow: "حمل التطبيق الآن 🍔",
    btnLearnMore: "اكتشف المميزات ⚡",
    statCustomers: "+10,000 عميل سعيد",
    statOrders: "+50,000 وجبة تم توصيلها",
    statRating: "4.9★ تقييم التطبيق",
    statSpeed: "20 دقيقة متوسط التوصيل",
    featuresTag: "لماذا تطبيق وصل لي؟",
    featuresTitle: "تجربة طلب فريدة تضمن راحتك ورضاك الكامل",
    feat1Title: "تصفح القائمة والوجبات الطازجة 🍔",
    feat1Desc: "عرض شامل لكافة الوجبات، المشروبات، والسندويشات مع صور عالية الجودة وأسعار محدثة.",
    feat2Title: "تتبع لحظي للطلب 🛵",
    feat2Desc: "متابعة حالة الطلب خطوة بخطوة من التحضير بالمطبخ وحتى خروج المندوب ووصوله لإليك.",
    feat3Title: "حفظ موقع التسليم والعناوين 📍",
    feat3Desc: "تخزين عنوان وموقع العميل المسجل بحسابه عند إتمام الطلب لتسهيل وصول المندوب لمكان العميل وتسليم الوجبة بسرعة.",
    feat4Title: "تقييد الشكاوى وحظر اليوم 🛑",
    feat4Desc: "نظام شكاوى ذكي يتيح لك إرسال ملاحظاتك للإدارة مع حظر إساءة الاستخدام بمحاولتين يومياً.",
    feat5Title: "إشعارات عامة وعروض 🔔",
    feat5Desc: "إرسال إشعارات وتنبيهات عامة وعروض ترويجية وتحديثات من إدارة المحل للعملاء أولاً بأول.",
    feat6Title: "أمان وخصوصية تامة 🔐",
    feat6Desc: "حماية كاملة لبياناتك الشخصية وموقعك دون مشاركتها مع أي أطراف خارجية.",
    feat7Title: "إدارة السندات والجرد الدوري 📊",
    feat7Desc: "إمكانية قيام إدارة المحل بعمل جرد دوري وحذف السندات والطلبات السابقة أسبوعياً أو شهرياً لتنظيف وتفريغ قاعدة البيانات بسهولة.",
    contactsTag: "التواصل المباشر مع الإدارة",
    contactsTitle: "فريق الإدارة والدعم الفني في خدمتك دائماً",
    ownerRole: "صاحب ومسؤول المحل 🍔",
    ownerName: "مقهى جدة للوجبات السريعة",
    ownerPhone: "773062568",
    devRole: "الدعم الفني ومطور التطبيق 🛠️",
    devName: "م. أحمد العطاس",
    devPhone: "770985114",
    btnCall: "اتصال هاتف 📞",
    btnWhatsapp: "واتساب 💬",
    footerText: "جميع الحقوق محفوظة © 2026 لتطبيق وصل لي (com.ahmedalattas.wasl).",
    privacyTitle: "سياسة الخصوصية وتطبيق وصل لي",
    privacySub: "تاريخ آخر تحديث: 30 يوليو 2026",
  },
  en: {
    navHome: "Home",
    navFeatures: "Features",
    navContacts: "Contact & Mgmt",
    navPrivacy: "Privacy Policy",
    btnDownload: "Download App 📲",
    heroBadge: "🚀 The Premier Platform for Fast Delivery & Fresh Meals",
    heroTitle: "Your Orders from Jeddah Fast Food <span>Delivered Instantly!</span>",
    heroDesc: "Wasl Lee ensures seamless menu browsing, instant checkout, and real-time order tracking straight to your doorstep.",
    btnDownloadNow: "Download App Now 🍔",
    btnLearnMore: "Explore Features ⚡",
    statCustomers: "+10,000 Happy Clients",
    statOrders: "+50,000 Meals Delivered",
    statRating: "4.9★ App Rating",
    statSpeed: "20 Min Avg Delivery",
    featuresTag: "Why Choose Wasl Lee?",
    featuresTitle: "A Unique Ordering Experience Built for Your Satisfaction",
    feat1Title: "Fresh Meals & Menu Browsing 🍔",
    feat1Desc: "Explore our full catalog of burgers, drinks, and meals with high-res photos and real-time prices.",
    feat2Title: "Live Order Tracking 🛵",
    feat2Desc: "Track your order status step-by-step from kitchen preparation to courier delivery.",
    feat3Title: "Saved Delivery Address 📍",
    feat3Desc: "Saved account delivery location used at checkout so drivers easily reach your exact location.",
    feat4Title: "Smart Complaint System 🛑",
    feat4Desc: "Direct feedback channel to store management with fair 2-per-day rate limiting.",
    feat5Title: "General Announcements 🔔",
    feat5Desc: "Receive general announcements, promotions, and store updates from administration.",
    feat6Title: "Total Privacy & Security 🔐",
    feat6Desc: "Complete protection for your personal info and location with zero third-party leaks.",
    feat7Title: "Inventory Auditing & Receipt Cleanup 📊",
    feat7Desc: "Empowers store management to perform periodic inventory audits and purge/archive past receipts weekly or monthly.",
    contactsTag: "Direct Management Contact",
    contactsTitle: "Management & Tech Support Always At Your Service",
    ownerRole: "Store Owner & Manager 🍔",
    ownerName: "Jeddah Fast Food Cafeteria",
    ownerPhone: "773062568",
    devRole: "Tech Support & Lead Developer 🛠️",
    devName: "Eng. Ahmed Al-Attas",
    devPhone: "770985114",
    btnCall: "Direct Call 📞",
    btnWhatsapp: "WhatsApp 💬",
    footerText: "All Rights Reserved © 2026 Wasl Lee App (com.ahmedalattas.wasl).",
    privacyTitle: "Privacy Policy for Wasl Lee App",
    privacySub: "Last Updated: July 30, 2026",
  }
};

let currentLang = localStorage.getItem('wasl_lang') || 'ar';
let currentTheme = localStorage.getItem('wasl_theme') || 'light';

// Initialize Theme & Language on Load
document.addEventListener('DOMContentLoaded', () => {
  setTheme(currentTheme);
  setLanguage(currentLang);
  initAnimations();
});

// Switch Theme Function
function toggleTheme() {
  currentTheme = currentTheme === 'light' ? 'dark' : 'light';
  setTheme(currentTheme);
  localStorage.setItem('wasl_theme', currentTheme);
}

function setTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);
  const themeBtn = document.getElementById('themeToggleBtn');
  if (themeBtn) {
    themeBtn.innerHTML = theme === 'dark' ? '☀️ Bright' : '🌙 Dark';
  }
}

// Switch Language Function
function toggleLanguage() {
  currentLang = currentLang === 'ar' ? 'en' : 'ar';
  setLanguage(currentLang);
  localStorage.setItem('wasl_lang', currentLang);
}

function setLanguage(lang) {
  document.body.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
  const langBtn = document.getElementById('langToggleBtn');
  if (langBtn) {
    langBtn.innerHTML = lang === 'ar' ? '🇬🇧 English' : '🇸🇦 العربية';
  }

  // Translate all marked elements
  document.querySelectorAll('[data-key]').forEach(elem => {
    const key = elem.getAttribute('data-key');
    if (translations[lang] && translations[lang][key]) {
      if (elem.tagName === 'INPUT' || elem.tagName === 'TEXTAREA') {
        elem.placeholder = translations[lang][key];
      } else {
        elem.innerHTML = translations[lang][key];
      }
    }
  });
}

// Simple Counter Animation
function initAnimations() {
  const statNumbers = document.querySelectorAll('.stat-item h3');
  statNumbers.forEach(stat => {
    stat.style.opacity = '1';
  });
}
