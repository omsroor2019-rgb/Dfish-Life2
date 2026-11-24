# DFISH LIVE

تطبيق كرة قدم عربي مبني باستخدام Flutter لأجهزة Android.

## المزايا

- مباريات اليوم والمباريات المباشرة والنتائج من API-Football.
- تفاصيل المباريات والإحصائيات والبطولات والترتيب والهدافون وصناع الأهداف.
- البحث عن اللاعبين والأندية.
- مشغل بث لمصادر البث المرخصة وروابط HLS وMP4 وصفحات HTTPS المناسبة.
- لوحة إدارة مخفية تفتح بعد الضغط على رقم الإصدار 10 مرات.
- إضافة المباريات وتعديلها وحذفها وإدارة حتى أربعة مصادر بث لكل مباراة.
- مزامنة مباشرة لجميع المستخدمين عبر Firebase Authentication وCloud Firestore.
- واجهة عربية RTL وألوان داكنة مع لمسات زمردية.

## الإعداد قبل البناء

1. أضف مفتاح API-Football جديداً في `lib/config/api_config.dart`.
2. أكمل قيم تطبيق Firebase Android في `lib/firebase_options.dart`.
3. أنشئ حساب المدير وقواعد Firestore كما هو موضح في `docs/FIREBASE_SETUP_AR.md`.
4. شغّل `flutter pub get` ثم `flutter run`.

## بناء APK

```bash
flutter pub get
dart run tool/verify_config.dart
flutter build apk --release
```

أو ارفع التغييرات إلى الفرع `main` في GitHub ثم شغّل Workflow باسم `Build DFISH LIVE APK`. لن يبدأ GitHub Actions البناء إذا كانت إعدادات Firebase أو API-Football ما زالت placeholders.

## الخدمات المستخدمة

- API-Football: مصدر بيانات المباريات والبطولات والإحصائيات. المفتاح مضمّن في التطبيق وفق طلب مالك المشروع ويمكن استخراجه من APK؛ استخدم مفتاحاً مخصصاً وراقب الحصة.
- Firebase Authentication: تسجيل دخول المدير.
- Cloud Firestore: مزامنة المباريات وروابط البث بين جميع الأجهزة.

لا يستخدم المشروع Cloudflare أو Worker أو D1 أو KV.

## الحقوق

تطوير عبد العزيز عوض بن ثابت. جميع الحقوق محفوظة © DFISH LIVE.
