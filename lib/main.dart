import 'dart:async';
import 'dart:ui' as ui show FontFeature, TextDirection;

import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin/admin_portal.dart';
import 'streams/streams_screen.dart';
import 'services/football_api.dart';
import 'services/highlightly_api.dart';
import 'services/firebase_runtime.dart';
import 'config/api_config.dart';
import 'config/league_catalog.dart';
import 'utils/arabic_time.dart';
import 'utils/arabic_football.dart';

const Color cBg = Color(0xFF0B1018);
const Color cPanel = Color(0xFF121B27);
const Color cPanel2 = Color(0xFF172332);
const Color cLine = Color(0xFF263445);
const Color cMint = Color(0xFF20E6B2);
const Color cText = Color(0xFFF4F7FA);
const Color cMuted = Color(0xFF8D9AAA);
DateTime nowAden() => DateTime.now().toUtc().add(const Duration(hours: 3));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  await FirebaseRuntime.initialize();
  runApp(const DfishLiveApp());
}

class DfishLiveApp extends StatelessWidget {
  const DfishLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'DFISH LIVE',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: cBg,
        colorScheme: const ColorScheme.dark(
          primary: cMint,
          secondary: cMint,
          surface: cPanel,
          error: Color(0xFFFF667A),
        ),
        textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme).apply(
          bodyColor: cText,
          displayColor: cText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cBg,
          foregroundColor: cText,
          elevation: 0,
          centerTitle: false,
        ),
        dividerColor: cLine,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cPanel,
          hintStyle: const TextStyle(color: cMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cLine)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cMint)),
        ),
      ),
      builder: (context, child) => MaterialUiCompatibilityBridge(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const AppShell(),
    );
  }
}

// ---------- Shared models and widgets ----------
class MatchData {
  MatchData(Map<String, dynamic> json)
      : id = (json['fixture']?['id'] as num?)?.toInt() ?? 0,
        kickoff = json['fixture']?['date']?.toString() ?? '',
        elapsed = (json['fixture']?['status']?['elapsed'] as num?)?.toInt(),
        status = json['fixture']?['status']?['short']?.toString() ?? 'NS',
        statusLong = json['fixture']?['status']?['long']?.toString() ?? '',
        leagueId = (json['league']?['id'] as num?)?.toInt() ?? 0,
        league = ArabicFootball.league(LeagueCatalog.displayNameFor(json['league']?['country']?.toString() ?? '', json['league']?['name']?.toString() ?? 'بطولة'), json['league']?['country']?.toString() ?? ''),
        leagueLogo = json['league']?['logo']?.toString() ?? '',
        country = LeagueCatalog.displayCompetitionCountry(
          json['league']?['country']?.toString() ?? '',
          json['league']?['name']?.toString() ?? '',
        ),
        home = json['teams']?['home']?['name']?.toString() ?? 'الفريق الأول',
        away = json['teams']?['away']?['name']?.toString() ?? 'الفريق الثاني',
        homeId = (json['teams']?['home']?['id'] as num?)?.toInt() ?? 0,
        awayId = (json['teams']?['away']?['id'] as num?)?.toInt() ?? 0,
        homeLogo = json['teams']?['home']?['logo']?.toString() ?? '',
        awayLogo = json['teams']?['away']?['logo']?.toString() ?? '',
        homeWinner = json['teams']?['home']?['winner'] == true,
        awayWinner = json['teams']?['away']?['winner'] == true,
        homeGoals = (json['goals']?['home'] as num?)?.toInt(),
        awayGoals = (json['goals']?['away'] as num?)?.toInt(),
        round = json['league']?['round']?.toString() ?? '',
        venue = json['fixture']?['venue']?['name']?.toString() ?? '',
        city = json['fixture']?['venue']?['city']?.toString() ?? '',
        referee = json['fixture']?['referee']?.toString() ?? '',
        homeHalfGoals = (json['score']?['halftime']?['home'] as num?)?.toInt(),
        awayHalfGoals = (json['score']?['halftime']?['away'] as num?)?.toInt();

  final int id;
  final String kickoff;
  final int? elapsed;
  final String status;
  final String statusLong;
  final int leagueId;
  final String league;
  final String leagueLogo;
  final String country;
  final String home;
  final String away;
  final int homeId;
  final int awayId;
  final String homeLogo;
  final String awayLogo;
  final bool homeWinner;
  final bool awayWinner;
  final int? homeGoals;
  final int? awayGoals;
  final String round;
  final String venue;
  final String city;
  final String referee;
  final int? homeHalfGoals;
  final int? awayHalfGoals;

  String get halftimeScore => homeHalfGoals == null || awayHalfGoals == null
      ? '—'
      : '$homeHalfGoals - $awayHalfGoals';

  bool get isLive => const {'1H', 'HT', '2H', 'ET', 'BT', 'P', 'LIVE', 'SUSP', 'INT'}.contains(status);
  bool get isFinished => const {'FT', 'AET', 'PEN', 'AWD', 'WO'}.contains(status);
  bool get isPostponed => status == 'PST';
  bool get isCancelled => status == 'CANC';
  bool get isUpcoming => const {'NS', 'TBD'}.contains(status);
  String get score => homeGoals == null || awayGoals == null ? '—' : '$homeGoals - $awayGoals';
  String get timeLabel {
    if (isLive) return elapsed == null ? _footballText(statusLong) : "${elapsed!}'";
    if (isFinished) return 'انتهت';
    if (isPostponed) return 'مؤجلة';
    if (isCancelled) return 'ملغاة';
    if (status == 'ABD') return 'متوقفة';
    if (kickoff.length >= 16) return formatArabicTime(kickoff);
    return 'قريباً';
  }
}

String _mapText(dynamic value, [String fallback = '—']) => value == null || value.toString().trim().isEmpty ? fallback : ArabicFootball.text(value.toString());

String _footballText(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '—';
  const labels = <String, String>{
    'match not started': 'لم تبدأ', 'not started': 'لم تبدأ',
    'first half': 'الشوط الأول', 'first half finished': 'نهاية الشوط الأول',
    'halftime': 'استراحة بين الشوطين', 'second half': 'الشوط الثاني',
    'extra time': 'وقت إضافي', 'break time': 'استراحة إضافية',
    'penalty in progress': 'ركلات الترجيح', 'match finished': 'انتهت المباراة',
    'match finished after extra time': 'انتهت بعد الوقت الإضافي',
    'match finished after penalties': 'انتهت بركلات الترجيح',
    'match suspended': 'معلّقة', 'match interrupted': 'متوقفة مؤقتاً',
    'match postponed': 'مؤجلة', 'match cancelled': 'ملغاة',
    'time to be defined': 'الموعد يحدد لاحقاً', 'match abandoned': 'متوقفة',
    'technical loss': 'نتيجة إدارية', 'walkover': 'فوز اعتباري',
    'goal': 'هدف', 'own goal': 'هدف عكسي', 'penalty': 'ركلة جزاء',
    'missed penalty': 'ركلة جزاء ضائعة', 'card': 'بطاقة',
    'yellow card': 'بطاقة صفراء', 'red card': 'بطاقة حمراء',
    'subst': 'تبديل', 'substitution': 'تبديل', 'var': 'حكم الفيديو',
    'goalkeeper': 'حارس مرمى', 'defender': 'مدافع', 'midfielder': 'لاعب وسط',
    'attacker': 'مهاجم', 'forward': 'مهاجم',
    'shots on goal': 'تسديدات على المرمى', 'shots off goal': 'تسديدات خارج المرمى',
    'total shots': 'إجمالي التسديدات', 'blocked shots': 'تسديدات متصدّى لها',
    'shots insidebox': 'تسديدات من داخل المنطقة', 'shots outsidebox': 'تسديدات من خارج المنطقة',
    'fouls': 'الأخطاء', 'corner kicks': 'الركلات الركنية', 'offsides': 'التسلل',
    'ball possession': 'الاستحواذ', 'yellow cards': 'البطاقات الصفراء',
    'red cards': 'البطاقات الحمراء', 'goalkeeper saves': 'تصديات الحارس',
    'total passes': 'إجمالي التمريرات', 'passes accurate': 'التمريرات الصحيحة',
    'passes %': 'دقة التمرير', 'expected_goals': 'الأهداف المتوقعة',
    'loan': 'إعارة', 'free': 'انتقال مجاني', 'transfer': 'انتقال',
    'regular season': 'الموسم العادي',
  };
  return labels[raw.toLowerCase()] ?? ArabicFootball.text(raw);
}

dynamic _firstOrEmpty(dynamic value) => value is List && value.isNotEmpty ? value.first : <String, dynamic>{};

class NetworkBadge extends StatelessWidget {
  const NetworkBadge({super.key, required this.url, required this.label, this.size = 36});
  final String url;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: cPanel2, borderRadius: BorderRadius.circular(11), border: Border.all(color: cLine)),
      child: url.isEmpty
          ? Text(label.isEmpty ? '?' : label.substring(0, 1), style: const TextStyle(color: cText, fontWeight: FontWeight.w700))
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(imageUrl: url, width: size - 5, height: size - 5, fit: BoxFit.contain,
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (_, __) => SizedBox(width: size - 5, height: size - 5),
                errorWidget: (_, __, ___) => Text(label.isEmpty ? '?' : label.substring(0, 1), style: const TextStyle(color: cText, fontWeight: FontWeight.w700))),
            ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: ui.TextDirection.ltr,
    child: RichText(
      text: TextSpan(children: [
        TextSpan(text: 'DFISH ', style: TextStyle(color: cText, fontSize: compact ? 18 : 23, fontWeight: FontWeight.w900, letterSpacing: .4)),
        TextSpan(text: 'LIVE', style: TextStyle(color: cMint, fontSize: compact ? 18 : 23, fontWeight: FontWeight.w900, letterSpacing: .4)),
      ]),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      if (subtitle != null) Text(subtitle!, style: const TextStyle(color: cMuted, fontSize: 12)),
    ])),
    if (trailing != null) trailing!,
  ]);
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: cPanel,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(
      padding: padding,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: cLine.withValues(alpha: .7))),
      child: child,
    )),
  );
}

// ---------- App shell ----------
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final GlobalKey<_HomeScreenState> _homeKey = GlobalKey<_HomeScreenState>();
  final GlobalKey<_MatchesScreenState> _matchesKey = GlobalKey<_MatchesScreenState>();
  late final List<Widget> _pages = [
    HomeScreen(key: _homeKey),
    MatchesScreen(key: _matchesKey),
    const StandingsScreen(),
    const StreamMatchesScreen(),
    const MoreScreen(),
  ];
  Timer? _liveRefreshTimer;
  final _titles = const ['الرئيسية', 'المباريات', 'البطولات', 'البث', 'المزيد'];
  final _icons = const [LucideIcons.house, LucideIcons.calendarDays, LucideIcons.trophy, LucideIcons.radioTower, LucideIcons.layoutGrid];

  @override
  void initState() {
    super.initState();
    // Refresh only the visible football tab. A five-minute interval is
    // deliberately conservative to protect daily API quotas.
    _liveRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted || WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
      if (_index == 0) _homeKey.currentState?.refreshLive();
      if (_index == 1) _matchesKey.currentState?.refreshLiveIfToday();
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 10), child: Row(children: [
        const BrandMark(),
        const Spacer(),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())), icon: const Icon(LucideIcons.search, color: cText)),
        IconButton(onPressed: () => _showInfo(context), icon: const Icon(LucideIcons.bell, color: cText)),
      ])),
      Expanded(child: IndexedStack(index: _index, children: _pages)),
    ])),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(color: cPanel, border: Border(top: BorderSide(color: cLine))),
      child: SafeArea(top: false, child: Row(children: List.generate(_pages.length, (i) => Expanded(child: InkWell(
        onTap: () { setState(() => _index = i); if (i == 0) _homeKey.currentState?.refreshLive(); if (i == 1) _matchesKey.currentState?.refreshLiveIfToday(); },
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_icons[i], size: 21, color: _index == i ? cMint : cMuted),
          const SizedBox(height: 4),
          Text(_titles[i], style: TextStyle(fontSize: 10, color: _index == i ? cMint : cMuted, fontWeight: _index == i ? FontWeight.w700 : FontWeight.w500)),
        ])),
      ))))),
    ),
  );

  void _showInfo(BuildContext context) => showDialog<void>(context: context, builder: (_) => AlertDialog(
    backgroundColor: cPanel,
    title: const Text('التنبيهات'),
    content: const Text('سيتم تفعيل التنبيهات بعد ربط خدمة الإشعارات. لا توجد تنبيهات وهمية في هذه النسخة.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
  ));
}

// ---------- Home ----------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _future;
  @override
  void initState() { super.initState(); _future = FootballApi.instance.fixtures(date: nowAden()); }
  void _reload() => setState(() => _future = FootballApi.instance.fixtures(date: nowAden()));
  void refreshLive() { if (mounted) setState(() => _future = FootballApi.instance.fixtures(date: nowAden())); }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: cMint, backgroundColor: cPanel, onRefresh: () async => _reload(),
    child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF183C3A), Color(0xFF142536), Color(0xFF121B27)]),
          border: Border.all(color: cMint.withValues(alpha: .24)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('كل كرة القدم في مكان واحد', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('نتائج، تفاصيل، تشكيلات، إحصائيات وترتيب البطولات.', style: TextStyle(color: Color(0xFFB9C9D2), fontSize: 12)),
          const SizedBox(height: 16),
          Row(children: [
            _smallMetric('التاريخ', DateFormat('yyyy/MM/dd').format(nowAden())),
            const SizedBox(width: 10),
            _smallMetric('التوقيت', 'Asia / Aden'),
          ]),
        ]),
      ),
      const SizedBox(height: 22),
      SectionHeading('مباريات اليوم', subtitle: 'حسب توقيت اليمن (Asia/Aden)', trailing: IconButton(onPressed: _reload, icon: const Icon(LucideIcons.refreshCw, size: 18, color: cMint))),
      const SizedBox(height: 12),
      FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل مباريات اليوم');
          if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: _reload);
          final matches = (snapshot.data ?? []).map((e) => MatchData(Map<String, dynamic>.from(e as Map))).toList();
          final stale = FootballApi.instance.lastResponseWasStale;
          if (matches.isEmpty) return Column(children: [if (stale) const CacheNotice(), const EmptyPanel(title: 'لا توجد مباريات مدرجة اليوم', subtitle: 'قد لا تكون هناك مباريات أو قد لا يغطي المصدر هذه البطولة.')]);
          final selected = matches.where((m) => m.isLive).toList()..addAll(matches.where((m) => !m.isLive).take(5));
          return Column(children: [if (stale) const CacheNotice(), ...selected.take(6).map((m) => Padding(padding: const EdgeInsets.only(bottom: 10), child: MatchTile(match: m)))]);
        },
      ),
      const SizedBox(height: 12),
      const SectionHeading('اكتشف DFISH LIVE', subtitle: 'أقسام التطبيق'),
      const SizedBox(height: 12),
      const Wrap(spacing: 9, runSpacing: 9, children: [
        FeatureChip(icon: LucideIcons.chartNoAxesCombined, text: 'إحصائيات'),
        FeatureChip(icon: LucideIcons.users, text: 'اللاعبون'),
        FeatureChip(icon: LucideIcons.arrowLeftRight, text: 'الانتقالات'),
        FeatureChip(icon: LucideIcons.tv, text: 'التلفزيون'),
        FeatureChip(icon: LucideIcons.clapperboard, text: 'الأفلام'),
      ]),
      const SizedBox(height: 20),
    ]),
  );

  Widget _smallMetric(String title, String value) => Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black.withValues(alpha: .18), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: cMuted, fontSize: 10)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))])));
}

class FeatureChip extends StatelessWidget {
  const FeatureChip({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: cPanel, borderRadius: BorderRadius.circular(12), border: Border.all(color: cLine)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: cMint, size: 16), const SizedBox(width: 7), Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]));
}

class CacheNotice extends StatelessWidget {
  const CacheNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFF493A1E).withValues(alpha: .35),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFD7A64A).withValues(alpha: .45)),
    ),
    child: const Row(children: [
      Icon(LucideIcons.wifiOff, size: 15, color: Color(0xFFE0B45E)),
      SizedBox(width: 8),
      Expanded(child: Text('تعرض آخر بيانات محفوظة؛ التحديث متوقف مؤقتاً حتى عودة خدمة البيانات.', style: TextStyle(color: Color(0xFFE7D4AA), fontSize: 10, height: 1.5))),
    ]),
  );
}

// ---------- Matches ----------
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});
  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  DateTime _date = nowAden();
  String _filter = 'الكل';
  late Future<List<dynamic>> _future;
  @override
  void initState() { super.initState(); _future = FootballApi.instance.fixtures(date: _date); }
  void _load() => setState(() => _future = FootballApi.instance.fixtures(date: _date));
  void refreshLiveIfToday() { final today = nowAden(); if (mounted && _date.year == today.year && _date.month == today.month && _date.day == today.day) { setState(() => _future = FootballApi.instance.fixtures(date: _date)); } }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
    const SectionHeading('المباريات', subtitle: 'تابع المواجهات والنتائج حسب اليوم'),
    const SizedBox(height: 14),
    Panel(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7), child: Row(children: [
      IconButton(onPressed: () { _date = _date.subtract(const Duration(days: 1)); _load(); }, icon: const Icon(LucideIcons.chevronRight, color: cText)),
      Expanded(child: Center(child: Column(children: [Text(DateFormat('EEEE', 'ar').format(_date), style: const TextStyle(color: cMuted, fontSize: 11)), Text(DateFormat('d MMMM yyyy', 'ar').format(_date), style: const TextStyle(fontWeight: FontWeight.w800))]))),
      IconButton(onPressed: () { _date = nowAden(); _load(); }, icon: const Icon(LucideIcons.calendarDays, color: cMint)),
      IconButton(onPressed: () { _date = _date.add(const Duration(days: 1)); _load(); }, icon: const Icon(LucideIcons.chevronLeft, color: cText)),
    ])),
    const SizedBox(height: 12),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['الكل', 'مباشر', 'قادمة', 'انتهت', 'مؤجلة', 'ملغاة'].map((v) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(v), selected: _filter == v, onSelected: (_) => setState(() => _filter = v), selectedColor: cMint.withValues(alpha: .2), backgroundColor: cPanel, labelStyle: TextStyle(color: _filter == v ? cMint : cMuted), side: BorderSide(color: _filter == v ? cMint : cLine)))).toList())),
    const SizedBox(height: 12),
    FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل جدول المباريات');
        if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: _load);
        var list = (snapshot.data ?? []).map((e) => MatchData(Map<String, dynamic>.from(e as Map))).toList();
        if (_filter == 'مباشر') list = list.where((m) => m.isLive).toList();
        if (_filter == 'قادمة') list = list.where((m) => m.isUpcoming).toList();
        if (_filter == 'انتهت') list = list.where((m) => m.isFinished).toList();
        if (_filter == 'مؤجلة') list = list.where((m) => m.isPostponed).toList();
        if (_filter == 'ملغاة') list = list.where((m) => m.isCancelled).toList();
        if (list.isEmpty) return Column(children: [if (FootballApi.instance.lastResponseWasStale) const CacheNotice(), const EmptyPanel(title: 'لا توجد مباريات في هذا التصنيف', subtitle: 'غيّر اليوم أو مرشح المباريات.')]);
        final groups = <String, List<MatchData>>{};
        for (final match in list) { groups.putIfAbsent('${match.leagueId}|${match.league}|${match.country}|${match.leagueLogo}', () => []).add(match); }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (FootballApi.instance.lastResponseWasStale) const CacheNotice(),
          ...groups.entries.map((entry) {
          final parts = entry.key.split('|');
          return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(children: [
            Row(children: [NetworkBadge(url: parts.length > 3 ? parts[3] : '', label: parts.length > 1 ? parts[1] : 'بطولة', size: 30), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(parts.length > 1 ? parts[1] : 'بطولة', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), Text(parts.length > 2 ? parts[2] : '', style: const TextStyle(color: cMuted, fontSize: 10))])), const Icon(LucideIcons.chevronLeft, color: cMuted, size: 17)]),
            const SizedBox(height: 8),
            ...entry.value.map((m) => Padding(padding: const EdgeInsets.only(bottom: 8), child: MatchTile(match: m))),
          ]));
        }),
        ]);
      },
    ),
  ]);
}

class MatchTile extends StatelessWidget {
  const MatchTile({super.key, required this.match});
  final MatchData match;
  @override
  Widget build(BuildContext context) => Panel(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailsScreen(match: match))),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    child: Row(children: [
      Expanded(child: _team(match.home, match.homeLogo, match.homeWinner)),
      SizedBox(width: 84, child: Column(children: [
        if (match.isLive) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFF5267).withValues(alpha: .14), borderRadius: BorderRadius.circular(5)), child: Text(match.timeLabel, style: const TextStyle(color: Color(0xFFFF7182), fontSize: 10, fontWeight: FontWeight.w800)))
        else Text(match.timeLabel, style: const TextStyle(color: cMuted, fontSize: 11)),
        const SizedBox(height: 5),
        Text(match.score, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFeatures: [ui.FontFeature.tabularFigures()])),
        if (match.isFinished) const Text('انتهت', style: TextStyle(color: cMuted, fontSize: 9)),
      ])),
      Expanded(child: _team(match.away, match.awayLogo, match.awayWinner, right: true)),
    ]),
  );

  Widget _team(String name, String logo, bool winner, {bool right = false}) => Row(mainAxisAlignment: right ? MainAxisAlignment.start : MainAxisAlignment.end, children: [
    if (!right) ...[Flexible(child: Text(ArabicFootball.team(name), maxLines: 2, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: winner ? FontWeight.w800 : FontWeight.w600))), const SizedBox(width: 7)],
    NetworkBadge(url: logo, label: name, size: 34),
    if (right) ...[const SizedBox(width: 7), Flexible(child: Text(ArabicFootball.team(name), maxLines: 2, textAlign: TextAlign.start, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: winner ? FontWeight.w800 : FontWeight.w600)))],
  ]);
}

// ---------- Match detail ----------
class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({super.key, required this.match});
  final MatchData match;
  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  int _tab = 0;
  Future<Map<String, dynamic>?>? _highlightlyMatchFuture;
  Timer? _highlightlyLiveTimer;
  static const _tabs = ['الملخص', 'الفعاليات', 'التشكيلات', 'الإحصائيات', 'بيانات اللاعبين', 'تفاصيل المباراة', 'المواجهات'];

  @override
  void initState() {
    super.initState();
    if (HighlightlyApi.instance.isConfigured) {
      final match = widget.match;
      _highlightlyMatchFuture = HighlightlyApi.instance.resolveMatch(
        kickoff: match.kickoff,
        homeTeam: match.home,
        awayTeam: match.away,
      );
      if (match.isLive) {
        _highlightlyLiveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
          if (mounted && (_tab == 1 || _tab == 3 || _tab == 4)) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    _highlightlyLiveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز المباراة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final key = 'fav_${m.homeId}_${m.awayId}';
              await prefs.setBool(key, !(prefs.getBool(key) ?? false));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث المفضلة')));
            },
            icon: const Icon(LucideIcons.star),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(padding: const EdgeInsets.all(18), child: Column(children: [
          Text(ArabicFootball.league(m.league, m.country), style: const TextStyle(color: cMuted, fontSize: 12)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _bigTeam(ArabicFootball.team(m.home), m.homeLogo)),
            Column(children: [
              Text(m.score, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(m.timeLabel, style: TextStyle(color: m.isLive ? cMint : cMuted, fontWeight: FontWeight.w700, fontSize: 11)),
            ]),
            Expanded(child: _bigTeam(ArabicFootball.team(m.away), m.awayLogo)),
          ]),
          const SizedBox(height: 12),
          Text(_footballText(m.statusLong), style: const TextStyle(color: cMuted, fontSize: 11)),
        ])),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: List.generate(_tabs.length, (index) => Padding(
            padding: const EdgeInsetsDirectional.only(end: 7),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: _tab == index,
              onSelected: (_) => setState(() => _tab = index),
              selectedColor: cMint.withValues(alpha: .16),
              backgroundColor: cPanel,
              labelStyle: TextStyle(color: _tab == index ? cMint : cMuted, fontSize: 11),
              side: BorderSide(color: _tab == index ? cMint : cLine),
            ),
          ))),
        ),
        const SizedBox(height: 12),
        if (_tab == 0) _summary(m)
        else if (_tab == 1) _highlightlySection('events', _dataList('fixtures/events'))
        else if (_tab == 2) _highlightlySection('lineups', _dataList('fixtures/lineups'))
        else if (_tab == 3) _highlightlySection('statistics', _dataList('fixtures/statistics'))
        else if (_tab == 4) _highlightlySection('players', _dataList('fixtures/players'))
        else if (_tab == 5) _highlightlySection('details', _summary(m))
        else _headToHead(m),
      ]),
    );
  }

  Widget _highlightlySection(String kind, Widget fallback) {
    final future = _highlightlyMatchFuture;
    if (!HighlightlyApi.instance.isConfigured || future == null) return fallback;
    return FutureBuilder<Map<String, dynamic>?>(
      future: future,
      builder: (context, matchSnapshot) {
        if (matchSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPanel(label: 'جاري مطابقة المباراة مع مصدر البيانات الإضافي');
        }
        if (matchSnapshot.hasError) {
          return Column(children: [
            _sourceFallbackNotice('تعذر الوصول إلى Highlightly؛ نعرض البيانات من المصدر الحالي.'),
            fallback,
          ]);
        }
        final match = matchSnapshot.data;
        final id = (match?['id'] as num?)?.toInt();
        if (id == null || id <= 0) {
          return Column(children: [
            _sourceFallbackNotice('لم نعثر على تطابق مؤكد لهذه المباراة في Highlightly؛ نعرض بيانات API-Football.'),
            fallback,
          ]);
        }
        return FutureBuilder<dynamic>(
          key: ValueKey('hl-${widget.match.id}-$id-$kind'),
          future: _loadHighlightlySection(kind, id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingPanel(label: 'جاري تحميل بيانات المباراة');
            }
            if (snapshot.hasError) {
              return Column(children: [
                _sourceFallbackNotice('لم تتوفر هذه البيانات من Highlightly؛ نعرض بيانات المصدر الحالي عند توفرها.'),
                fallback,
              ]);
            }
            final data = snapshot.data;
            if (data == null) return fallback;
            return _renderHighlightlySection(kind, data);
          },
        );
      },
    );
  }

  Future<dynamic> _loadHighlightlySection(String kind, int id) {
    switch (kind) {
      case 'events': return HighlightlyApi.instance.liveEvents(id);
      case 'lineups': return HighlightlyApi.instance.lineups(id);
      case 'statistics': return HighlightlyApi.instance.matchStatistics(id);
      case 'players': return HighlightlyApi.instance.boxScore(id);
      case 'details': return HighlightlyApi.instance.matchDetails(id);
      default: return Future<dynamic>.value(null);
    }
  }

  Widget _sourceFallbackNotice(String message) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Panel(padding: const EdgeInsets.all(10), child: Row(children: [
      const Icon(LucideIcons.info, color: cMint, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(color: cMuted, fontSize: 10, height: 1.5))),
    ])),
  );

  Widget _renderHighlightlySection(String kind, dynamic raw) {
    if (kind == 'events') {
      final rows = HighlightlyApi.asList(raw);
      if (rows.isEmpty) return const EmptyPanel(title: 'لا توجد فعاليات مسجلة', subtitle: 'قد لا تكون أحداث هذه المباراة متاحة بعد.');
      return Column(children: rows.map((event) {
        final minute = _mapText(event['time'], '—');
        final type = ArabicFootball.text(event['type'] ?? 'حدث');
        final team = event['team'] is Map ? ArabicFootball.team(event['team']['name']?.toString() ?? '') : '';
        final player = _mapText(event['player'], '');
        final assist = _mapText(event['assist'], '');
        final substituted = _mapText(event['substituted'], '');
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(padding: const EdgeInsets.all(12), child: Row(children: [
          Container(width: 53, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: cPanel2, borderRadius: BorderRadius.circular(9)), child: Text(minute, textAlign: TextAlign.center, style: const TextStyle(color: cMint, fontWeight: FontWeight.w900, fontSize: 11))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            if (player.isNotEmpty) Text(player, style: const TextStyle(color: cText, fontSize: 10)),
            if (assist.isNotEmpty) Text('صناعة: $assist', style: const TextStyle(color: cMuted, fontSize: 9)),
            if (substituted.isNotEmpty) Text('خروج: $substituted', style: const TextStyle(color: cMuted, fontSize: 9)),
            if (team.isNotEmpty) Text(team, style: const TextStyle(color: cMuted, fontSize: 9)),
          ])),
        ])));
      }).toList());
    }

    if (kind == 'lineups') {
      final data = HighlightlyApi.asObject(raw);
      final home = data?['homeTeam'];
      final away = data?['awayTeam'];
      if (home is! Map || away is! Map) return const EmptyPanel(title: 'التشكيلة لم تُعلن بعد', subtitle: 'تُتاح التشكيلات عادةً قبل انطلاق المباراة بوقت قصير.');
      return Column(children: [
        _highlightlyPitch(Map<String, dynamic>.from(home)),
        const SizedBox(height: 12),
        _highlightlyPitch(Map<String, dynamic>.from(away)),
      ]);
    }

    if (kind == 'statistics') {
      final rows = HighlightlyApi.asList(raw);
      if (rows.isEmpty) return const EmptyPanel(title: 'إحصائيات المباراة غير متاحة', subtitle: 'لم ينشر مزوّد البيانات إحصائيات هذه المباراة بعد.');
      return Column(children: rows.map((teamRow) {
        final team = teamRow['team'] is Map ? Map<String, dynamic>.from(teamRow['team']) : <String, dynamic>{};
        final stats = teamRow['statistics'] is List ? teamRow['statistics'] as List : const [];
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [NetworkBadge(url: _mapText(team['logo'], ''), label: _mapText(team['name'], ''), size: 28), const SizedBox(width: 8), Expanded(child: Text(ArabicFootball.team(_mapText(team['name'], 'الفريق')), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)))]),
          const Divider(color: cLine),
          ...stats.whereType<Map>().map((stat) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
            Expanded(child: Text(ArabicFootball.text(stat['displayName'] ?? stat['name']), style: const TextStyle(color: cMuted, fontSize: 11))),
            Text(_highlightlyStatValue(stat['value'], stat['displayName']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          ]))),
        ])));
      }).toList());
    }

    if (kind == 'players') {
      final rows = HighlightlyApi.asList(raw);
      if (rows.isEmpty) return const EmptyPanel(title: 'بيانات اللاعبين غير متاحة', subtitle: 'قد لا يوفر مزوّد البيانات إحصائيات فردية لهذه المباراة.');
      return Column(children: rows.map((teamRow) {
        final team = teamRow['team'] is Map ? Map<String, dynamic>.from(teamRow['team']) : <String, dynamic>{};
        final players = teamRow['players'] is List ? teamRow['players'] as List : const [];
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [NetworkBadge(url: _mapText(team['logo'], ''), label: _mapText(team['name'], ''), size: 28), const SizedBox(width: 8), Expanded(child: Text(ArabicFootball.team(_mapText(team['name'], 'الفريق')), style: const TextStyle(fontWeight: FontWeight.w900)))]),
          const Divider(color: cLine),
          ...players.whereType<Map>().map((player) {
            final id = (player['id'] as num?)?.toInt();
            final profileId = id != null && id > 0 ? id : null;
            final name = _mapText(player['name'], 'لاعب');
            final stats = player['statistics'] is List && (player['statistics'] as List).isNotEmpty && (player['statistics'] as List).first is Map
                ? Map<String, dynamic>.from((player['statistics'] as List).first as Map)
                : (player['statistics'] is Map ? Map<String, dynamic>.from(player['statistics']) : <String, dynamic>{});
            final metrics = <String>[
              if (player['shirtNumber'] != null) 'رقم ${player['shirtNumber']}',
              if (player['isCaptain'] == true) 'قائد الفريق',
              if (player['isSubstitute'] == true) 'شارك بديلاً',
              if (player['offsides'] != null) 'تسلل ${player['offsides']}',
              if (player['minutesPlayed'] != null) '${player['minutesPlayed']} د',
              'أهداف ${stats['goalsScored'] ?? 0}',
              'صناعة ${stats['assists'] ?? 0}',
              'تسديدات ${stats['shotsTotal'] ?? stats['shotsOnTarget'] ?? '—'}',
              if (player['matchRating'] != null) 'التقييم ${player['matchRating']}',
            ];
            return InkWell(
              onTap: profileId == null ? null : () => _showHighlightlyPlayer(profileId, name, Map<String, dynamic>.from(player)),
              borderRadius: BorderRadius.circular(10),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
                NetworkBadge(url: _mapText(player['logo'], ''), label: name, size: 36),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  Text('${ArabicFootball.text(player['position'] ?? '')} · ${metrics.join(' · ')}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cMuted, fontSize: 9)),
                ])),
                const Icon(LucideIcons.chevronLeft, size: 16, color: cMuted),
              ])),
            );
          }),
        ])));
      }).toList());
    }

    if (kind == 'details') {
      final detail = HighlightlyApi.asObject(raw);
      if (detail == null) return const EmptyPanel(title: 'تفاصيل المباراة غير متاحة', subtitle: 'لا توجد بيانات إضافية لهذه المباراة حالياً.');
      final league = detail['league'] is Map ? Map<String, dynamic>.from(detail['league']) : <String, dynamic>{};
      final homeTeam = detail['homeTeam'] is Map ? Map<String, dynamic>.from(detail['homeTeam']) : <String, dynamic>{};
      final awayTeam = detail['awayTeam'] is Map ? Map<String, dynamic>.from(detail['awayTeam']) : <String, dynamic>{};
      final country = detail['country'] is Map ? Map<String, dynamic>.from(detail['country']) : <String, dynamic>{};
      final venue = detail['venue'] is Map ? Map<String, dynamic>.from(detail['venue']) : <String, dynamic>{};
      final referee = detail['referee'] is Map ? Map<String, dynamic>.from(detail['referee']) : <String, dynamic>{};
      final forecast = detail['forecast'] is Map ? Map<String, dynamic>.from(detail['forecast']) : <String, dynamic>{};
      final state = detail['state'] is Map ? Map<String, dynamic>.from(detail['state']) : <String, dynamic>{};
      final score = state['score'] is Map ? Map<String, dynamic>.from(state['score']) : <String, dynamic>{};
      final predictions = detail['predictions'] is Map ? Map<String, dynamic>.from(detail['predictions']) : <String, dynamic>{};
      final news = detail['news'] is List ? detail['news'] as List : const [];
      final homeShots = homeTeam['shots'] is List ? homeTeam['shots'] as List : const [];
      final awayShots = awayTeam['shots'] is List ? awayTeam['shots'] as List : const [];
      final homeTopPlayers = homeTeam['topPlayers'] is List ? homeTeam['topPlayers'] as List : const [];
      final awayTopPlayers = awayTeam['topPlayers'] is List ? awayTeam['topPlayers'] as List : const [];
      return Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('بيانات المباراة الكاملة', style: TextStyle(color: cMint, fontWeight: FontWeight.w900, fontSize: 14)),
        const Divider(color: cLine),
        _infoRow('الفريق المستضيف', ArabicFootball.team(_mapText(homeTeam['name'], ''))),
        _infoRow('الفريق الضيف', ArabicFootball.team(_mapText(awayTeam['name'], ''))),
        _infoRow('البطولة', ArabicFootball.league(_mapText(league['name'], ''), _mapText(country['name'], ''))),
        _infoRow('الدولة', ArabicFootball.country(_mapText(country['name'], ''))),
        _infoRow('الموسم', _mapText(league['season'])),
        _infoRow('الجولة', _mapText(detail['round'])),
        _infoRow('حالة المباراة', ArabicFootball.text(state['description'])),
        _infoRow('النتيجة', _mapText(score['current'])),
        _infoRow('نتيجة ركلات الترجيح', _mapText(score['penalties'], '')) ,
        _infoRow('دقيقة المباراة', _mapText(state['clock'], '')),
        _infoRow('الملعب', _mapText(venue['name'])),
        _infoRow('المدينة', _mapText(venue['city'])),
        _infoRow('الدولة المستضيفة', ArabicFootball.country(_mapText(venue['country'], ''))),
        _infoRow('سعة الملعب', _mapText(venue['capacity'])),
        _infoRow('الحكم', _mapText(referee['name'])),
        _infoRow('جنسية الحكم', ArabicFootball.country(_mapText(referee['nationality'], ''))),
        _infoRow('حالة الطقس', ArabicFootball.text(forecast['status'])),
        _infoRow('درجة الحرارة', _mapText(forecast['temperature'])),
        if (homeShots.isNotEmpty || awayShots.isNotEmpty) ...[
          const Divider(color: cLine),
          const Text('تفاصيل التسديدات', style: TextStyle(color: cMint, fontWeight: FontWeight.w900)),
          for (final entry in <Map<String, dynamic>>[
            {'team': homeTeam, 'shots': homeShots},
            {'team': awayTeam, 'shots': awayShots},
          ])
            if ((entry['shots'] as List).isNotEmpty) ...[
              Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text(ArabicFootball.team(_mapText((entry['team'] as Map)['name'], 'الفريق')), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
              ...(entry['shots'] as List).whereType<Map>().take(10).map((shot) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${_mapText(shot['time'])} · ${_mapText(shot['playerName'])} · ${ArabicFootball.text(shot['outcome'])} · ${ArabicFootball.text(shot['goalTarget'])}', style: const TextStyle(color: cMuted, fontSize: 9)),
              )),
            ],
        ],
        if (homeTopPlayers.isNotEmpty || awayTopPlayers.isNotEmpty) ...[
          const Divider(color: cLine),
          const Text('أبرز لاعبي المباراة', style: TextStyle(color: cMint, fontWeight: FontWeight.w900)),
          for (final entry in <Map<String, dynamic>>[
            {'team': homeTeam, 'players': homeTopPlayers},
            {'team': awayTeam, 'players': awayTopPlayers},
          ])
            if ((entry['players'] as List).isNotEmpty) ...[
              Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text(ArabicFootball.team(_mapText((entry['team'] as Map)['name'], 'الفريق')), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
              ...(entry['players'] as List).whereType<Map>().take(5).map((topPlayer) {
                final values = topPlayer['statistics'] is List ? topPlayer['statistics'] as List : const [];
                final summary = values.whereType<Map>().map((stat) {
                  final value = stat['value'];
                  final valueText = value is Map ? value.values.join(' / ') : _mapText(value);
                  return '${ArabicFootball.text(stat['name'])}: $valueText';
                }).join(' · ');
                return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text('${_mapText(topPlayer['name'])} · ${ArabicFootball.text(topPlayer['position'])} · $summary', style: const TextStyle(color: cMuted, fontSize: 9)));
              }),
            ],
        ],
        if ((predictions['prematch'] is List && (predictions['prematch'] as List).isNotEmpty) || (predictions['live'] is List && (predictions['live'] as List).isNotEmpty)) ...[
          const Divider(color: cLine),
          const Text('توقعات المباراة', style: TextStyle(color: cMint, fontWeight: FontWeight.w900)),
          for (final source in ['prematch', 'live'])
            if (predictions[source] is List)
              ...(predictions[source] as List).whereType<Map>().take(3).map((prediction) {
                final probabilities = prediction['probabilities'] is Map ? Map<String, dynamic>.from(prediction['probabilities']) : <String, dynamic>{};
                return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text('${source == 'live' ? 'توقع مباشر' : 'توقع قبل المباراة'}: ${_mapText(probabilities['home'], '')} · تعادل ${_mapText(probabilities['draw'], '')} · ${_mapText(probabilities['away'], '')}', style: const TextStyle(fontSize: 10, color: cMuted)));
              }),
        ],
        if (news.isNotEmpty) ...[
          const Divider(color: cLine),
          const Text('أخبار مرتبطة بالمباراة', style: TextStyle(color: cMint, fontWeight: FontWeight.w900)),
          ...news.whereType<Map>().take(5).map((item) => Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(item['url']?.toString() ?? '');
                if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(LucideIcons.externalLink, size: 14),
              label: Text('فتح الخبر الأصلي · ${_mapText(item['datePublished'], '')}', style: const TextStyle(fontSize: 10)),
            ),
          )),
        ],
      ]));
    }
    return const SizedBox.shrink();
  }

  String _highlightlyStatValue(dynamic value, dynamic label) {
    final key = label?.toString().toLowerCase() ?? '';
    if (value is num && value >= 0 && value <= 1 &&
        (key.contains('accuracy') || key.contains('possession') || key.contains('percentage'))) {
      return '${(value * 100).round()}%';
    }
    return _mapText(value);
  }

  Widget _highlightlyPitch(Map<String, dynamic> team) {
    final initial = team['initialLineup'] is List ? team['initialLineup'] as List : const [];
    final substitutes = team['substitutes'] is List ? team['substitutes'] as List : const [];
    final name = ArabicFootball.team(_mapText(team['name'], 'الفريق'));
    return Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [NetworkBadge(url: _mapText(team['logo'], ''), label: name, size: 31), const SizedBox(width: 8), Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))), Text(_mapText(team['formation']), style: const TextStyle(color: cMint, fontWeight: FontWeight.w900))]),
      const SizedBox(height: 10),
      Container(
        constraints: const BoxConstraints(minHeight: 265),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF145B43), Color(0xFF0E4938)]),
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (final row in initial)
            if (row is List)
              Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Wrap(alignment: WrapAlignment.spaceEvenly, spacing: 8, runSpacing: 8, children: row.whereType<Map>().map((player) => _pitchPlayer(Map<String, dynamic>.from(player))).toList())),
        ]),
      ),
      const SizedBox(height: 9),
      Text('البدلاء (${substitutes.length})', style: const TextStyle(color: cMint, fontWeight: FontWeight.w800, fontSize: 11)),
      const SizedBox(height: 5),
      if (substitutes.isEmpty) const Text('لا توجد قائمة بدلاء متاحة', style: TextStyle(color: cMuted, fontSize: 10)),
      Wrap(spacing: 6, runSpacing: 6, children: substitutes.whereType<Map>().map((player) => Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: cPanel2,
        side: const BorderSide(color: cLine),
        label: Text('${player['number'] ?? ''} ${player['name'] ?? ''}', style: const TextStyle(fontSize: 9)),
      )).toList()),
    ]));
  }

  Widget _pitchPlayer(Map<String, dynamic> player) => SizedBox(
    width: 75,
    child: Column(children: [
      Container(width: 29, height: 29, alignment: Alignment.center, decoration: BoxDecoration(color: cText, shape: BoxShape.circle, border: Border.all(color: cMint, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)]), child: Text(_mapText(player['number'], '—'), style: const TextStyle(color: cBg, fontSize: 10, fontWeight: FontWeight.w900))),
      const SizedBox(height: 3),
      Text(_mapText(player['name'], 'لاعب'), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
    ]),
  );

  Future<void> _showHighlightlyPlayer(int playerId, String name, [Map<String, dynamic>? matchPlayer]) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cPanel,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<dynamic>(
            future: HighlightlyApi.instance.playerDetails(playerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: cMint)));
              if (snapshot.hasError) return SizedBox(height: 150, child: Center(child: Text(snapshot.error.toString(), textAlign: TextAlign.center)));
              final player = HighlightlyApi.asObject(snapshot.data) ?? <String, dynamic>{};
              final profile = player['profile'] is Map ? Map<String, dynamic>.from(player['profile']) : <String, dynamic>{};
              final position = profile['position'] is Map ? Map<String, dynamic>.from(profile['position']) : <String, dynamic>{};
              final club = profile['club'] is Map ? Map<String, dynamic>.from(profile['club']) : <String, dynamic>{};
              return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(_mapText(player['fullName'], name), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 9),
                _infoRow('النادي الحالي', ArabicFootball.team(_mapText(club['current'], ''))),
                _infoRow('المركز', ArabicFootball.text(position['main'])),
                _infoRow('مراكز أخرى', ArabicFootball.text(position['secondary'])),
                _infoRow('الجنسية', ArabicFootball.country(_mapText(profile['citizenship'], ''))),
                _infoRow('تاريخ الميلاد', _mapText(profile['birthDate'])),
                _infoRow('مكان الميلاد', _mapText(profile['birthPlace'])),
                _infoRow('الطول', _mapText(profile['height'])),
                _infoRow('القدم المفضلة', ArabicFootball.text(profile['foot'])),
                if (matchPlayer != null) ...[
                  const Divider(color: cLine),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('إحصائيات اللاعب في هذه المباراة', style: TextStyle(color: cMint, fontWeight: FontWeight.w900, fontSize: 12)),
                    children: [
                      _highlightlyPlayerMatchMetrics(matchPlayer),
                    ],
                  ),
                ],
                if (player['transfers'] is List && (player['transfers'] as List).isNotEmpty) ...[
                  const Divider(color: cLine),
                  const Text('سجل الانتقالات', style: TextStyle(color: cMint, fontWeight: FontWeight.w900)),
                  ...(player['transfers'] as List).take(6).whereType<Map>().map((transfer) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${_mapText(transfer['transferDate'])} · ${ArabicFootball.text(transfer['type'])} · ${ArabicFootball.team(_mapText(transfer['from'], ''))} ← ${ArabicFootball.team(_mapText(transfer['to'], ''))} · ${_mapText(transfer['fee'], '')}', style: const TextStyle(color: cMuted, fontSize: 9)),
                  )),
                ],
                if (player['injuries'] is List && (player['injuries'] as List).isNotEmpty) ...[
                  const Divider(color: cLine),
                  const Text('سجل الإصابات', style: TextStyle(color: cMint, fontWeight: FontWeight.w900)),
                  ...(player['injuries'] as List).take(5).whereType<Map>().map((injury) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${_mapText(injury['reason'])} · ${_mapText(injury['season'])} · ${_mapText(injury['fromDate'])} · مباريات غاب عنها: ${_mapText(injury['missedGames'], '0')} · ${_mapText(injury['absentDurationInDays'], '—')} يوم', style: const TextStyle(color: cMuted, fontSize: 9)),
                  )),
                ],
                if (player['marketValue'] is List && (player['marketValue'] as List).isNotEmpty) ...[
                  const Divider(color: cLine),
                  const Text('القيمة السوقية', style: TextStyle(color: cMint, fontWeight: FontWeight.w900)),
                  ...(player['marketValue'] as List).take(5).whereType<Map>().map((value) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${_mapText(value['recordedDate'])} · ${_mapText(value['club'])} · ${_mapText(value['currency'])}${_mapText(value['value'])} · العمر ${_mapText(value['age'])}', style: const TextStyle(color: cMuted, fontSize: 9)),
                  )),
                ],
                if (player['rumours'] is Map) ...[
                  const Divider(color: cLine),
                  const Text('شائعات الانتقال (غير مؤكدة)', style: TextStyle(color: cMint, fontWeight: FontWeight.w900)),
                  ...((player['rumours']['current'] is List) ? player['rumours']['current'] as List : const []).whereType<Map>().take(4).map((rumour) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${ArabicFootball.team(_mapText(rumour['club'], ''))} · ${_mapText(rumour['rumourDate'])} · احتمال ${_mapText(rumour['transferProbability'])}', style: const TextStyle(color: cMuted, fontSize: 9)),
                  )),
                ],
                const Divider(color: cLine),
                const Text('إحصائيات اللاعب حسب البطولة', style: TextStyle(color: cMint, fontWeight: FontWeight.w900)),
                FutureBuilder<dynamic>(
                  future: HighlightlyApi.instance.playerStatistics(playerId),
                  builder: (context, statsSnapshot) {
                    if (statsSnapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(color: cMint)));
                    if (statsSnapshot.hasError) return const Text('إحصائيات الموسم غير متاحة حالياً', style: TextStyle(color: cMuted, fontSize: 10));
                    final stats = HighlightlyApi.asObject(statsSnapshot.data) ?? <String, dynamic>{};
                    final competitions = stats['perCompetition'] is List ? stats['perCompetition'] as List : const [];
                    if (competitions.isEmpty) return const Text('لا توجد إحصائيات موسمية منشورة', style: TextStyle(color: cMuted, fontSize: 10));
                    return Column(children: competitions.take(8).whereType<Map>().map((item) => Panel(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('${ArabicFootball.league(_mapText(item['league'], ''))} · ${_mapText(item['season'])}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      Text('مباريات ${item['gamesPlayed'] ?? 0} · دقائق ${item['minutesPlayed'] ?? 0} · أهداف ${item['goals'] ?? 0} · صناعة ${item['assists'] ?? 0} · صفراء ${item['yellowCards'] ?? 0} · حمراء ${item['redCards'] ?? 0}', style: const TextStyle(color: cMuted, fontSize: 9)),
                    ]))).toList());
                  },
                ),
              ]));
            },
          ),
        ),
      ),
    );
  }

  Widget _highlightlyPlayerMatchMetrics(Map<String, dynamic> player) {
    final raw = player['statistics'];
    final stats = raw is List && raw.isNotEmpty && raw.first is Map
        ? Map<String, dynamic>.from(raw.first as Map)
        : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
    const labels = <String, String>{
      'goalsScored': 'الأهداف', 'goalsSaved': 'تصديات الحارس', 'goalsConceded': 'أهداف استقبلها',
      'assists': 'التمريرات الحاسمة', 'dribblesTotal': 'المراوغات', 'dribblesSuccessful': 'مراوغات ناجحة',
      'dribblesFailed': 'مراوغات غير ناجحة', 'dribbleSuccessRate': 'نسبة نجاح المراوغات',
      'fouledByOthers': 'الأخطاء التي تعرض لها', 'fouledOthers': 'الأخطاء المرتكبة',
      'tacklesTotal': 'التدخلات', 'interceptionsTotal': 'الاعتراضات', 'duelsTotal': 'الالتحامات',
      'duelsWon': 'الالتحامات الناجحة', 'duelsLost': 'الالتحامات الخاسرة', 'duelSuccessRate': 'نجاح الالتحامات',
      'cardsRed': 'بطاقات حمراء', 'cardsYellow': 'بطاقات صفراء', 'cardsSecondYellow': 'بطاقات صفراء ثانية',
      'passesAccuracy': 'دقة التمرير', 'passesSuccessful': 'تمريرات ناجحة', 'passesFailed': 'تمريرات خاطئة',
      'passesTotal': 'إجمالي التمريرات', 'passesKey': 'تمريرات مفتاحية',
      'penaltiesScored': 'ركلات جزاء مسجلة', 'penaltiesMissed': 'ركلات جزاء ضائعة', 'penaltiesTotal': 'ركلات جزاء',
      'penaltiesAccuracy': 'دقة ركلات الجزاء', 'shotsOnTarget': 'تسديدات على المرمى',
      'shotsOffTarget': 'تسديدات خارج المرمى', 'shotsTotal': 'إجمالي التسديدات', 'shotsAccuracy': 'دقة التسديد',
      'expectedGoals': 'الأهداف المتوقعة', 'expectedAssists': 'التمريرات الحاسمة المتوقعة',
      'expectedGoalsOnTarget': 'الأهداف المتوقعة على المرمى',
      'expectedGoalsOnTargetConceded': 'الأهداف المتوقعة المستقبلة على المرمى',
      'expectedGoalsPrevented': 'أهداف منعها الحارس',
    };
    final available = labels.entries.where((entry) => stats[entry.key] != null).toList();
    if (available.isEmpty) return const Text('لا توجد إحصائيات تفصيلية لهذا اللاعب في المباراة.', style: TextStyle(color: cMuted, fontSize: 10));
    return Wrap(spacing: 7, runSpacing: 7, children: available.map((entry) => Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: cPanel2,
      side: const BorderSide(color: cLine),
      label: Text('${entry.value}: ${stats[entry.key]}', style: const TextStyle(fontSize: 9)),
    )).toList());
  }

  Widget _summary(MatchData m) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _infoRow('نتيجة الشوط الأول', m.halftimeScore),
    _infoRow('الجولة', m.round),
    _infoRow('الملعب', m.venue),
    _infoRow('المدينة', m.city),
    _infoRow('الحكم', m.referee),
  ]));

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: cMuted, fontSize: 12))),
      Flexible(child: Text(value.isEmpty ? 'غير متاح' : value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _bigTeam(String name, String logo) => Column(children: [
    NetworkBadge(url: logo, label: name, size: 66),
    const SizedBox(height: 9),
    Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
  ]);

  Widget _dataList(String endpoint) => FutureBuilder<List<dynamic>>(
    key: ValueKey('${widget.match.id}-$endpoint'),
    future: FootballApi.instance.fixtureData(endpoint, widget.match.id),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل التفاصيل');
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() {}));
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const EmptyPanel(title: 'التفاصيل غير متاحة', subtitle: 'هذه البطولة أو المباراة لا توفر هذه البيانات حالياً.');
      if (endpoint.endsWith('events')) return Column(children: rows.map((e) {
        final x = Map<String, dynamic>.from(e as Map);
        final time = x['time']?['elapsed']?.toString() ?? '';
        final extra = x['time']?['extra']?.toString();
        final detail = _footballText(x['detail'] ?? x['type'] ?? 'حدث');
        final player = x['player']?['name']?.toString() ?? '';
        final assist = x['assist']?['name']?.toString() ?? '';
        final team = x['team']?['name']?.toString() ?? '';
        final clock = time.isEmpty ? '—' : (extra == null ? time : '$time+$extra');
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(padding: const EdgeInsets.all(12), child: Row(children: [
          Container(width: 48, padding: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(color: cPanel2, borderRadius: BorderRadius.circular(9)), child: Text('$clock\'', textAlign: TextAlign.center, style: const TextStyle(color: cMint, fontWeight: FontWeight.w800, fontSize: 11))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(detail, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text([player, if (assist.isNotEmpty) 'صناعة: $assist', team].where((v) => v.isNotEmpty).join(' · '), style: const TextStyle(color: cMuted, fontSize: 10)),
          ])),
        ])));
      }).toList());
      if (endpoint.endsWith('lineups')) return Column(children: rows.map((e) {
        final x = Map<String, dynamic>.from(e as Map);
        final team = x['team']?['name']?.toString() ?? 'الفريق';
        final formation = x['formation']?.toString() ?? '';
        final coach = x['coach']?['name']?.toString() ?? '';
        final start = (x['startXI'] as List?) ?? [];
        final subs = (x['substitutes'] as List?) ?? [];
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(team, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('الخطة: ${formation.isEmpty ? 'غير متاحة' : formation}${coach.isEmpty ? '' : ' · $coach'}', style: const TextStyle(color: cMint, fontSize: 11)),
          const SizedBox(height: 8),
          Text('التشكيلة الأساسية (${start.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ...start.map((p) => _playerRow(p['player'] ?? {})),
          const Divider(color: cLine),
          Text('الاحتياط (${subs.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ...subs.map((p) => _playerRow(p['player'] ?? {})),
        ])));
      }).toList());
      if (endpoint.endsWith('players')) return Column(children: rows.map((e) {
        final x = Map<String, dynamic>.from(e as Map);
        final team = x['team']?['name']?.toString() ?? 'الفريق';
        final players = (x['players'] as List?) ?? const [];
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(team, style: const TextStyle(color: cMint, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...players.map((entry) {
            final player = entry['player'] ?? {};
            final statsList = (entry['statistics'] as List?) ?? const [];
            final stats = statsList.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(statsList.first as Map);
            final games = stats['games'] ?? {};
            final goals = stats['goals'] ?? {};
            final passes = stats['passes'] ?? {};
            final shots = stats['shots'] ?? {};
            final minutes = games['minutes']?.toString() ?? '—';
            final totalGoals = goals['total']?.toString() ?? '0';
            final assists = goals['assists']?.toString() ?? '0';
            final shotCount = shots['total']?.toString() ?? '—';
            final passCount = passes['total']?.toString() ?? '—';
            return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_mapText(player['name'], 'لاعب'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                Text('${minutes} د · ${totalGoals} هدف · ${assists} صناعة · ${shotCount} تسديدة · ${passCount} تمريرة', style: const TextStyle(color: cMuted, fontSize: 9)),
              ])),
              Text(_mapText(games['rating'], ''), style: const TextStyle(color: cMint, fontSize: 11, fontWeight: FontWeight.w800)),
            ]));
          }),
        ])));
      }).toList());
      return Column(children: rows.map((e) {
        final x = Map<String, dynamic>.from(e as Map);
        final team = x['team']?['name']?.toString() ?? 'الفريق';
        final stats = (x['statistics'] as List?) ?? [];
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(team, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...stats.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
            Expanded(child: Text(_footballText(s['type']), style: const TextStyle(fontSize: 11, color: cMuted))),
            Text(_mapText(s['value']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ]))),
        ])));
      }).toList());
    },
  );

  Widget _headToHead(MatchData m) => FutureBuilder<List<dynamic>>(
    key: ValueKey('h2h-${m.homeId}-${m.awayId}'),
    future: FootballApi.instance.headToHead(m.homeId, m.awayId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل المواجهات');
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() {}));
      final rows = snapshot.data ?? const [];
      if (rows.isEmpty) return const EmptyPanel(title: 'لا توجد مواجهات سابقة', subtitle: 'لم يعثر مزود البيانات على نتائج سابقة متاحة للفريقين.');
      return Column(children: rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: MatchTile(match: MatchData(Map<String, dynamic>.from(row as Map))),
      )).toList());
    },
  );

  Widget _playerRow(dynamic player) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(_mapText(player['number'], ''), style: const TextStyle(color: cMint, fontSize: 11)),
      const SizedBox(width: 9),
      Expanded(child: Text(_mapText(player['name']), style: const TextStyle(fontSize: 11))),
      Text(_footballText(player['pos']), style: const TextStyle(color: cMuted, fontSize: 10)),
    ]),
  );
}

// ---------- البطولات والترتيب والهدافون وصناعة الأهداف ----------
class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});
  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  late Future<List<dynamic>> _leagues;
  int _season = ApiConfig.currentSeason;
  List<int> _seasonOptions = ApiConfig.requestedSeasons;
  int _mode = 0;
  int? _selectedLeagueId;
  bool _useHighlightly = ApiConfig.isHighlightlyConfigured;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  void _loadLeagues() {
    _selectedLeagueId = null;
    _leagues = _loadAvailableSeasonsAndLeagues();
  }

  Future<List<dynamic>> _loadAvailableSeasonsAndLeagues() async {
    try {
      final available = await FootballApi.instance.availableSeasons();
      final current = ApiConfig.currentSeason;
      final relevant = available
          .where((year) => year == current || year == current + 1)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      // Keep 2026 and 2027 available as requested, even if the provider
      // has not published one of them globally yet. The selected league
      // endpoint will report plan/coverage restrictions precisely.
      _seasonOptions = relevant.isNotEmpty
          ? relevant
          : ApiConfig.requestedSeasons;
      if (!_seasonOptions.contains(_season)) {
        _season = _seasonOptions.contains(current)
            ? current
            : _seasonOptions.first;
      }
    } catch (_) {
      // If the season-list endpoint is unavailable or quota-limited,
      // keep the current + next season choices and try the requested season.
      _seasonOptions = ApiConfig.requestedSeasons;
      if (!_seasonOptions.contains(_season)) _season = ApiConfig.currentSeason;
    }
    return FootballApi.instance.leagues(season: _season);
  }

  String _coverageKey() => switch (_mode) {
        0 => 'standings',
        1 => 'top_scorers',
        _ => 'top_assists',
      };

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const SectionHeading('البطولات', subtitle: 'الدوريات الكبرى والبطولات القارية'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ChoiceChip(label: const Text('API-Football'), selected: !_useHighlightly, onSelected: (_) => setState(() => _useHighlightly = false), selectedColor: cMint.withValues(alpha: .16), labelStyle: TextStyle(color: !_useHighlightly ? cMint : cMuted))),
            const SizedBox(width: 8),
            Expanded(child: ChoiceChip(label: const Text('Highlightly'), selected: _useHighlightly, onSelected: (_) => setState(() => _useHighlightly = true), selectedColor: cMint.withValues(alpha: .16), labelStyle: TextStyle(color: _useHighlightly ? cMint : cMuted))),
          ]),
          const SizedBox(height: 10),
          if (_useHighlightly) const HighlightlyStandingsSection(),
          Panel(
            padding: const EdgeInsets.all(11),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(LucideIcons.info, color: cMint, size: 17),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'المواسم والإحصائيات المتاحة تعتمد على خطة مزوّد البيانات وتغطية كل بطولة.',
                style: const TextStyle(color: cMuted, fontSize: 10, height: 1.6),
              )),
            ]),
          ),
          const SizedBox(height: 12),
          if (!_useHighlightly) FutureBuilder<List<dynamic>>(
            future: _leagues,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingPanel(label: 'جاري تحميل الدوريات المتاحة لهذا الموسم');
              }
              if (snapshot.hasError) {
                return ErrorPanel(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(_loadLeagues),
                );
              }
              final all = (snapshot.data ?? const <dynamic>[])
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
              if (all.isEmpty) {
                return const EmptyPanel(
                  title: 'لا توجد دوريات متاحة لهذا الموسم',
                  subtitle: 'تحقق من مفتاح API-Football وخطة الحساب، أو جرّب موسماً آخر من المواسم المجانية.',
                );
              }

              Map<String, dynamic> selected;
              final selectedIndex = all.indexWhere(
                (e) => (e['league']?['id'] as num?)?.toInt() == _selectedLeagueId,
              );
              if (selectedIndex >= 0) {
                selected = all[selectedIndex];
              } else {
                selected = all.first;
                _selectedLeagueId = (selected['league']?['id'] as num?)?.toInt();
              }
              final league = Map<String, dynamic>.from(selected['league'] as Map);
              final leagueId = (league['id'] as num?)?.toInt() ?? 0;
              final coverageOk = LeagueCatalog.supports(selected, _season, _coverageKey());
              final arabicName = LeagueCatalog.displayName(selected);
              final arabicCountry = LeagueCatalog.displayCountry(selected);

              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                DropdownButtonFormField<int>(
                  value: _season,
                  dropdownColor: cPanel,
                  decoration: const InputDecoration(labelText: 'الموسم'),
                  items: _seasonOptions.map((year) => DropdownMenuItem<int>(
                    value: year,
                    child: Text('$year / ${year + 1}', style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (value) {
                    if (value == null || value == _season) return;
                    setState(() { _season = value; _loadLeagues(); });
                  },
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<int>(
                  value: leagueId == 0 ? null : leagueId,
                  isExpanded: true,
                  dropdownColor: cPanel,
                  decoration: const InputDecoration(labelText: 'اختر الدوري'),
                  items: all.map((item) {
                    final data = item['league'] as Map;
                    final itemId = (data['id'] as num?)?.toInt();
                    return DropdownMenuItem<int>(
                      value: itemId,
                      child: Text(
                        '${LeagueCatalog.displayName(item)} · ${LeagueCatalog.displayCountry(item)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).where((item) => item.value != null).toList(),
                  onChanged: (value) => setState(() => _selectedLeagueId = value),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  _modeChip('الترتيب', 0),
                  const SizedBox(width: 6),
                  _modeChip('الهدافون', 1),
                  const SizedBox(width: 6),
                  _modeChip('صناعة الأهداف', 2),
                ]),
                const SizedBox(height: 12),
                if (!coverageOk)
                  EmptyPanel(
                    title: 'هذه الإحصائية غير مغطاة',
                    subtitle: 'لا يوفر مزوّد البيانات ${_mode == 0 ? 'جدول الترتيب' : _mode == 1 ? 'قائمة الهدافين' : 'قائمة صانعي الأهداف'} لهذا الدوري في موسم $_season.',
                  )
                else
                  _standingsData(leagueId, _season, arabicName),
              ]);
            },
          ),
        ],
      );

  Widget _modeChip(String title, int value) => Expanded(
        child: InkWell(
          onTap: () => setState(() => _mode = value),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            decoration: BoxDecoration(
              color: _mode == value ? cMint.withValues(alpha: .13) : cPanel,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _mode == value ? cMint : cLine),
            ),
            child: Text(title, textAlign: TextAlign.center,
              style: TextStyle(color: _mode == value ? cMint : cMuted, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ),
      );

  Widget _standingsData(int id, int season, String leagueName) => FutureBuilder<List<dynamic>>(
        key: ValueKey('$id-$season-$_mode'),
        future: _mode == 0
            ? FootballApi.instance.standings(id, season)
            : (_mode == 1
                ? FootballApi.instance.topScorers(id, season)
                : FootballApi.instance.topAssists(id, season)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingPanel(label: 'جاري تحميل بيانات الدوري');
          }
          if (snapshot.hasError) {
            return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() {}));
          }
          final response = snapshot.data ?? const <dynamic>[];
          if (response.isEmpty) {
            return const EmptyPanel(
              title: 'لا توجد بيانات متاحة',
              subtitle: 'قد لا تتوفر هذه الإحصائية لهذا الدوري أو الموسم في خطة حسابك.',
            );
          }
          if (_mode == 0) return _buildAllStandings(response, leagueName);
          return _buildPlayerRanking(response);
        },
      );

  Widget _buildAllStandings(List<dynamic> response, String leagueName) {
    final first = response.first;
    if (first is! Map) {
      return const EmptyPanel(title: 'استجابة غير مكتملة', subtitle: 'لم يصل جدول الترتيب بالشكل المتوقع.');
    }
    final league = first['league'];
    final rawGroups = league is Map ? league['standings'] : null;
    if (rawGroups is! List || rawGroups.isEmpty) {
      return const EmptyPanel(title: 'جدول الترتيب غير متاح', subtitle: 'لا يوفر مزوّد البيانات ترتيب هذا الدوري لهذا الموسم.');
    }
    final groups = rawGroups.whereType<List>().toList();
    if (groups.isEmpty) {
      return const EmptyPanel(title: 'جدول الترتيب غير متاح', subtitle: 'لا توجد مجموعات ترتيب منشورة.');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${ArabicFootball.league(leagueName)} · $_season / ${_season + 1}', style: const TextStyle(color: cMint, fontSize: 12, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      ...groups.map((group) => _standingsTable(group)),
    ]);
  }

  Widget _standingsTable(List<dynamic> rows) {
    final groupName = rows.isNotEmpty && rows.first is Map ? (rows.first as Map)['group']?.toString() : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
        child: Column(children: [
          if (groupName != null && groupName.isNotEmpty)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Align(alignment: Alignment.centerRight, child: Text(_footballText(groupName), style: const TextStyle(color: cMint, fontSize: 11, fontWeight: FontWeight.w800)))),
          Row(children: const [
            SizedBox(width: 20, child: Text('#', style: TextStyle(color: cMuted, fontSize: 9))),
            Expanded(child: Text('الفريق', style: TextStyle(color: cMuted, fontSize: 9))),
            SizedBox(width: 25, child: Text('لعب', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
            SizedBox(width: 22, child: Text('ف', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
            SizedBox(width: 22, child: Text('ت', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
            SizedBox(width: 22, child: Text('خ', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
            SizedBox(width: 28, child: Text('+/−', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
            SizedBox(width: 28, child: Text('نقاط', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
          ]),
          const Divider(color: cLine),
          ...rows.whereType<Map>().map((row) {
            final item = Map<String, dynamic>.from(row);
            final team = item['team'] is Map ? Map<String, dynamic>.from(item['team']) : <String, dynamic>{};
            final all = item['all'] is Map ? Map<String, dynamic>.from(item['all']) : <String, dynamic>{};
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(children: [
                SizedBox(width: 20, child: Text(_mapText(item['rank']), style: const TextStyle(color: cMint, fontWeight: FontWeight.w800, fontSize: 10))),
                Expanded(child: Row(children: [
                  NetworkBadge(url: team['logo']?.toString() ?? '', label: team['name']?.toString() ?? '', size: 23),
                  const SizedBox(width: 5),
                  Expanded(child: Text(ArabicFootball.team(_mapText(team['name'])), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                ])),
                SizedBox(width: 25, child: Text(_mapText(all['played']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                SizedBox(width: 22, child: Text(_mapText(all['win']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                SizedBox(width: 22, child: Text(_mapText(all['draw']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                SizedBox(width: 22, child: Text(_mapText(all['lose']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                SizedBox(width: 28, child: Text(_mapText(item['goalsDiff']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                SizedBox(width: 28, child: Text(_mapText(item['points']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildPlayerRanking(List<dynamic> response) {
    final entries = response.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    double score(Map<String, dynamic> row) {
      final stats = _firstOrEmpty(row['statistics']);
      final goals = stats is Map ? stats['goals'] : null;
      final raw = _mode == 1 && goals is Map ? goals['total'] : (goals is Map ? goals['assists'] : null);
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? -1;
    }
    entries.sort((a, b) => score(b).compareTo(score(a)));
    if (entries.isEmpty) return const EmptyPanel(title: 'لا توجد إحصائيات لاعبين', subtitle: 'لم تصل قائمة اللاعبين لهذا الموسم.');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_mode == 1 ? 'ترتيب الهدافين · $_season / ${_season + 1}' : 'ترتيب صانعي الأهداف · $_season / ${_season + 1}', style: const TextStyle(color: cMint, fontSize: 12, fontWeight: FontWeight.w800))),
      ...entries.take(30).toList().asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final row = entry.value;
        final player = row['player'] is Map ? Map<String, dynamic>.from(row['player']) : <String, dynamic>{};
        final stats = _firstOrEmpty(row['statistics']);
        final stat = stats is Map ? stats : <String, dynamic>{};
        final goals = stat['goals'] is Map ? stat['goals'] as Map : <String, dynamic>{};
        final team = stat['team'] is Map ? stat['team'] as Map : <String, dynamic>{};
        final rawMetric = _mode == 1 ? goals['total'] : goals['assists'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Panel(child: Row(children: [
            SizedBox(width: 22, child: Text('$rank', style: const TextStyle(color: cMint, fontWeight: FontWeight.w900))),
            NetworkBadge(url: player['photo']?.toString() ?? '', label: player['name']?.toString() ?? '', size: 42),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_mapText(player['name']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              Text(ArabicFootball.team(_mapText(team['name'])), style: const TextStyle(color: cMuted, fontSize: 10)),
            ])),
            Text(_mapText(rawMetric, '0'), style: const TextStyle(color: cMint, fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Text(_mode == 1 ? 'هدف' : 'تمريرة حاسمة', style: const TextStyle(color: cMuted, fontSize: 9)),
          ])),
        );
      }),
    ]);
  }
}

class HighlightlyStandingsSection extends StatefulWidget {
  const HighlightlyStandingsSection({super.key});

  @override
  State<HighlightlyStandingsSection> createState() => _HighlightlyStandingsSectionState();
}

class _HighlightlyStandingsSectionState extends State<HighlightlyStandingsSection> {
  late Future<List<Map<String, dynamic>>> _leaguesFuture;
  int? _selectedLeagueId;
  int? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _leaguesFuture = HighlightlyApi.instance.allLeagues();
  }

  void _reload() {
    setState(() => _leaguesFuture = HighlightlyApi.instance.allLeagues());
  }

  @override
  Widget build(BuildContext context) {
    if (!HighlightlyApi.instance.isConfigured) {
      return const EmptyPanel(
        title: 'Highlightly غير مفعّل بعد',
        subtitle: 'أضف مفتاح HIGHLIGHTLY_API_KEY إلى GitHub Secrets ثم أعد بناء التطبيق. سيبقى API-Football متاحاً كما هو.',
      );
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _leaguesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل بطولات Highlightly');
        if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: _reload);

        final all = (snapshot.data ?? const <Map<String, dynamic>>[]).where((item) {
          final country = item['country'] is Map ? (item['country']['name']?.toString() ?? '') : '';
          final name = item['name']?.toString() ?? '';
          return LeagueCatalog.isAllowedHighlightly(country, name);
        }).toList();
        if (all.isEmpty) {
          return const EmptyPanel(title: 'لم تصل بطولات مطابقة', subtitle: 'تحقق من اشتراك Highlightly أو راجع قائمة البطولات التي يعيدها الحساب.');
        }
        all.sort((a, b) {
          final aCountry = a['country'] is Map ? a['country']['name']?.toString() ?? '' : '';
          final bCountry = b['country'] is Map ? b['country']['name']?.toString() ?? '' : '';
          final aWrapper = <String, dynamic>{'country': aCountry, 'league': <String, dynamic>{'name': a['name']}};
          final bWrapper = <String, dynamic>{'country': bCountry, 'league': <String, dynamic>{'name': b['name']}};
          final priority = LeagueCatalog.priority(aWrapper).compareTo(LeagueCatalog.priority(bWrapper));
          if (priority != 0) return priority;
          return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
        });

        var selected = all.first;
        for (final item in all) {
          if ((item['id'] as num?)?.toInt() == _selectedLeagueId) {
            selected = item;
            break;
          }
        }
        final leagueId = (selected['id'] as num?)?.toInt() ?? 0;
        final seasonsRaw = selected['seasons'] is List ? selected['seasons'] as List : const [];
        final seasons = seasonsRaw.whereType<Map>()
            .map((item) => (item['season'] as num?)?.toInt())
            .whereType<int>().toSet().toList()
          ..sort((a, b) => b.compareTo(a));
        final season = seasons.contains(_selectedSeason)
            ? _selectedSeason!
            : (seasons.isNotEmpty ? seasons.first : 0);
        final countryName = selected['country'] is Map ? selected['country']['name']?.toString() ?? '' : '';
        final displayLeague = ArabicFootball.league(selected['name']?.toString() ?? '', countryName);

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Panel(padding: const EdgeInsets.all(10), child: Row(children: [
            const Icon(LucideIcons.info, color: cMint, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('المواسم أدناه هي المواسم التي أعادها Highlightly لهذه البطولة تحديداً، ولا نفترض توفر 2026 أو 2027 ما لم تظهرا في القائمة.', style: const TextStyle(color: cMuted, fontSize: 10, height: 1.5))),
          ])),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: leagueId > 0 ? leagueId : null,
            isExpanded: true,
            dropdownColor: cPanel,
            decoration: const InputDecoration(labelText: 'اختر البطولة'),
            items: all.map((item) {
              final id = (item['id'] as num?)?.toInt();
              final country = item['country'] is Map ? item['country']['name']?.toString() ?? '' : '';
              final name = ArabicFootball.league(item['name']?.toString() ?? '', country);
              return DropdownMenuItem<int>(value: id, child: Text('$name · ${ArabicFootball.country(country)}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)));
            }).where((item) => item.value != null).toList(),
            onChanged: (value) => setState(() { _selectedLeagueId = value; _selectedSeason = null; }),
          ),
          const SizedBox(height: 9),
          if (seasons.isEmpty)
            const EmptyPanel(title: 'لا توجد مواسم منشورة', subtitle: 'لم يعرض Highlightly أي موسم لهذه البطولة ضمن حسابك حالياً.')
          else ...[
            DropdownButtonFormField<int>(
              value: season,
              dropdownColor: cPanel,
              decoration: const InputDecoration(labelText: 'الموسم المتاح'),
              items: seasons.map((year) => DropdownMenuItem<int>(value: year, child: Text('$year / ${year + 1}'))).toList(),
              onChanged: (value) => setState(() => _selectedSeason = value),
            ),
            const SizedBox(height: 12),
            _highlightlyTable(leagueId, season, displayLeague),
          ],
        ]);
      },
    );
  }

  Widget _highlightlyTable(int leagueId, int season, String leagueName) => FutureBuilder<List<Map<String, dynamic>>>(
    key: ValueKey('highlightly-standing-$leagueId-$season'),
    future: HighlightlyApi.instance.standings(leagueId, season),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل جدول الترتيب');
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() {}));
      final groups = snapshot.data ?? const <Map<String, dynamic>>[];
      if (groups.isEmpty) return const EmptyPanel(title: 'جدول الترتيب غير متاح', subtitle: 'الموسم موجود في قائمة البطولة، لكن مزوّد البيانات لم ينشر ترتيباً له بعد أو أن تغطيته غير متاحة.');
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$leagueName · $season / ${season + 1}', style: const TextStyle(color: cMint, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...groups.map((group) {
          final rows = group['standings'] is List ? group['standings'] as List : const [];
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: Panel(padding: const EdgeInsets.all(10), child: Column(children: [
            if (_mapText(group['name'], '').isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Align(alignment: Alignment.centerRight, child: Text(ArabicFootball.text(group['name']), style: const TextStyle(color: cMint, fontSize: 11, fontWeight: FontWeight.w800)))),
            Row(children: const [
              SizedBox(width: 22, child: Text('#', style: TextStyle(color: cMuted, fontSize: 9))),
              Expanded(child: Text('الفريق', style: TextStyle(color: cMuted, fontSize: 9))),
              SizedBox(width: 28, child: Text('لعب', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
              SizedBox(width: 24, child: Text('ف', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
              SizedBox(width: 24, child: Text('ت', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
              SizedBox(width: 24, child: Text('خ', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
              SizedBox(width: 34, child: Text('له/عليه', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 8))),
              SizedBox(width: 30, child: Text('نقاط', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9))),
            ]),
            const Divider(color: cLine),
            ...rows.whereType<Map>().map((row) {
              final team = row['team'] is Map ? Map<String, dynamic>.from(row['team']) : <String, dynamic>{};
              final total = row['total'] is Map ? Map<String, dynamic>.from(row['total']) : <String, dynamic>{};
              final scored = total['scoredGoals'] ?? 0;
              final conceded = total['receivedGoals'] ?? 0;
              return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
                SizedBox(width: 22, child: Text(_mapText(row['position']), style: const TextStyle(color: cMint, fontWeight: FontWeight.w900, fontSize: 10))),
                Expanded(child: Row(children: [
                  NetworkBadge(url: _mapText(team['logo'], ''), label: _mapText(team['name'], ''), size: 22),
                  const SizedBox(width: 5),
                  Expanded(child: Text(ArabicFootball.team(_mapText(team['name'], 'الفريق')), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                ])),
                SizedBox(width: 28, child: Text(_mapText(total['games']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                SizedBox(width: 24, child: Text(_mapText(total['wins']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                SizedBox(width: 24, child: Text(_mapText(total['draws']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                SizedBox(width: 24, child: Text(_mapText(total['loses']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                SizedBox(width: 34, child: Text('$scored/$conceded', textAlign: TextAlign.center, style: const TextStyle(fontSize: 8))),
                SizedBox(width: 30, child: Text(_mapText(row['points']), textAlign: TextAlign.center, style: const TextStyle(color: cMint, fontSize: 10, fontWeight: FontWeight.w900))),
              ]));
            }),
          ])));
        }),
      ]);
    },
  );
}

// ---------- News and official sources ----------
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});
  static const sources = [
    ('FIFA', 'أخبار الاتحاد الدولي لكرة القدم', 'https://www.fifa.com/news'),
    ('UEFA', 'أخبار ومسابقات كرة القدم الأوروبية', 'https://www.uefa.com/news/'),
    ('BBC Sport', 'أخبار كرة القدم العالمية', 'https://www.bbc.com/sport/football'),
    ('ESPN', 'أخبار وتقارير كرة القدم', 'https://www.espn.com/soccer/'),
    ('AFC', 'أخبار كرة القدم الآسيوية', 'https://www.the-afc.com/en/more/news.html'),
  ];
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
    const SectionHeading('أخبار كرة القدم', subtitle: 'مصادر رسمية لقراءة آخر الأخبار'),
    const SizedBox(height: 12),
    const Panel(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(LucideIcons.info, color: cMint, size: 19), SizedBox(width: 10), Expanded(child: Text('هذه النسخة تفتح مواقع الناشرين مباشرة ولا تنسخ أخبارهم أو صورهم. سنضيف موجزاً داخلياً فقط عند اعتماد مصدر يسمح صراحة بإعادة عرض الأخبار داخل التطبيق.', style: TextStyle(color: cMuted, fontSize: 11, height: 1.7)))])),
    const SizedBox(height: 12),
    ...sources.map((s) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Panel(onTap: () => _open(context, s.$3), child: Row(children: [Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: cPanel2, borderRadius: BorderRadius.circular(12)), child: Text(s.$1.substring(0, 1), style: const TextStyle(color: cMint, fontWeight: FontWeight.w900))), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w800)), Text(s.$2, style: const TextStyle(color: cMuted, fontSize: 10))])), const Icon(LucideIcons.externalLink, size: 17, color: cMint)])))),
  ]);

  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
    }
  }
}

// ---------- Search, player profile and team profile ----------
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  int _mode = 0;
  Future<List<dynamic>>? _future;
  String _query = '';

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _search() {
    final q = _controller.text.trim();
    if (q.length < (_mode == 0 ? 4 : 3)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_mode == 0 ? 'اكتب أربعة أحرف على الأقل للبحث عن لاعب' : 'اكتب ثلاثة أحرف على الأقل للبحث عن نادٍ')));
      return;
    }
    setState(() {
      _query = q;
      _future = _mode == 0 ? FootballApi.instance.searchPlayers(q, ApiConfig.currentSeason) : FootballApi.instance.searchTeams(q);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('البحث', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [_modeChip('اللاعبون', 0), const SizedBox(width: 8), _modeChip('الأندية', 1)]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: TextField(controller: _controller, textInputAction: TextInputAction.search, onSubmitted: (_) => _search(), decoration: InputDecoration(hintText: _mode == 0 ? 'اسم اللاعب (4 أحرف على الأقل)' : 'اسم النادي (3 أحرف على الأقل)', prefixIcon: const Icon(LucideIcons.search, color: cMuted)))), const SizedBox(width: 8), FilledButton(onPressed: _search, style: FilledButton.styleFrom(backgroundColor: cMint, foregroundColor: cBg, padding: const EdgeInsets.all(15)), child: const Icon(LucideIcons.search))]),
      const SizedBox(height: 14),
      if (_future == null) const EmptyPanel(title: 'ابحث عن لاعب أو نادٍ', subtitle: 'ستظهر النتائج الحقيقية القادمة من API-Football هنا.'),
      if (_future != null) FutureBuilder<List<dynamic>>(future: _future, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري البحث');
        if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: _search);
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) return EmptyPanel(title: 'لا توجد نتائج لـ $_query', subtitle: 'جرّب كتابة الاسم بطريقة أخرى.');
        if (_mode == 0) return Column(children: rows.take(30).map((r) {
          final player = r['player'] ?? {};
          final stats = _firstOrEmpty(r['statistics']);
          final team = stats['team'] ?? {};
          final id = (player['id'] as num?)?.toInt() ?? 0;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerProfileScreen(playerId: id, name: _mapText(player['name'])))), child: Row(children: [NetworkBadge(url: player['photo']?.toString() ?? '', label: player['name']?.toString() ?? '', size: 44), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_mapText(player['name']), style: const TextStyle(fontWeight: FontWeight.w800)), Text(_mapText(team['name']), style: const TextStyle(color: cMuted, fontSize: 10))])), const Icon(LucideIcons.chevronLeft, color: cMuted, size: 17)])));
        }).toList());
        return Column(children: rows.take(30).map((r) {
          final team = r['team'] ?? {};
          final venue = r['venue'] ?? {};
          final id = (team['id'] as num?)?.toInt() ?? 0;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamProfileScreen(teamId: id, name: _mapText(team['name'])))), child: Row(children: [NetworkBadge(url: team['logo']?.toString() ?? '', label: team['name']?.toString() ?? '', size: 44), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_mapText(team['name']), style: const TextStyle(fontWeight: FontWeight.w800)), Text('${_mapText(team['country'], '')} · ${_mapText(venue['name'], '')}', style: const TextStyle(color: cMuted, fontSize: 10))])), const Icon(LucideIcons.chevronLeft, color: cMuted, size: 17)])));
        }).toList());
      }),
    ]),
  );

  Widget _modeChip(String title, int mode) => Expanded(child: InkWell(onTap: () => setState(() { _mode = mode; _future = null; }), child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: _mode == mode ? cMint.withValues(alpha: .13) : cPanel, borderRadius: BorderRadius.circular(11), border: Border.all(color: _mode == mode ? cMint : cLine)), child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: _mode == mode ? cMint : cMuted, fontWeight: FontWeight.w700)))));
}

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key, required this.playerId, required this.name});
  final int playerId;
  final String name;
  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  late Future<Map<String, dynamic>> _future;
  late Future<List<dynamic>> _transfers;
  @override
  void initState() {
    super.initState();
    _future = FootballApi.instance.get('players', {'id': '${widget.playerId}', 'season': '${ApiConfig.currentSeason}'});
    _transfers = FootballApi.instance.get('transfers', {'player': '${widget.playerId}'}).then((v) => (v['response'] as List?) ?? const []);
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('ملف اللاعب', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), body: FutureBuilder<Map<String, dynamic>>(future: _future, builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cMint));
    if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(16), child: ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() => _future = FootballApi.instance.get('players', {'id': '${widget.playerId}', 'season': '${ApiConfig.currentSeason}'}))));
    final rows = (snapshot.data?['response'] as List?) ?? [];
    if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: EmptyPanel(title: 'ملف اللاعب غير متاح', subtitle: 'لا توجد إحصائيات لهذا اللاعب في الموسم الحالي.'));
    final row = rows.first;
    final p = row['player'] ?? {};
    final stats = _firstOrEmpty(row['statistics']);
    final team = stats['team'] ?? {};
    final games = stats['games'] ?? {};
    final goals = stats['goals'] ?? {};
    return ListView(padding: const EdgeInsets.all(16), children: [
      Panel(child: Column(children: [NetworkBadge(url: p['photo']?.toString() ?? '', label: _mapText(p['name']), size: 90), const SizedBox(height: 10), Text(_mapText(p['name']), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), Text('${_mapText(p['nationality'], '')} · ${_mapText(p['age'], '')} سنة', style: const TextStyle(color: cMuted, fontSize: 11)), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_metric('الفريق', _mapText(team['name'])), _metric('المركز', _footballText(games['position'])), _metric('الرقم', _mapText(games['number']))])])),
      const SizedBox(height: 12),
      Row(children: [_metricPanel('المشاركات', _mapText(games['appearences'])), const SizedBox(width: 8), _metricPanel('الأهداف', _mapText(goals['total'])), const SizedBox(width: 8), _metricPanel('الصناعة', _mapText(goals['assists']))]),
      const SizedBox(height: 18),
      const SectionHeading('تاريخ الانتقالات'), const SizedBox(height: 9),
      FutureBuilder<List<dynamic>>(future: _transfers, builder: (context, ts) {
        if (ts.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل الانتقالات');
        if (ts.hasError) return ErrorPanel(message: ts.error.toString(), onRetry: () => setState(() => _transfers = FootballApi.instance.get('transfers', {'player': '${widget.playerId}'}).then((v) => (v['response'] as List?) ?? const [])));
        final transfers = ts.data ?? [];
        if (transfers.isEmpty) return const EmptyPanel(title: 'لا توجد انتقالات مسجلة', subtitle: 'لم يرجع المصدر سجلاً للانتقالات.');
        return Column(children: transfers.map((t) { final x = t['transfers'] as List? ?? []; return Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_mapText(t['player']?['name']), style: const TextStyle(fontWeight: FontWeight.w800)), ...x.map((v) => Text('${_mapText(v['date'])} · ${_footballText(v['type'])} · ${_mapText(v['teams']?['out']?['name'])} ← ${_mapText(v['teams']?['in']?['name'])}', style: const TextStyle(color: cMuted, fontSize: 10)))]))); }).toList());
      }),
    ]);
  }));

  Widget _metric(String title, String value) => Column(children: [Text(title, style: const TextStyle(color: cMuted, fontSize: 9)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))]);
  Widget _metricPanel(String title, String value) => Expanded(child: Panel(padding: const EdgeInsets.all(12), child: Column(children: [Text(title, style: const TextStyle(color: cMuted, fontSize: 10)), const SizedBox(height: 5), Text(value, style: const TextStyle(color: cMint, fontSize: 18, fontWeight: FontWeight.w900))])));
}

class TeamProfileScreen extends StatefulWidget {
  const TeamProfileScreen({super.key, required this.teamId, required this.name});
  final int teamId;
  final String name;
  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen> {
  late Future<Map<String, dynamic>> _team;
  late Future<List<dynamic>> _players;
  @override
  void initState() { super.initState(); _team = FootballApi.instance.get('teams', {'id': '${widget.teamId}'}); _players = FootballApi.instance.teamPlayers(widget.teamId, ApiConfig.currentSeason); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('ملف النادي', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), body: ListView(padding: const EdgeInsets.all(16), children: [
    FutureBuilder<Map<String, dynamic>>(future: _team, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل بيانات النادي');
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() => _team = FootballApi.instance.get('teams', {'id': '${widget.teamId}'})));
      final rows = (snapshot.data?['response'] as List?) ?? [];
      if (rows.isEmpty) return EmptyPanel(title: widget.name, subtitle: 'تفاصيل النادي غير متاحة.');
      final t = rows.first['team'] ?? {}; final venue = rows.first['venue'] ?? {};
      return Panel(child: Column(children: [NetworkBadge(url: t['logo']?.toString() ?? '', label: _mapText(t['name']), size: 76), const SizedBox(height: 8), Text(_mapText(t['name']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text('${_mapText(t['country'], '')} · تأسس ${_mapText(t['founded'], '')}', style: const TextStyle(color: cMuted, fontSize: 11)), const SizedBox(height: 9), Text('الملعب: ${_mapText(venue['name'])}', style: const TextStyle(fontSize: 11))]));
    }),
    const SizedBox(height: 16), const SectionHeading('قائمة اللاعبين'), const SizedBox(height: 10),
    FutureBuilder<List<dynamic>>(future: _players, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل قائمة اللاعبين');
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() => _players = FootballApi.instance.teamPlayers(widget.teamId, ApiConfig.currentSeason)));
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const EmptyPanel(title: 'قائمة اللاعبين غير متاحة', subtitle: 'قد لا تكون تغطية الموسم الحالي متاحة بعد.');
      return Column(children: rows.map((r) { final p = r['player'] ?? {}; final id = (p['id'] as num?)?.toInt() ?? 0; return Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerProfileScreen(playerId: id, name: _mapText(p['name'])))), child: Row(children: [NetworkBadge(url: p['photo']?.toString() ?? '', label: _mapText(p['name']), size: 38), const SizedBox(width: 10), Expanded(child: Text(_mapText(p['name']), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))), Text(_mapText(p['nationality'], ''), style: const TextStyle(color: cMuted, fontSize: 10)), const SizedBox(width: 7), const Icon(LucideIcons.chevronLeft, color: cMuted, size: 16)]))); }).toList());
    }),
  ]));
}

// ---------- More / official sources / settings ----------
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  static const providers = [
    ('FIFA+', 'محتوى ومباريات مختارة وفق التوفر الجغرافي', 'https://www.fifa.com/fifaplus/'),
    ('UEFA.tv', 'محتوى ومقاطع رسمية من مسابقات UEFA', 'https://www.uefa.tv/'),
    ('YouTube', 'قنوات الأندية والبطولات الرسمية', 'https://www.youtube.com/'),
    ('الجزيرة مباشر', 'الموقع الرسمي للبث الإخباري', 'https://www.aljazeera.net/live'),
    ('France 24 عربي', 'البث والمحتوى الإخباري الرسمي', 'https://www.france24.com/ar/'),
  ];
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
    const SectionHeading('المزيد', subtitle: 'خدمات ومصادر DFISH LIVE'),
    const SizedBox(height: 14),
    _MoreTile(icon: LucideIcons.newspaper, title: 'أخبار كرة القدم', subtitle: 'مصادر رياضية رسمية وموثوقة', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen()))),
    _MoreTile(icon: LucideIcons.search, title: 'بحث اللاعبين والأندية', subtitle: 'ابحث بالاسم وافتح صفحة اللاعب أو النادي', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
    _MoreTile(icon: LucideIcons.tv, title: 'التلفزيون الرسمي', subtitle: 'مصادر القنوات الرسمية والمرخصة', onTap: () => _open(context, 'https://www.fifa.com/fifaplus/')),
    _MoreTile(icon: LucideIcons.clapperboard, title: 'الأفلام والمسلسلات', subtitle: 'كتالوج التشغيل يحتاج مصدراً مرخصاً مستقلاً', onTap: () => _showInfo(context)),
    _MoreTile(icon: LucideIcons.settings, title: 'الإعدادات', subtitle: 'اللغة والمظهر ومعلومات التطبيق', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
    const SizedBox(height: 18),
    const SectionHeading('مصادر محتوى رسمية', subtitle: 'اضغط لفتح الموقع الرسمي'),
    const SizedBox(height: 10),
    ...providers.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(onTap: () => _open(context, p.$3), child: Row(children: [const Icon(LucideIcons.playCircle, color: cMint), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w800)), Text(p.$2, style: const TextStyle(color: cMuted, fontSize: 10))])), const Icon(LucideIcons.externalLink, color: cMuted, size: 16)])))),
    const SizedBox(height: 10),
    const Text('التطبيق لا يعيد بث محتوى الغير. توفر المحتوى قد يختلف حسب بلد المستخدم وشروط كل منصة.', style: TextStyle(color: cMuted, fontSize: 10, height: 1.6)),
  ]);

  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
    }
  }

  static void _showInfo(BuildContext context) => showDialog<void>(context: context, builder: (_) => AlertDialog(backgroundColor: cPanel, title: const Text('الأفلام والمسلسلات'), content: const Text('سيتم تفعيل التشغيل عند ربط مصدر كتالوج ومقاطع يملك حقوق العرض والتضمين. لا يعرض التطبيق روابط فيديو غير موثقة.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))]));
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _taps = 0;
  DateTime? _lastTap;
  void _versionTap() {
    final now = DateTime.now();
    if (_lastTap == null || now.difference(_lastTap!) > const Duration(seconds: 8)) _taps = 0;
    _lastTap = now;
    _taps++;
    if (_taps >= 10) {
      _taps = 0;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAccessScreen()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الإعدادات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Panel(child: Row(children: [Icon(LucideIcons.globe, color: cMint), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('اللغة', style: TextStyle(fontWeight: FontWeight.w800)), Text('العربية · RTL', style: TextStyle(color: cMuted, fontSize: 11))]))])),
      const SizedBox(height: 9),
      const Panel(child: Row(children: [Icon(LucideIcons.clock, color: cMint), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('المنطقة الزمنية', style: TextStyle(fontWeight: FontWeight.w800)), Text('اليمن · Asia/Aden (UTC+3)', style: TextStyle(color: cMuted, fontSize: 11))]))])),
      const SizedBox(height: 9),
      const Panel(child: Row(children: [Icon(LucideIcons.shieldCheck, color: cMint), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الخصوصية والأمان', style: TextStyle(fontWeight: FontWeight.w800)), Text('بيانات المباريات من API-Football، والمزامنة ولوحة الإدارة عبر Firebase.', style: TextStyle(color: cMuted, fontSize: 11))]))])),
      const SizedBox(height: 24),
      const SizedBox(height: 8),
      const Text('تطوير عبد العزيز عوض بن ثابت', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 10)),
      const Text('جميع الحقوق محفوظة © DFISH LIVE', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 9)),
      Center(child: GestureDetector(onTap: _versionTap, child: const Padding(padding: EdgeInsets.all(18), child: Text('DFISH LIVE · الإصدار 1.0.1', style: TextStyle(color: cMuted, fontSize: 10, letterSpacing: .4)))),),
    ]),
  );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(onTap: onTap, child: Row(children: [Icon(icon, color: cMint, size: 21), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(color: cMuted, fontSize: 10))])), const Icon(LucideIcons.chevronLeft, color: cMuted, size: 18)])));
}

// ---------- State panels ----------
class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Panel(child: Row(children: [const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: cMint)), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(color: cMuted, fontSize: 12)))]));
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Panel(child: Column(children: [const Icon(LucideIcons.calendarX, color: cMuted, size: 28), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: cMuted, fontSize: 11, height: 1.6))]));
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Panel(child: Column(children: [const Icon(LucideIcons.wifiOff, color: Color(0xFFFF7282), size: 25), const SizedBox(height: 8), const Text('تعذر تحميل البيانات', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: cMuted, fontSize: 10, height: 1.5)), const SizedBox(height: 10), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(LucideIcons.refreshCw, size: 16), label: const Text('إعادة المحاولة'), style: OutlinedButton.styleFrom(foregroundColor: cMint, side: const BorderSide(color: cMint)))]));
}
