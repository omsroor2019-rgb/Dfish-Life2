# إعداد Firebase لتطبيق DFISH LIVE

هذا المشروع يستخدم Firebase فقط لمزامنة المباريات وروابط البث ولوحة الإدارة. لا توجد حاجة إلى Cloudflare أو Cloudflare Worker أو D1 أو KV.

## 1) إنشاء مشروع Firebase

1. افتح https://console.firebase.google.com/ وأنشئ مشروعاً باسم `DFISH LIVE`.
2. من Project settings > General أضف تطبيق Android.
3. استخدم معرف الحزمة التالي تماماً:
   `com.dfish.live.dfish_live`
4. حمّل `google-services.json` مؤقتاً من إعدادات تطبيق Android لقراءة القيم المطلوبة، لكن لا ترفعه إلى GitHub ولا تضع ملف Service Account في التطبيق. انسخ القيم المقابلة من الملف أو من إعداد SDK:
   - API Key الخاص بتطبيق Android (قيمة `apiKey`)
   - App ID (قيمة `appId`)
   - Messaging Sender ID
   - Project ID
   - Storage bucket (اختياري)
5. افتح `lib/firebase_options.dart` واستبدل القيم النائبة بالقيم الحقيقية. لا يحتاج هذا المشروع إلى وضع `google-services.json` في مجلد التطبيق لأن إعداد Firebase يتم عبر `FirebaseOptions` داخل Dart.

هذه قيم تعريف تطبيق Firebase وليست مفتاح Service Account. لا تضع مفتاح Service Account أو ملف مفتاح خاص داخل تطبيق Android.

## 2) تفعيل تسجيل دخول المدير

1. من Firebase Console افتح Authentication.
2. افتح Sign-in method ثم فعّل Email/Password.
3. من Users أضف مستخدماً جديداً بالبريد التالي:
   `admin@dfish.live`
4. عيّن كلمة مرور قوية لا تقل عن 16 حرفاً واحتفظ بها خارج ملفات المشروع.
5. انسخ UID الخاص بالمستخدم بعد إنشائه.

لوحة الإدارة لا تحتوي على إنشاء حساب عام. حساب المدير يُنشأ من Firebase Console فقط. في التطبيق يضغط المدير على رقم الإصدار 10 مرات ثم يدخل كلمة المرور.

## 3) إنشاء قاعدة Firestore وتأمينها

1. افتح Firestore Database وأنشئ قاعدة بيانات في Production mode.
2. افتح تبويب Rules.
3. انسخ محتوى الملف `firestore.rules` كاملاً وانشر القواعد.
4. من تبويب Data أنشئ مجموعة باسم `admin_users`.
5. أنشئ مستنداً يكون معرّفه UID الذي نسخته من Authentication.
6. أضف الحقول:
   - `enabled` من النوع Boolean وقيمته `true`

لا تسمح بإنشاء مستندات `admin_users` من التطبيق. أضف المديرين يدوياً من Firebase Console فقط. قواعد Firestore تمنع المستخدمين العاديين من إنشاء أو تعديل أو حذف المباريات.

## 4) إضافة مفتاح API-Football

1. افتح لوحة حسابك في https://dashboard.api-football.com/ وأنشئ مفتاحاً جديداً.
2. افتح مستودع GitHub ثم Settings > Secrets and variables > Actions.
3. اختر New repository secret وأنشئ سراً بالاسم `API_FOOTBALL_KEY`.
4. ألصق المفتاح الجديد في قيمة السر واحفظه؛ لا تضعه في ملفات Dart أو في المستودع.
5. لا تستخدم المفتاح الذي سبق إرساله في محادثة أو نشره في مكان عام؛ ألغِه وأنشئ مفتاحاً جديداً.

مهم: هذا التطبيق يتصل مباشرةً بـ API-Football كما طلب مالك المشروع. لذلك يصبح مفتاح API قابلاً للاستخراج من APK، وتُستهلك حصة الحساب نفسها من جميع المستخدمين. راقب الحصة وحدود الاشتراك في لوحة API-Football. لا يمكن ضمان عمل الخدمة بنسبة 100% عند انقطاع الإنترنت أو تجاوز الحصة أو رفض المزود للطلب.

## 5) تشغيل وفحص التطبيق

من مجلد المشروع:

```bash
flutter pub get
flutter analyze
flutter run --dart-define=API_FOOTBALL_KEY=YOUR_NEW_KEY
```
استبدل `YOUR_NEW_KEY` محلياً بمفتاحك الجديد، ولا تضعه في ملف أو مستودع عام.

من لوحة الإدارة يوجد زر `فحص الاتصال` الذي يرسل طلباً إلى مسار `status` في API-Football. نجاح الاختبار يعني أن المفتاح مقبول وقت الاختبار، ولا يضمن توفر كل بطولة أو إحصائية في خطة الاشتراك.

## 6) بناء APK من GitHub Actions

1. ارفع محتويات المشروع إلى مستودع GitHub.
2. تأكد من أن إعدادات `lib/firebase_options.dart` تخص مشروع `dfish-live`.
3. أضف GitHub Secret باسم `API_FOOTBALL_KEY` قبل تشغيل البناء.
4. افتح Actions.
5. اختر `Build DFISH LIVE APK` ثم `Run workflow`.
6. بعد نجاح البناء افتح نتيجة التشغيل وحمّل Artifact باسم `DFISH-LIVE-Android-APK`.

لا توجد إعدادات خادم إضافية مطلوبة في GitHub لهذا الاتصال المباشر.

## 7) هيكل بيانات البث

تُخزن كل مباراة في مجموعة `matches` بالحقول الأساسية:

- `home`, `away`, `league`
- `date` بصيغة `YYYY-MM-DD`
- `time` بصيغة `HH:MM` بتوقيت اليمن
- `homeLogo`, `awayLogo`, `leagueLogo`
- `commentator`, `channel`
- `enabled` لإظهار المباراة أو إخفائها
- `sources`: قائمة حتى أربعة مصادر، وكل مصدر يحتوي `name`, `url`, `enabled`
- `createdAt`, `updatedAt`

التطبيق يستمع إلى تغييرات Firestore مباشرةً؛ لذلك تظهر عمليات النشر والتعديل والحذف على أجهزة المستخدمين دون إعادة بناء APK. يجب إضافة الروابط التي تملك حق استخدامها فقط.

## استكشاف الأخطاء

- `permission-denied`: تحقق من نشر `firestore.rules` ومن وجود مستند `admin_users/{UID}` مع `enabled: true`.
- `FirebaseApp not initialized`: تأكد من تعبئة قيم `lib/firebase_options.dart` ثم أعد البناء.
- `API key rejected`: أنشئ مفتاح API-Football جديداً وتحقق من حالة الاشتراك.
- `429`: تجاوز حد الطلبات؛ راجع لوحة API-Football وخفّض التحديث اليدوي.
