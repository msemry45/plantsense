import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plantsense/services/locale_service.dart';

/// Comprehensive type-safe localizations for PlantSense SVPG.
/// Supports Arabic ('ar') as default and English ('en').
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(LocaleService.localeNotifier.value);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  // ===========================================================================
  // Common & Navigation
  // ===========================================================================
  String get appTitle => 'SVPG';
  String get appSubtitle => isArabic
      ? 'نظام مراقبة نمو النباتات الرأسية الذكي'
      : 'Smart Vertical Plant Growth Monitoring';
  String get back => isArabic ? 'رجوع' : 'Back';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get saving => isArabic ? 'جاري الحفظ...' : 'Saving...';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get deleting => isArabic ? 'جاري الحذف...' : 'Deleting...';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get refresh => isArabic ? 'تحديث' : 'Refresh';
  String get search => isArabic ? 'بحث' : 'Search';
  String get done => isArabic ? 'تم' : 'Done';
  String get close => isArabic ? 'إغلاق' : 'Close';
  String get loading => isArabic ? 'جاري التحميل...' : 'Loading...';
  String get error => isArabic ? 'خطأ' : 'Error';
  String get success => isArabic ? 'نجاح' : 'Success';
  String get languageToggle => isArabic ? 'English' : 'عربي';

  // ===========================================================================
  // Authentication & Profile
  // ===========================================================================
  String get login => isArabic ? 'تسجيل الدخول' : 'Sign In';
  String get register => isArabic ? 'إنشاء حساب جديد' : 'Create Account';
  String get forgotPassword => isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get resetPassword => isArabic ? 'استعادة كلمة المرور' : 'Reset Password';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get username => isArabic ? 'اسم المستخدم' : 'Username';
  String get fullName => isArabic ? 'الاسم الكامل' : 'Full Name';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Log Out';
  String get signOut => isArabic ? 'تسجيل الخروج' : 'Sign out';
  String get logoutConfirmTitle => isArabic ? 'تأكيد تسجيل الخروج' : 'Confirm Logout';
  String get logoutConfirmContent => isArabic ? 'هل تريد تسجيل الخروج من حسابك؟' : 'Are you sure you want to log out?';
  String get continueAsGuest => isArabic ? 'المتابعة كزائر' : 'Continue as Guest';
  String get welcomeBack => isArabic ? 'أهلاً بك مجدداً في SVPG' : 'Welcome back to SVPG';
  String get createNewAccountHeader => isArabic ? 'انضم إلى نظام المراقبة الزراعية الذكي' : 'Join the Smart Plant Monitoring System';
  String get resetPasswordInstruction => isArabic
      ? 'أدخل بريدك الإلكتروني لتلقي رابط إعادة تعيين كلمة المرور.'
      : 'Enter your email to receive a password reset link.';
  String get sendResetLink => isArabic ? 'إرسال رابط الاستعادة' : 'Send Reset Link';
  String get resetLinkSentConfirmation => isArabic
      ? 'إذا كان هذا الحساب مسجلاً، فقد تم إرسال رابط الاستعادة إلى بريدك.'
      : 'If this account is registered, a password reset link has been sent.';

  // Validation
  String get emailRequired => isArabic ? 'البريد الإلكتروني مطلوب' : 'Email is required';
  String get invalidEmail => isArabic ? 'يرجى إدخال بريد إلكتروني صحيح' : 'Please enter a valid email';
  String get passwordRequired => isArabic ? 'كلمة المرور مطلوبة' : 'Password is required';
  String get passwordTooShort => isArabic ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : 'Password must be at least 6 characters';
  String get usernameRequired => isArabic ? 'اسم المستخدم مطلوب' : 'Username is required';
  String get usernameInvalid => isArabic
      ? 'اسم المستخدم يجب أن يحتوي أحرفاً وأرقاماً إنجليزية وشرطة سفلية فقط (3-30 حرف)'
      : 'Username must contain alphanumeric characters or underscores (3-30 chars)';
  String get fullNameRequired => isArabic ? 'الاسم الكامل مطلوب' : 'Full Name is required';

  // ===========================================================================
  // Dashboard & Roles
  // ===========================================================================
  String get dashboard => isArabic ? 'لوحة التحكم' : 'Dashboard';
  String get roleFarmer => isArabic ? 'مزارع' : 'Farmer';
  String get roleAdmin => isArabic ? 'مدير النظام' : 'Administrator';
  String get roleViewer => isArabic ? 'مشاهد' : 'Viewer';
  String get roleGuest => isArabic ? 'زائر' : 'Guest';
  String get activeStatus => isArabic ? 'نشط' : 'Active';
  String get suspendedStatus => isArabic ? 'معلّق' : 'Suspended';
  String get accountSuspendedNotice => isArabic
      ? 'تم تعليق هذا الحساب بواسطة إدارة النظام.'
      : 'This account has been suspended by system administration.';

  // Actions
  String get myPlantsAction => isArabic ? 'نباتاتي' : 'My Plants';
  String get myPlantsSubtitle => isArabic ? 'إدارة ومتابعة النباتات والنمو' : 'Manage and monitor your plants';
  String get viewPlantsAction => isArabic ? 'استعراض النباتات' : 'View Plants';
  String get viewPlantsSubtitle => isArabic ? 'الاطلاع على النباتات المصرح لك بمشاهدتها' : 'Inspect plants shared with you';
  String get adminUsersAction => isArabic ? 'إدارة المستخدمين' : 'Manage Users';
  String get adminUsersSubtitle => isArabic ? 'التحكم بالصلاحيات وتفعيل أو تعليق الحسابات' : 'Manage user roles and account statuses';
  String get careTasksAction => isArabic ? 'مهام العناية' : 'Care Tasks';
  String get careTasksSubtitle => isArabic ? 'جدول ومتابعة الري والتسميد والإضاءة' : 'Watering, lighting, and fertilizing schedule';
  String get aiDiagnosisAction => isArabic ? 'تحليل الأوراق بالذكاء الاصطناعي' : 'AI Leaf Condition Analysis';
  String get aiDiagnosisSubtitle => isArabic ? 'فحص صحة الأوراق والكشف البصري عن الإجهاد' : 'Visual leaf stress and condition inspection';
  String get analyticsAction => isArabic ? 'التقارير والإحصائيات' : 'Analytics & Reports';
  String get analyticsSubtitle => isArabic ? 'مؤشرات الأداء والنمو الحقلي' : 'Performance metrics and growth insights';

  // ===========================================================================
  // Plants List
  // ===========================================================================
  String get plantsListTitle => isArabic ? 'قائمة النباتات' : 'Plants List';
  String get myPlantsHeading => isArabic ? 'نباتاتي الزراعية' : 'My Monitored Plants';
  String get searchPlantsHint => isArabic ? 'ابحث باسم النبات أو موقعه...' : 'Search by plant name or location...';
  String get noPlantsFound => isArabic ? 'لم يتم العثور على نباتات مطابقة' : 'No matching plants found';
  String get noPlantsRecordedYet => isArabic ? 'لا توجد نباتات مسجلة بعد' : 'No plants recorded yet';
  String get addFirstPlantPrompt => isArabic
      ? 'ابدأ بإضافة أول نبتة لمتابعة نموها وتوثيق حالتها بالصور والملاحظات.'
      : 'Start by adding your first plant to track growth, photos, and observation notes.';
  String get addNewPlant => isArabic ? 'إضافة نبات جديد' : 'Add New Plant';
  String daysOld(int days) => isArabic ? '$days يوم' : '${days}d old';

  // ===========================================================================
  // Plant Form (Add / Edit)
  // ===========================================================================
  String get plantFormAddTitle => isArabic ? 'إضافة نبات جديد' : 'Add New Plant';
  String get plantFormEditTitle => isArabic ? 'تعديل بيانات النبات' : 'Edit Plant';
  String get plantNameLabel => isArabic ? 'اسم النبات *' : 'Plant Name *';
  String get plantNameHint => isArabic ? 'مثال: طماطم البرج الرأسي 1' : 'e.g. Hydroponic Tower Tomato 1';
  String get speciesLabel => isArabic ? 'النوع الزراعي *' : 'Plant Species *';
  String get selectSpeciesHint => isArabic ? 'اختر النوع من الموسوعة' : 'Select species from encyclopedia';
  String get locationLabel => isArabic ? 'الموقع الحقلي' : 'Setup Location';
  String get locationHint => isArabic ? 'مثال: البيت المحمي - رف أ2' : 'e.g. Greenhouse Rack A-2';
  String get plantedDateLabel => isArabic ? 'تاريخ الزراعة' : 'Planted On';
  String get notesLabel => isArabic ? 'ملاحظات أولية' : 'Initial Notes';
  String get notesHint => isArabic ? 'تفاصيل وسط الزراعة، مصدر الشتلة، إلخ...' : 'Details about growing medium, seedling source, etc...';
  String get savePlantButton => isArabic ? 'حفظ النبات' : 'Save Plant';
  String get plantSavedSuccess => isArabic ? 'تم حفظ بيانات النبات بنجاح.' : 'Plant saved successfully.';
  String get plantUpdatedSuccess => isArabic ? 'تم تحديث بيانات النبات بنجاح.' : 'Plant updated successfully.';

  // ===========================================================================
  // Plant Details
  // ===========================================================================
  String get plantDetailsTitle => isArabic ? 'تفاصيل النبات' : 'Plant Details';
  String get noPhotoUploadedYet => isArabic ? 'لم تُرفع صورة بعد' : 'No photo uploaded yet';
  String get plantAgeLabel => isArabic ? 'عمر النبتة' : 'Plant Age';
  String get notSpecified => isArabic ? 'غير محدد' : 'Not specified';
  String get unknown => isArabic ? 'غير معروف' : 'Unknown';
  String get addPhoto => isArabic ? 'إضافة صورة' : 'Add Photo';
  String photoHistoryWithCount(int count) => isArabic ? 'سجل الصور ($count)' : 'History ($count)';
  String get speciesCareGuidelines => isArabic ? 'إرشادات العناية بالنوع' : 'Species Care Guidelines';
  String get idealTemperature => isArabic ? 'الحرارة المثالية' : 'Ideal Temperature';
  String get idealHumidity => isArabic ? 'الرطوبة المثالية' : 'Ideal Humidity';
  String get lightConditions => isArabic ? 'الإضاءة المطلوبة' : 'Light Conditions';
  String get generalCareAdvice => isArabic ? 'نصائح العناية العامة' : 'General Care Tips';
  String growthPhotosSection(int count) => isArabic ? 'صور النمو ($count)' : 'Growth Photos ($count)';
  String get viewAll => isArabic ? 'عرض الكل' : 'View All';
  String observationNotesSection(int count) => isArabic ? 'الملاحظات الحقلية ($count)' : 'Observation Notes ($count)';
  String get viewAllOrAdd => isArabic ? 'عرض الكل / إضافة' : 'View All / Add';
  String get noNotesRecorded => isArabic ? 'لا توجد ملاحظات مسجلة' : 'No notes recorded';
  String get recordGrowthNotesAdvice => isArabic
      ? 'سجل ملاحظات دورية حول صحة النبتة أو تعديلات الري والتسميد.'
      : 'Record regular growth observations or care changes.';
  // ===========================================================================
  // AI Plant Leaf Condition Analysis (Milestone 4)
  // ===========================================================================
  String get aiDiagnosisNoticeTitle => isArabic ? 'فحص حالة الأوراق بالذكاء الاصطناعي' : 'AI Leaf Condition Analysis';
  String get aiDiagnosisNoticeBody => isArabic
      ? 'فحص بصري متعدد الوسائط لتقييم صحة الأوراق وعلامات الإجهاد الظاهرة.'
      : 'Multimodal visual analysis assessing leaf health and visible stress indicators.';
  String get analyzeLeafAction => isArabic ? 'فحص حالة الورقة' : 'Analyze Leaf Condition';
  String get analyzeLatestPhotoAction => isArabic ? 'فحص أحدث صورة بالذكاء الاصطناعي' : 'Analyze Latest Photo with AI';
  String get analyzingLeafProgress => isArabic
      ? 'جاري فحص حالة الورقة وتحليل المؤشرات البصرية...'
      : 'Analyzing leaf condition and visual indicators...';
  String get analyzingLeafWait => isArabic
      ? 'يتم الاتصال بنموذج الذكاء الاصطناعي لفحص الصورة، يرجى الانتظار...'
      : 'Connecting to multimodal AI model, please wait...';
  String get analysisResultTitle => isArabic ? 'نتيجة الفحص البصري' : 'Visual Analysis Result';
  String get healthStatusLabel => isArabic ? 'الحالة العامة' : 'Health Status';
  String get statusHealthy => isArabic ? 'سليم' : 'Healthy';
  String get statusAttentionNeeded => isArabic ? 'يحتاج عناية' : 'Attention Needed';
  String get statusUncertain => isArabic ? 'غير مؤكد' : 'Uncertain';
  String get severityLabel => isArabic ? 'مستوى الشدة' : 'Severity Level';
  String get severityNone => isArabic ? 'لا توجد أعراض' : 'None';
  String get severityLow => isArabic ? 'منخفض' : 'Low';
  String get severityMedium => isArabic ? 'متوسط' : 'Medium';
  String get severityHigh => isArabic ? 'مرتفع' : 'High';
  String get severityUnknown => isArabic ? 'غير محدد' : 'Uncertain';
  String get visibleSignsLabel => isArabic ? 'العلامات البصرية الملاحظة' : 'Observed Visual Signs';
  String get noVisibleSignsFound => isArabic ? 'لم تُرصد علامات إجهاد واضحة' : 'No obvious stress signs observed';
  String get confidenceNoteLabel => isArabic ? 'ملاحظة الفحص' : 'Analysis Note';
  String get recommendationsLabel => isArabic ? 'إرشادات العناية الأولية' : 'Initial Care Recommendations';
  String get noRecommendations => isArabic ? 'لا توجد إرشادات إضافية مطلوبة حالياً.' : 'No additional recommendations needed at this time.';
  String get disclaimerLabel => isArabic ? 'تنويه استرشادي' : 'Advisory Disclaimer';
  String get disclaimerDefault => isArabic
      ? 'هذا التقييم استرشادي مبني على الصورة فقط ولا يُعد تشخيصاً زراعياً نهائياً.'
      : 'This assessment is advisory based on image only and does not replace confirmed agricultural diagnosis.';
  String get viewFullReportAction => isArabic ? 'عرض التقرير الكامل' : 'View Full Report';
  String get reanalyzeAction => isArabic ? 'إعادة الفحص' : 'Re-analyze';
  String get viewHistoryAction => isArabic ? 'سجل الفحوصات' : 'Analysis History';
  String get aiAnalysisHistoryTitle => isArabic ? 'سجل فحوصات الذكاء الاصطناعي' : 'AI Analysis History';
  String get noAnalysesRecordedYet => isArabic ? 'لم يتم إجراء فحص بالذكاء الاصطناعي لهذه النبتة بعد.' : 'No AI leaf analyses recorded for this plant yet.';
  String get startFirstAnalysisPrompt => isArabic
      ? 'التقط صورة لورقة النبات لبدء الفحص البصري بالذكاء الاصطناعي.'
      : 'Take or select a leaf photo to start AI visual analysis.';
  String get latestAnalysisBadge => isArabic ? 'آخر فحص' : 'Latest Analysis';
  String get cachedDiagnosisNotice => isArabic ? 'تم جلب نتيجة سابقة محفوظة لهذه الصورة.' : 'Retrieved cached diagnosis for this photo.';
  String get photoRequiredForAIAnalysis => isArabic ? 'يرجى رفع صورة أولاً لإجراء الفحص بالذكاء الاصطناعي.' : 'Please upload a photo first to run AI leaf analysis.';
  String get aiAnalysisFailedMessage => isArabic ? 'تعذر إتمام الفحص البصري حالياً، يرجى المحاولة لاحقاً.' : 'Unable to complete visual analysis at this time. Please try again later.';
  String get analyzeNowCheckboxPrompt => isArabic ? 'فحص الورقة بالذكاء الاصطناعي فور حفظ الصورة' : 'Analyze leaf condition with AI immediately after upload';
  String get deletePlantTitle => isArabic ? 'حذف النبات' : 'Delete Plant';
  String deletePlantContent(String name) => isArabic
      ? 'هل أنت متأكد من حذف "$name"؟ سيتم حذف جميع الصور المسجلة في التخزين الخاص والملاحظات المرتبطة به نهائياً.'
      : 'Are you sure you want to delete "$name"? All associated growth photos in private storage and notes will be permanently removed.';
  String get plantDeletedSuccess => isArabic ? 'تم حذف النبات وجميع ملفاته بنجاح.' : 'Plant and all associated files deleted successfully.';

  // ===========================================================================
  // Image Capture & Preview
  // ===========================================================================
  String addPhotoForPlantTitle(String name) => isArabic ? 'إضافة صورة — $name' : 'Add Photo — $name';
  String get selectGrowthPhotoPrompt => isArabic ? 'اختر صورة لتوثيق نمو هذه النبتة' : 'Select a growth photo for this plant';
  String get maxFileSizeNotice => isArabic ? 'الحد الأقصى 10 ميغابايت • صيغ JPEG, PNG, WebP, HEIC' : 'Max 10 MB • JPEG, PNG, WebP, HEIC';
  String get cameraSource => isArabic ? 'الكاميرا' : 'Camera';
  String get gallerySource => isArabic ? 'المعرض' : 'Gallery';
  String get confirmAndUploadButton => isArabic ? 'تأكيد الرفع إلى التخزين الخاص' : 'Confirm & Upload to Private Storage';
  String get photoUploadedSuccess => isArabic ? 'تم رفع الصورة إلى التخزين الخاص بنجاح.' : 'Photo uploaded to private storage successfully.';
  String get emptyFileError => isArabic ? 'الملف المحدد فارغ.' : 'Selected image file is empty.';
  String sizeLimitError(String sizeMb) => isArabic
      ? 'حجم الصورة ($sizeMb ميغابايت) يتجاوز الحد المسموح به (10 ميغابايت).'
      : 'Image size ($sizeMb MB) exceeds the maximum allowed 10 MB limit.';
  String invalidFormatError(String format) => isArabic
      ? 'صيغة الصورة غير مدعومة ($format). الصيغ المسموحة: JPEG, PNG, WebP, HEIC.'
      : 'Unsupported image format ($format). Allowed: JPEG, PNG, WebP, HEIC.';

  // ===========================================================================
  // Photo Timeline & Compare
  // ===========================================================================
  String photoHistoryTitle(String name) => isArabic ? '$name — سجل الصور' : '$name — Photo History';
  String get compareMode => isArabic ? 'مقارنة' : 'Compare';
  String get exitCompareMode => isArabic ? 'إنهاء' : 'Done';
  String get selectTwoPhotosForCompare => isArabic
      ? 'تم تحديد صورتين! اضغط "مقارنة الصورتين" بالأسفل.'
      : '2 photos selected! Tap "Compare Selected" below.';
  String get compareSelectedButton => isArabic ? 'مقارنة الصورتين المحددتين (2)' : 'Compare Selected (2)';
  String get exactlyTwoPhotosWarning => isArabic
      ? 'يمكنك مقارنة صورتين اثنتين فقط في المرة الواحدة.'
      : 'You can compare exactly 2 photos at a time.';
  String get deletePhotoTitle => isArabic ? 'حذف الصورة' : 'Delete Photo';
  String get deletePhotoConfirm => isArabic
      ? 'هل أنت متأكد من حذف هذه الصورة؟ سيتم حذفها نهائياً من التخزين الخاص وقاعدة البيانات.'
      : 'Are you sure you want to delete this photo? It will be permanently removed from private storage and database.';
  String get photoDeletedSuccess => isArabic ? 'تم حذف الصورة بنجاح من التخزين وقاعدة البيانات.' : 'Photo deleted successfully from storage and database.';
  String comparePhotosTitle(String name) => isArabic ? 'مقارنة الصور — $name' : 'Compare Photos — $name';
  String daysGrowthInterval(int days) => isArabic ? 'فارق نمو $days يوم' : '$days days growth interval';
  String get compareDescription => isArabic
      ? 'مقارنة بصرية لتطور نمو الأوراق والمجموع الخضري بين الصورتين.'
      : 'Visual comparison of plant growth and foliage progression.';
  String get earlierPhoto => isArabic ? 'الصورة السابقة (الأقدم)' : 'Earlier Photo';
  String get laterPhoto => isArabic ? 'الصورة اللاحقة (الأحدث)' : 'Later Photo';
  String daysLater(int days) => isArabic ? 'بعد $days يوم' : '$days Days Later';

  // ===========================================================================
  // Observation Notes
  // ===========================================================================
  String notesTitle(String name) => isArabic ? '$name — الملاحظات الحقلية' : '$name — Notes';
  String get noObservationNotesYet => isArabic ? 'لا توجد ملاحظات حقلية بعد' : 'No observation notes yet';
  String get notesDescription => isArabic
      ? 'سجل ملاحظات مؤرخة حول نشاط النمو، تعديل المحلول المغذي، فحص الآفات، أو ضبط الإضاءة.'
      : 'Keep dated notes on plant vigor, fertilizer changes, pest checks, or environmental tweaks.';
  String get recordFirstNote => isArabic ? 'تسجيل أول ملاحظة' : 'Record First Note';
  String get addObservationNoteDialogTitle => isArabic ? 'إضافة ملاحظة حقلية' : 'Add Observation Note';
  String get editObservationNoteDialogTitle => isArabic ? 'تعديل الملاحظة الحقلية' : 'Edit Observation Note';
  String get noteHint => isArabic
      ? 'اكتب ملاحظاتك (مثال: ظهور نموات ورقية جديدة، اصفرار خفيف على الحواف، تعديل الري)...'
      : 'Record observations (e.g. new leaf shoot, yellowing tip, watering adjustment)...';
  String get noteDatePrefix => isArabic ? 'التاريخ:' : 'Date:';
  String get deleteNoteTitle => isArabic ? 'حذف الملاحظة' : 'Delete Note';
  String get deleteNoteConfirm => isArabic ? 'هل أنت متأكد من حذف هذه الملاحظة الحقلية؟' : 'Are you sure you want to delete this observation note?';
  String get noteDeletedSuccess => isArabic ? 'تم حذف الملاحظة بنجاح.' : 'Observation note deleted successfully.';
  String get noteSavedSuccess => isArabic ? 'تم حفظ الملاحظة بنجاح.' : 'Observation note saved successfully.';
  String get noteUpdatedSuccess => isArabic ? 'تم تحديث الملاحظة بنجاح.' : 'Observation note updated successfully.';

  // ===========================================================================
  // Permissions & Isolation
  // ===========================================================================
  String get viewerReadOnlyNotice => isArabic
      ? 'حسابك بصفة مشاهد (Viewer): لديك صلاحية المشاهدة فقط دون التعديل أو الحذف.'
      : 'You are signed in as a Viewer with read-only permissions.';
  String get permissionDenied => isArabic
      ? 'ليس لديك صلاحية لتنفيذ هذا الإجراء.'
      : 'You do not have permission to perform this action.';

  // ===========================================================================
  // Splash & Account Verification
  // ===========================================================================
  String get verifyingAccount => isArabic ? 'جاري التحقق من الحساب...' : 'Verifying account...';
  String get unableToVerifyAccount => isArabic ? 'تعذر التحقق من الحساب' : 'Unable to verify your account';

  // ===========================================================================
  // Admin Users Screen
  // ===========================================================================
  String get manageUsersTitle => isArabic ? 'إدارة المستخدمين' : 'Manage Users';
  String get rolePrefix => isArabic ? 'الدور: ' : 'Role: ';
  String get statusPrefix => isArabic ? 'الحالة: ' : 'Status: ';
  String get failedToLoadUsers => isArabic ? 'فشل تحميل بيانات المستخدمين' : 'Failed to load users';
  String get failedToUpdateStatus => isArabic ? 'فشل تحديث حالة المستخدم' : 'Failed to update status';
  String get failedToUpdateRole => isArabic ? 'فشل تحديث دور المستخدم' : 'Failed to update role';

  // ===========================================================================
  // Additional Screen Labels
  // ===========================================================================
  String get plantNotFound => isArabic ? 'لم يتم العثور على النبتة المطلوبة' : 'Plant not found';
  String get takeFirstPhoto => isArabic ? 'التقاط أول صورة' : 'Take First Photo';
  String get sizePrefix => isArabic ? 'الحجم: ' : 'Size: ';
  String get sourcePrefix => isArabic ? 'المصدر: ' : 'Source: ';
  String get uploadingPhoto => isArabic ? 'جاري رفع الصورة...' : 'Uploading...';
  String selectPhotosToCompare(int count) => isArabic
      ? 'حدد صورتين اثنتين للمقارنة ($count/2 محددة)'
      : 'Select exactly 2 photos to compare ($count/2 selected)';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

