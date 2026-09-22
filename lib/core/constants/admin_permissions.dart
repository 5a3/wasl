import 'package:flutter/material.dart';

/// Single micro-permission item descriptor
class AdminPermissionItem {
  final String key;
  final String title;
  final String description;
  final IconData icon;

  const AdminPermissionItem({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Single permission category group
class AdminPermissionGroup {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<AdminPermissionItem> items;

  const AdminPermissionGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

/// Constants and helper tools for Ultra-Granular Admin Permissions (42 Permissions / 10 Modules)
class AdminPermissions {
  // --- 1. Products Module ---
  static const String productsView = 'products_view';
  static const String productsAdd = 'products_add';
  static const String productsEdit = 'products_edit';
  static const String productsToggleAvailability = 'products_toggle_availability';
  static const String productsDelete = 'products_delete';

  // --- 2. Categories Module ---
  static const String categoriesView = 'categories_view';
  static const String categoriesAdd = 'categories_add';
  static const String categoriesEdit = 'categories_edit';
  static const String categoriesDelete = 'categories_delete';
  static const String categoriesManage = 'categories_manage';

  // --- 3. Orders Module ---
  static const String ordersView = 'orders_view';
  static const String ordersViewDetails = 'orders_view_details';
  static const String ordersPrintReceipt = 'orders_print_receipt';
  static const String ordersAcceptPrepare = 'orders_accept_prepare';
  static const String ordersSendDelivery = 'orders_send_delivery';
  static const String ordersMarkCompleted = 'orders_mark_completed';
  static const String ordersCancel = 'orders_cancel';
  static const String ordersDelete = 'orders_delete';

  // --- 4. Delivery Zones Module ---
  static const String deliveryZonesView = 'delivery_zones_view';
  static const String deliveryZonesAdd = 'delivery_zones_add';
  static const String deliveryZonesEdit = 'delivery_zones_edit';
  static const String deliveryZonesToggle = 'delivery_zones_toggle';
  static const String deliveryZonesDelete = 'delivery_zones_delete';

  // --- 5. Store Status Module ---
  static const String storeStatusView = 'store_status_view';
  static const String storeStatusToggle = 'store_status_toggle';
  static const String storeClosedReasonEdit = 'store_closed_reason_edit';

  // --- 6. Ads & Banners Module ---
  static const String adsView = 'ads_view';
  static const String adsAdd = 'ads_add';
  static const String adsEdit = 'ads_edit';
  static const String adsDelete = 'ads_delete';

  // --- 7. Push Notifications Module ---
  static const String notificationsView = 'notifications_view';
  static const String notificationsSendAll = 'notifications_send_all';
  static const String notificationsDelete = 'notifications_delete';

  // --- 8. Complaints Module ---
  static const String complaintsView = 'complaints_view';
  static const String complaintsReply = 'complaints_reply';
  static const String complaintsDelete = 'complaints_delete';

  // --- 9. Analytics & Reports Module ---
  static const String reportsViewSummary = 'reports_view_summary';
  static const String reportsViewFinancial = 'reports_view_financial';
  static const String reportsExportPdf = 'reports_export_pdf';
  static const String reportsFilterByAdmin = 'reports_filter_by_admin';

  // --- 10. Sub-Admins Management Module ---
  static const String subAdminsView = 'sub_admins_view';
  static const String subAdminsAdd = 'sub_admins_add';
  static const String subAdminsEditPermissions = 'sub_admins_edit_permissions';
  static const String subAdminsDelete = 'sub_admins_delete';

  // --- 11. Payment Methods Module ---
  static const String paymentMethodsView = 'payment_methods_view';
  static const String paymentMethodsAdd = 'payment_methods_add';
  static const String paymentMethodsEdit = 'payment_methods_edit';
  static const String paymentMethodsDelete = 'payment_methods_delete';

  // --- 12. Cities Module ---
  static const String citiesView = 'cities_view';
  static const String citiesAdd = 'cities_add';
  static const String citiesEdit = 'cities_edit';
  static const String citiesDelete = 'cities_delete';

  // --- 13. Stores & Vendor Link Module ---
  static const String storesView = 'stores_view';
  static const String storesAdd = 'stores_add';
  static const String storesEdit = 'stores_edit';
  static const String storesLinkCategoriesCities = 'stores_link_categories_cities';
  static const String storesToggleStatus = 'stores_toggle_status';
  static const String storesDelete = 'stores_delete';

  // --- 14. Store Categories Module ---
  static const String storeCategoriesView = 'store_categories_view';
  static const String storeCategoriesAdd = 'store_categories_add';
  static const String storeCategoriesEdit = 'store_categories_edit';
  static const String storeCategoriesDelete = 'store_categories_delete';

  /// Calculate dynamic total count of all micro-permissions
  static int get allPermissionsCount {
    int total = 0;
    for (final group in allGroups) {
      total += group.items.length;
    }
    return total;
  }

  /// All Categorized Permission Groups with metadata for the UI
  static const List<AdminPermissionGroup> allGroups = [
    AdminPermissionGroup(
      id: 'products',
      title: '🍽️ المأكولات والوجبات',
      icon: Icons.fastfood_outlined,
      color: Colors.orange,
      items: [
        AdminPermissionItem(
          key: productsView,
          title: 'عرض الوجبات والأسعار',
          description: 'تصفح قائمة الوجبات والبحث والاطلاع على تفاصيلها',
          icon: Icons.visibility_outlined,
        ),
        AdminPermissionItem(
          key: productsAdd,
          title: 'إضافة وجبة/منتج جديد',
          description: 'إنشاء وجبة جديدة ورفع الصور وتحديد الأسعار',
          icon: Icons.add_circle_outline,
        ),
        AdminPermissionItem(
          key: productsEdit,
          title: 'تعديل بيانات الوجبات',
          description: 'تغيير الاسم، الوصف، السعر والصور لأي وجبة',
          icon: Icons.edit_note_outlined,
        ),
        AdminPermissionItem(
          key: productsToggleAvailability,
          title: 'تعديل التوفر (متوفر / غير متوفر)',
          description: 'مفتاح التغيير السريع لتأكيد توفر أو نفاد الوجبة',
          icon: Icons.toggle_on_outlined,
        ),
        AdminPermissionItem(
          key: productsDelete,
          title: 'حذف الوجبات نهائياً',
          description: 'مسح وحذف المنتج وصوره من النظام',
          icon: Icons.delete_outline,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'categories',
      title: '📁 الفئات والتصنيفات',
      icon: Icons.category_outlined,
      color: Colors.amber,
      items: [
        AdminPermissionItem(
          key: categoriesView,
          title: 'عرض الفئات الرئيسية والفرعية',
          description: 'استعراض شجرة أقسام المأكولات والمشروبات',
          icon: Icons.grid_view_outlined,
        ),
        AdminPermissionItem(
          key: categoriesAdd,
          title: 'إضافة فئة جديدة',
          description: 'إنشاء تصنيف جديد ورفع صورة الشعار الخاصة به',
          icon: Icons.create_new_folder_outlined,
        ),
        AdminPermissionItem(
          key: categoriesEdit,
          title: 'تعديل بيانات الفئات',
          description: 'تغيير اسم الفئة وصورتها وترتيب ظهورها',
          icon: Icons.drive_file_rename_outline,
        ),
        AdminPermissionItem(
          key: categoriesDelete,
          title: 'حذف الفئات والتصنيفات',
          description: 'إزالة الفئة وتصفية المنتجات المندرجة تحتها',
          icon: Icons.folder_delete_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'orders',
      title: '🧾 الطلبات والمبيعات',
      icon: Icons.receipt_long_outlined,
      color: Colors.blue,
      items: [
        AdminPermissionItem(
          key: ordersView,
          title: 'عرض قائمة الطلبات والبحث',
          description: 'مشاهدة الطلبات الجارية والمكتملة والتصفية',
          icon: Icons.list_alt_outlined,
        ),
        AdminPermissionItem(
          key: ordersViewDetails,
          title: 'عرض بيانات وتلفونات العملاء',
          description: 'مشاهدة التفاصيل الدقيقة للعميل وعنوان التوصيل',
          icon: Icons.contact_phone_outlined,
        ),
        AdminPermissionItem(
          key: ordersPrintReceipt,
          title: 'طباعة الإيصالات والفواتير',
          description: 'توليد وطباعة فاتورة الطلب بصيغة PDF',
          icon: Icons.print_outlined,
        ),
        AdminPermissionItem(
          key: ordersAcceptPrepare,
          title: 'قبول وتحضير الطلب 🍳',
          description: 'تحويل حالة الطلب إلى قيد التجهيز بالمطبخ',
          icon: Icons.soup_kitchen_outlined,
        ),
        AdminPermissionItem(
          key: ordersSendDelivery,
          title: 'تسليم الطلب للمندوب 🛵',
          description: 'تحويل حالة الطلب إلى جاري التوصيل مع السائق',
          icon: Icons.delivery_dining_outlined,
        ),
        AdminPermissionItem(
          key: ordersMarkCompleted,
          title: 'إكمال وتسليم الطلب ✅',
          description: 'إنهاء الطلب وتأكيد الاستلام الناجح',
          icon: Icons.task_alt_outlined,
        ),
        AdminPermissionItem(
          key: ordersCancel,
          title: 'إلغاء وتجميع الطلبات ❌',
          description: 'رفض الطلب وإلغائه مع تحديد السبب',
          icon: Icons.cancel_outlined,
        ),
        AdminPermissionItem(
          key: ordersDelete,
          title: 'حذف الطلبات نهائياً',
          description: 'مسح سجل الطلب بشكل نهائي من قاعدة البيانات',
          icon: Icons.delete_forever_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'delivery',
      title: '🚚 التوصيل والمناطق',
      icon: Icons.local_shipping_outlined,
      color: Colors.teal,
      items: [
        AdminPermissionItem(
          key: deliveryZonesView,
          title: 'عرض مناطق التوصيل',
          description: 'استعراض المناطق المخدومة وأسعار التوصيل',
          icon: Icons.map_outlined,
        ),
        AdminPermissionItem(
          key: deliveryZonesAdd,
          title: 'إضافة منطقة توصيل جديدة',
          description: 'إدراج منطقة جديدة وتحديد رسوم توصيلها',
          icon: Icons.add_location_alt_outlined,
        ),
        AdminPermissionItem(
          key: deliveryZonesEdit,
          title: 'تعديل أسعار ورسوم التوصيل',
          description: 'تعديل أسعار ورسوم المناطق وتحديثها',
          icon: Icons.edit_location_alt_outlined,
        ),
        AdminPermissionItem(
          key: deliveryZonesToggle,
          title: 'إيقاف وتفعيل التوصيل للمنطقة',
          description: 'تفعيل أو إيقاف استقبال الطلبات لمنطقة معينة مؤقتاً',
          icon: Icons.wrong_location_outlined,
        ),
        AdminPermissionItem(
          key: deliveryZonesDelete,
          title: 'حذف مناطق التوصيل',
          description: 'حذف المنطقة نهائياً من قائمة التوصيل المتاحة',
          icon: Icons.wrong_location_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'store',
      title: '🏪 تشغيل وإغلاق المحل',
      icon: Icons.storefront_outlined,
      color: Colors.redAccent,
      items: [
        AdminPermissionItem(
          key: storeStatusView,
          title: 'مشاهدة حالة فتح المحل',
          description: 'معرفة هل المطعم مغلق أم يتقبل طلبات حالياً',
          icon: Icons.store_outlined,
        ),
        AdminPermissionItem(
          key: storeStatusToggle,
          title: 'فتح وإغلاق المحل والمطعم 🔴🟢',
          description: 'مفتاح إيقاف أو استقبال طلبات العملاء فورياً',
          icon: Icons.power_settings_new_outlined,
        ),
        AdminPermissionItem(
          key: storeClosedReasonEdit,
          title: 'تعديل سبب إغلاق المحل',
          description: 'كتابة النص الذي يظهر للعملاء عند الإغلاق',
          icon: Icons.edit_note_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'ads',
      title: '📢 الإعلانات والعروض',
      icon: Icons.campaign_outlined,
      color: Colors.purple,
      items: [
        AdminPermissionItem(
          key: adsView,
          title: 'عرض بنرات الإعلانات',
          description: 'مشاهدة الإعلانات المنشورة في أعلى التطبيق',
          icon: Icons.view_carousel_outlined,
        ),
        AdminPermissionItem(
          key: adsAdd,
          title: 'نشر إعلان / عرض جديد',
          description: 'رفع صورة إعلان ترويجي جديد وتحديد تفاصيله',
          icon: Icons.add_photo_alternate_outlined,
        ),
        AdminPermissionItem(
          key: adsEdit,
          title: 'تعديل بنرات الإعلانات',
          description: 'تغيير صورة الإعلان، العنوان، أو الرابط',
          icon: Icons.mode_edit_outline,
        ),
        AdminPermissionItem(
          key: adsDelete,
          title: 'حذف وتوقيف الإعلان',
          description: 'حذف الإعلان وإزالته من واجهة العملاء',
          icon: Icons.hide_image_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'notifications',
      title: '🔔 الإشعارات الجماعية',
      icon: Icons.notifications_active_outlined,
      color: Colors.indigo,
      items: [
        AdminPermissionItem(
          key: notificationsView,
          title: 'عرض سجل الإشعارات',
          description: 'مشاهدة الإشعارات السابقة المرسلة للعملاء',
          icon: Icons.mark_email_read_outlined,
        ),
        AdminPermissionItem(
          key: notificationsSendAll,
          title: 'إرسال إشعار عام للعملاء 📲',
          description: 'إرسال تنبيه جماعي عبر FCM لكل أجهزة العملاء',
          icon: Icons.send_rounded,
        ),
        AdminPermissionItem(
          key: notificationsDelete,
          title: 'حذف الإشعارات من السجل',
          description: 'مسح الإشعارات السابقة من الأرشيف',
          icon: Icons.delete_sweep_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'complaints',
      title: '📩 الشكاوى والمقترحات',
      icon: Icons.rate_review_outlined,
      color: Colors.deepOrange,
      items: [
        AdminPermissionItem(
          key: complaintsView,
          title: 'عرض رسائل وشكاوى العملاء',
          description: 'قراءة الملاحظات والشكاوى المرفوعة من العملاء',
          icon: Icons.mark_chat_read_outlined,
        ),
        AdminPermissionItem(
          key: complaintsReply,
          title: 'الرد وتغيير حالة الشكوى',
          description: 'الرد على العميل وتغيير الحالة إلى (تم الحل)',
          icon: Icons.reply_outlined,
        ),
        AdminPermissionItem(
          key: complaintsDelete,
          title: 'حذف رسائل الشكاوى',
          description: 'إزالة ومسح الشكوى من القائمة',
          icon: Icons.delete_outline,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'reports',
      title: '📊 التقارير والإحصائيات',
      icon: Icons.bar_chart_outlined,
      color: Colors.green,
      items: [
        AdminPermissionItem(
          key: reportsViewSummary,
          title: 'عرض الإحصائيات العامة',
          description: 'مشاهدة أعداد الطلبات وإجمالي المبيعات الإجمالية',
          icon: Icons.pie_chart_outline,
        ),
        AdminPermissionItem(
          key: reportsViewFinancial,
          title: 'عرض الأرباح المالية التفصيلية 💵',
          description: 'الاطلاع على الأرباح الصافية وعائدات كل منطقة',
          icon: Icons.account_balance_wallet_outlined,
        ),
        AdminPermissionItem(
          key: reportsExportPdf,
          title: 'تصدير وطباعة تقرير PDF',
          description: 'توليد ملف PDF شامل للمبيعات وطباعته أو مشاركته',
          icon: Icons.picture_as_pdf_outlined,
        ),
        AdminPermissionItem(
          key: reportsFilterByAdmin,
          title: 'فلترة التقارير حسب المدير',
          description: 'تصفية ومتابعة تقارير المبيعات حسب المدير الذي قام بقبول الطلب أو تعديل حالته',
          icon: Icons.person_search_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'sub_admins',
      title: '👥 المدراء وصلاحيات النظام',
      icon: Icons.admin_panel_settings_outlined,
      color: Colors.blueGrey,
      items: [
        AdminPermissionItem(
          key: subAdminsView,
          title: 'عرض قائمة المدراء المشرفين',
          description: 'مشاهدة أسماء حسابات المدراء الفرعيين ونشاطهم',
          icon: Icons.people_outline,
        ),
        AdminPermissionItem(
          key: subAdminsAdd,
          title: 'إضافة حساب مدير فرعي جديد',
          description: 'إنشاء يوزر جديد وتعيين اسم المستخدم وكلمة المرور',
          icon: Icons.person_add_alt_outlined,
        ),
        AdminPermissionItem(
          key: subAdminsEditPermissions,
          title: 'تعديل وتخصيص الصلاحيات 🔑',
          description: 'تحديد وتعديل الصلاحيات الممنوحة لكل مدير',
          icon: Icons.manage_accounts_outlined,
        ),
        AdminPermissionItem(
          key: subAdminsDelete,
          title: 'حذف وسحب حساب المدير',
          description: 'مسح حساب المشرف وإيقاف إمكانيته للدخول نهائياً',
          icon: Icons.person_remove_alt_1_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'payment_methods',
      title: '💳 طرق وحسابات الدفع',
      icon: Icons.credit_card_outlined,
      color: Colors.cyan,
      items: [
        AdminPermissionItem(
          key: paymentMethodsView,
          title: 'عرض طرق وحسابات الدفع',
          description: 'استعراض طرق الدفع المفعلة وأرقام الحسابات',
          icon: Icons.visibility_outlined,
        ),
        AdminPermissionItem(
          key: paymentMethodsAdd,
          title: 'إضافة طريقة دفع جديدة',
          description: 'إدراج طريقة دفع أو رقم محفظة/حساب بنكي جديد',
          icon: Icons.add_card_outlined,
        ),
        AdminPermissionItem(
          key: paymentMethodsEdit,
          title: 'تعديل وتفعيل طرق الدفع',
          description: 'تغيير الاسم ورقم الحساب ومفتاح التفعيل والتوقيف',
          icon: Icons.edit_note_outlined,
        ),
        AdminPermissionItem(
          key: paymentMethodsDelete,
          title: 'حذف طرق وسائط الدفع',
          description: 'إزالة وطرح وسيلة الدفع نهائياً من القائمة',
          icon: Icons.delete_outline,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'cities',
      title: '🏙️ إدارة المدن',
      icon: Icons.location_city_outlined,
      color: Colors.brown,
      items: [
        AdminPermissionItem(
          key: citiesView,
          title: 'عرض قائمة المدن المتاحة',
          description: 'استعراض أسماء المدن المخدومة في النظام',
          icon: Icons.location_city,
        ),
        AdminPermissionItem(
          key: citiesAdd,
          title: 'إضافة مدينة جديدة',
          description: 'إدراج مدينة جديدة لنطاق توصيل التطبيق',
          icon: Icons.add_location_outlined,
        ),
        AdminPermissionItem(
          key: citiesEdit,
          title: 'تعديل أسماء المدن',
          description: 'تعديل وتغيير اسم المدينة المسجلة',
          icon: Icons.edit_location_outlined,
        ),
        AdminPermissionItem(
          key: citiesDelete,
          title: 'حذف مدينة نهائياً',
          description: 'إزالة ومسح المدينة من قائمة المدن المفعلة',
          icon: Icons.wrong_location_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'stores',
      title: '🏪 إدارة المطاعم والمتاجر',
      icon: Icons.storefront_outlined,
      color: Colors.deepPurple,
      items: [
        AdminPermissionItem(
          key: storesView,
          title: 'عرض قائمة المطاعم والمتاجر',
          description: 'تصفح واستعراض المتاجر المسجلة في النظام',
          icon: Icons.store_outlined,
        ),
        AdminPermissionItem(
          key: storesAdd,
          title: 'إضافة مطعم/متجر جديد',
          description: 'إنشاء حساب وتفاصيل مطعم جديد ورفع شعاره',
          icon: Icons.add_business_outlined,
        ),
        AdminPermissionItem(
          key: storesEdit,
          title: 'تعديل بيانات المطاعم والمتاجر',
          description: 'تغيير الاسم، الوصف، العنوان، التلفون وصور الغلاف',
          icon: Icons.edit_note_outlined,
        ),
        AdminPermissionItem(
          key: storesLinkCategoriesCities,
          title: 'ربط المطاعم بالأقسام والمدن 🔗',
          description: 'تحديد وتعيين المدينة والقسم الذي ينتمي إليه المحل',
          icon: Icons.hub_outlined,
        ),
        AdminPermissionItem(
          key: storesToggleStatus,
          title: 'فتح وإغلاق المطاعم والمتاجر 🔴🟢',
          description: 'التبديل الفوري لاستقبال أو إيقاف الطلبات لكل مطعم',
          icon: Icons.power_settings_new_outlined,
        ),
        AdminPermissionItem(
          key: storesDelete,
          title: 'حذف مطعم/متجر نهائياً',
          description: 'إزالة المحل وجميع بيانتة من النظام',
          icon: Icons.delete_forever_outlined,
        ),
      ],
    ),

    AdminPermissionGroup(
      id: 'store_categories',
      title: '🏷️ إدارة أقسام المحلات والتصنيفات',
      icon: Icons.category_outlined,
      color: Colors.pink,
      items: [
        AdminPermissionItem(
          key: storeCategoriesView,
          title: 'عرض أقسام المحلات',
          description: 'استعراض أقسام وتصنيفات المحلات والمطاعم',
          icon: Icons.grid_view_outlined,
        ),
        AdminPermissionItem(
          key: storeCategoriesAdd,
          title: 'إضافة قسم محلات جديد',
          description: 'إنشاء قسم جديد مثل (مطاعم، كفتيريا، سوبرماركت...)',
          icon: Icons.library_add_outlined,
        ),
        AdminPermissionItem(
          key: storeCategoriesEdit,
          title: 'تعديل أقسام المحلات',
          description: 'تغيير اسم وأيقونة قسم المحلات',
          icon: Icons.edit_note_outlined,
        ),
        AdminPermissionItem(
          key: storeCategoriesDelete,
          title: 'حذف قسم المحلات',
          description: 'إزالة وشطب قسم المحلات نهائياً',
          icon: Icons.delete_outline,
        ),
      ],
    ),
  ];

  /// Backward compatibility mapper: maps old legacy string permissions to new micro-permissions
  static List<String> normalizePermissions(List<String> rawPermissions) {
    final Set<String> normalized = {};

    for (final perm in rawPermissions) {
      if (perm == 'manage_products') {
        normalized.addAll([
          productsView,
          productsAdd,
          productsEdit,
          productsToggleAvailability,
          productsDelete,
          categoriesView,
          categoriesAdd,
          categoriesEdit,
          categoriesDelete,
          adsView,
          adsAdd,
          adsEdit,
          adsDelete,
        ]);
      } else if (perm == 'manage_orders') {
        normalized.addAll([
          ordersView,
          ordersViewDetails,
          ordersPrintReceipt,
          ordersAcceptPrepare,
          ordersSendDelivery,
          ordersMarkCompleted,
          ordersCancel,
          ordersDelete,
          deliveryZonesView,
          deliveryZonesAdd,
          deliveryZonesEdit,
          deliveryZonesToggle,
          deliveryZonesDelete,
          storeStatusView,
          storeStatusToggle,
          storeClosedReasonEdit,
        ]);
      } else if (perm == 'view_reports') {
        normalized.addAll([
          reportsViewSummary,
          reportsViewFinancial,
          reportsExportPdf,
        ]);
      } else if (perm == 'manage_admins') {
        normalized.addAll([
          subAdminsView,
          subAdminsAdd,
          subAdminsEditPermissions,
          subAdminsDelete,
        ]);
      } else {
        // Already a micro-permission
        normalized.add(perm);
      }
    }

    return normalized.toList();
  }
}
