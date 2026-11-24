# ملاحظات تكامل API-Football

- المضيف: `https://v3.football.api-sports.io/`
- طريقة المصادقة: ترويسة `x-apisports-key`.
- المنطقة الزمنية: `Asia/Aden` (اليمن UTC+3).
- مباريات يوم محدد: `/fixtures?date=YYYY-MM-DD&timezone=Asia/Aden`.
- المباريات المباشرة: `/fixtures?live=all&timezone=Asia/Aden`.
- أحداث المباراة: `/fixtures/events?fixture={fixture_id}`.
- التشكيلات: `/fixtures/lineups?fixture={fixture_id}`.
- إحصائيات المباراة: `/fixtures/statistics?fixture={fixture_id}`.
- ترتيب الدوري: `/standings?league={league_id}&season={year}`.
- الهدافون: `/players/topscorers?league={league_id}&season={year}`.
- صناع الأهداف: `/players/topassists?league={league_id}&season={year}`.
- معلومات اللاعب: `/players?id={player_id}&season={year}`.
- معلومات النادي ولاعبيه: `/teams?id={team_id}` و`/players?team={team_id}&season={year}`.
- انتقالات اللاعب: `/transfers?player={player_id}`.
- الدوريات: `/leagues?current=true`.
- فحص صلاحية الاتصال: `/status`.

## مكان المفتاح

يُضبط المفتاح في `lib/config/api_config.dart` بناءً على طلب مالك المشروع. هذا يعني أن المفتاح موجود في التطبيق ويمكن استخراجه من ملف APK. استخدم مفتاحاً مخصصاً للتطبيق، وراقب الحصة، وألغ أي مفتاح سبق نشره أو مشاركته.

## حدود البيانات والاشتراك

- الحصة اليومية ومعدل الطلبات والتغطية تعتمد على خطة API-Football النشطة؛ راجع لوحة الحساب قبل الإطلاق.
- يطبق التطبيق تخزيناً مؤقتاً داخل الذاكرة لتقليل تكرار طلبات المباريات والدوريات.
- لا تتوفر التشكيلات والإحصائيات لكل مباراة أو بطولة بالضرورة.
- شعارات الفرق والدوريات وصور اللاعبين تُعرض عند توافر روابطها في استجابة API.
- API-Football مصدر بيانات وإحصائيات، وليس مزود فيديو بث للمباريات.
- قد تتأخر بعض البيانات أو لا تتوفر بسبب التغطية أو توقيت التحديث أو اشتراك الحساب.

راجع التوثيق الرسمي: https://www.api-football.com/documentation-v3
