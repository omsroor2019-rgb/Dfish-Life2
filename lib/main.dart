import 'dart:ui' as ui show FontFeature, TextDirection;

import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin/admin_portal.dart';
import 'streams/streams_screen.dart';
import 'services/football_api.dart';
import 'services/firebase_runtime.dart';

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
        league = json['league']?['name']?.toString() ?? 'بطولة',
        leagueLogo = json['league']?['logo']?.toString() ?? '',
        country = json['league']?['country']?.toString() ?? '',
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
        round = json['league']?['round']?.toString() ?? '';

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

  bool get isLive => const {'1H', 'HT', '2H', 'ET', 'BT', 'P', 'LIVE', 'SUSP', 'INT'}.contains(status);
  bool get isFinished => const {'FT', 'AET', 'PEN', 'AWD', 'WO'}.contains(status);
  String get score => homeGoals == null || awayGoals == null ? '—' : '$homeGoals - $awayGoals';
  String get timeLabel {
    if (isLive) return elapsed == null ? statusLong : "${elapsed!}'";
    if (isFinished) return 'انتهت';
    if (kickoff.length >= 16) return kickoff.substring(11, 16);
    return 'قريباً';
  }
}

String _mapText(dynamic value, [String fallback = '—']) => value == null || value.toString().trim().isEmpty ? fallback : value.toString();
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
              child: Image.network(url, width: size - 5, height: size - 5, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(label.isEmpty ? '?' : label.substring(0, 1), style: const TextStyle(color: cText, fontWeight: FontWeight.w700))),
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
  final _pages = const [HomeScreen(), MatchesScreen(), StandingsScreen(), StreamMatchesScreen(), MoreScreen()];
  final _titles = const ['الرئيسية', 'المباريات', 'البطولات', 'البث', 'المزيد'];
  final _icons = const [LucideIcons.house, LucideIcons.calendarDays, LucideIcons.trophy, LucideIcons.radioTower, LucideIcons.layoutGrid];

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
        onTap: () => setState(() => _index = i),
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
  void _reload() => setState(() => _future = FootballApi.instance.fixtures());

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
          if (matches.isEmpty) return const EmptyPanel(title: 'لا توجد مباريات مدرجة اليوم', subtitle: 'قد لا تكون هناك مباريات أو قد لا يغطي المصدر هذه البطولة.');
          final selected = matches.where((m) => m.isLive).toList()..addAll(matches.where((m) => !m.isLive).take(5));
          return Column(children: selected.take(6).map((m) => Padding(padding: const EdgeInsets.only(bottom: 10), child: MatchTile(match: m))).toList());
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
      const Text('البيانات تعتمد على تغطية مزود الخدمة، وقد لا تتوفر جميع التفاصيل لكل بطولة.', style: TextStyle(color: cMuted, fontSize: 11)),
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
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['الكل', 'مباشر', 'قادمة', 'انتهت'].map((v) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(v), selected: _filter == v, onSelected: (_) => setState(() => _filter = v), selectedColor: cMint.withValues(alpha: .2), backgroundColor: cPanel, labelStyle: TextStyle(color: _filter == v ? cMint : cMuted), side: BorderSide(color: _filter == v ? cMint : cLine)))).toList())),
    const SizedBox(height: 12),
    FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل جدول المباريات');
        if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: _load);
        var list = (snapshot.data ?? []).map((e) => MatchData(Map<String, dynamic>.from(e as Map))).toList();
        if (_filter == 'مباشر') list = list.where((m) => m.isLive).toList();
        if (_filter == 'قادمة') list = list.where((m) => !m.isLive && !m.isFinished).toList();
        if (_filter == 'انتهت') list = list.where((m) => m.isFinished).toList();
        if (list.isEmpty) return const EmptyPanel(title: 'لا توجد مباريات في هذا التصنيف', subtitle: 'غيّر اليوم أو مرشح المباريات.');
        final groups = <String, List<MatchData>>{};
        for (final match in list) { groups.putIfAbsent('${match.leagueId}|${match.league}|${match.country}|${match.leagueLogo}', () => []).add(match); }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: groups.entries.map((entry) {
          final parts = entry.key.split('|');
          return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(children: [
            Row(children: [NetworkBadge(url: parts.length > 3 ? parts[3] : '', label: parts.length > 1 ? parts[1] : 'بطولة', size: 30), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(parts.length > 1 ? parts[1] : 'بطولة', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), Text(parts.length > 2 ? parts[2] : '', style: const TextStyle(color: cMuted, fontSize: 10))])), const Icon(LucideIcons.chevronLeft, color: cMuted, size: 17)]),
            const SizedBox(height: 8),
            ...entry.value.map((m) => Padding(padding: const EdgeInsets.only(bottom: 8), child: MatchTile(match: m))),
          ]));
        }).toList());
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
    if (!right) ...[Flexible(child: Text(name, maxLines: 2, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: winner ? FontWeight.w800 : FontWeight.w600))), const SizedBox(width: 7)],
    NetworkBadge(url: logo, label: name, size: 34),
    if (right) ...[const SizedBox(width: 7), Flexible(child: Text(name, maxLines: 2, textAlign: TextAlign.start, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: winner ? FontWeight.w800 : FontWeight.w600)))],
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
  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Scaffold(
      appBar: AppBar(title: const Text('مركز المباراة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: () async { final prefs = await SharedPreferences.getInstance(); final key = 'fav_${m.homeId}_${m.awayId}'; await prefs.setBool(key, !(prefs.getBool(key) ?? false)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث المفضلة'))); }, icon: const Icon(LucideIcons.star))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Panel(padding: const EdgeInsets.all(18), child: Column(children: [
          Text(m.league, style: const TextStyle(color: cMuted, fontSize: 12)),
          const SizedBox(height: 18),
          Row(children: [Expanded(child: _bigTeam(m.home, m.homeLogo)), Column(children: [Text(m.score, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(m.timeLabel, style: TextStyle(color: m.isLive ? cMint : cMuted, fontWeight: FontWeight.w700, fontSize: 11))]), Expanded(child: _bigTeam(m.away, m.awayLogo))]),
          const SizedBox(height: 12),
          Text(m.statusLong, style: const TextStyle(color: cMuted, fontSize: 11)),
        ])),
        const SizedBox(height: 16),
        Row(children: [
          _detailTab('الأحداث', 0), _detailTab('التشكيلة', 1), _detailTab('الإحصائيات', 2),
        ]),
        const SizedBox(height: 12),
        if (_tab == 0) _dataList('fixtures/events')
        else if (_tab == 1) _dataList('fixtures/lineups')
        else _dataList('fixtures/statistics'),
      ]),
    );
  }

  Widget _bigTeam(String name, String logo) => Column(children: [NetworkBadge(url: logo, label: name, size: 66), const SizedBox(height: 9), Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))]);
  Widget _detailTab(String label, int index) => Expanded(child: InkWell(onTap: () => setState(() => _tab = index), child: Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tab == index ? cMint : cLine, width: _tab == index ? 2 : 1))), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: _tab == index ? cMint : cMuted, fontSize: 11, fontWeight: FontWeight.w700)))));

  Widget _dataList(String endpoint) => FutureBuilder<List<dynamic>>(
    key: ValueKey('${widget.match.id}-$endpoint'),
    future: FootballApi.instance.fixtureData(endpoint, widget.match.id),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل التفاصيل');
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() {}));
      final rows = snapshot.data ?? [];
      if (rows.isEmpty) return const EmptyPanel(title: 'التفاصيل غير متاحة حالياً', subtitle: 'قد لا توفر البطولة هذه البيانات أو لم تبدأ المباراة بعد.');
      if (endpoint.endsWith('events')) return Column(children: rows.map((e) {
        final x = Map<String, dynamic>.from(e as Map);
        final time = x['time']?['elapsed']?.toString() ?? '';
        final detail = _mapText(x['detail'], _mapText(x['type'], 'حدث'));
        final player = x['player']?['name']?.toString() ?? '';
        final team = x['team']?['name']?.toString() ?? '';
        return Panel(padding: const EdgeInsets.all(12), child: Row(children: [Container(width: 40, padding: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(color: cPanel2, borderRadius: BorderRadius.circular(9)), child: Text(time.isEmpty ? '—' : "$time'", textAlign: TextAlign.center, style: const TextStyle(color: cMint, fontWeight: FontWeight.w800, fontSize: 11))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(detail, style: const TextStyle(fontWeight: FontWeight.w700)), Text('$player${team.isEmpty ? '' : ' · $team'}', style: const TextStyle(color: cMuted, fontSize: 10))]))]));
      }).toList());
      if (endpoint.endsWith('lineups')) return Column(children: rows.map((e) {
        final x = Map<String, dynamic>.from(e as Map);
        final team = x['team']?['name']?.toString() ?? 'الفريق';
        final formation = x['formation']?.toString() ?? '';
        final start = (x['startXI'] as List?) ?? [];
        final subs = (x['substitutes'] as List?) ?? [];
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(team, style: const TextStyle(fontWeight: FontWeight.w800)), Text('الخطة: ${formation.isEmpty ? 'غير متاحة' : formation}', style: const TextStyle(color: cMint, fontSize: 11)), const SizedBox(height: 8), Text('التشكيلة الأساسية (${start.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), ...start.map((p) { final player = p['player'] ?? {}; return _playerRow(player); }), const Divider(color: cLine), Text('الاحتياط (${subs.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), ...subs.map((p) => _playerRow(p['player'] ?? {}))])));
      }).toList());
      return Column(children: rows.map((e) {
        final x = Map<String, dynamic>.from(e as Map);
        final team = x['team']?['name']?.toString() ?? 'الفريق';
        final stats = (x['statistics'] as List?) ?? [];
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(team, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), ...stats.map((s) => Row(children: [Expanded(child: Text(_mapText(s['type']), style: const TextStyle(fontSize: 11, color: cMuted))), Text(_mapText(s['value']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))])),])));
      }).toList());
    },
  );

  Widget _playerRow(dynamic player) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Text(_mapText(player['number'], ''), style: const TextStyle(color: cMint, fontSize: 11)), const SizedBox(width: 9), Expanded(child: Text(_mapText(player['name']), style: const TextStyle(fontSize: 11))), Text(_mapText(player['pos'], ''), style: const TextStyle(color: cMuted, fontSize: 10))]));
}

// ---------- Standings and scorers ----------
class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});
  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  late Future<List<dynamic>> _leagues;
  Map<String, dynamic>? _selected;
  int _mode = 0;
  @override
  void initState() { super.initState(); _leagues = FootballApi.instance.leagues(); }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
    const SectionHeading('البطولات', subtitle: 'ترتيب الأندية والهدافون'),
    const SizedBox(height: 14),
    FutureBuilder<List<dynamic>>(
      future: _leagues,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل البطولات المتاحة');
        if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() => _leagues = FootballApi.instance.leagues()));
        final all = (snapshot.data ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (_selected == null && all.isNotEmpty) _selected = all.first;
        if (all.isEmpty) return const EmptyPanel(title: 'قائمة البطولات غير متاحة', subtitle: 'تحقق من ربط API-Football.');
        final league = _selected?['league'] ?? {};
        final seasons = (_selected?['seasons'] as List?) ?? [];
        final currentSeason = seasons.cast<Map>().where((s) => s['current'] == true).toList();
        final season = currentSeason.isNotEmpty ? (currentSeason.first['year'] as num?)?.toInt() ?? nowAden().year : nowAden().year;
        final id = (league['id'] as num?)?.toInt() ?? 0;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<int>(
            value: id == 0 ? null : id,
            dropdownColor: cPanel,
            decoration: const InputDecoration(labelText: 'اختر البطولة'),
            items: all.take(100).map((l) { final x = l['league'] ?? {}; return DropdownMenuItem<int>(value: (x['id'] as num?)?.toInt(), child: Text(_mapText(x['name'], 'بطولة'), overflow: TextOverflow.ellipsis)); }).toList(),
            onChanged: (value) => setState(() => _selected = all.firstWhere((e) => (e['league']?['id'] as num?)?.toInt() == value)),
          ),
          const SizedBox(height: 10),
          Row(children: [_modeChip('الترتيب', 0), const SizedBox(width: 6), _modeChip('الهدافون', 1), const SizedBox(width: 6), _modeChip('الصناعة', 2)]),
          const SizedBox(height: 12),
          _standingsData(id, season),
        ]);
      },
    ),
  ]);

  Widget _modeChip(String title, int value) => Expanded(child: InkWell(onTap: () => setState(() => _mode = value), child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: _mode == value ? cMint.withValues(alpha: .13) : cPanel, borderRadius: BorderRadius.circular(11), border: Border.all(color: _mode == value ? cMint : cLine)), child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: _mode == value ? cMint : cMuted, fontWeight: FontWeight.w700, fontSize: 12)))));

  Widget _standingsData(int id, int season) => FutureBuilder<List<dynamic>>(
    key: ValueKey('$id-$season-$_mode'),
    future: _mode == 0 ? FootballApi.instance.standings(id, season) : (_mode == 1 ? FootballApi.instance.topScorers(id, season) : FootballApi.instance.topAssists(id, season)),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل بيانات البطولة');
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() {}));
      final response = snapshot.data ?? [];
      if (response.isEmpty) return const EmptyPanel(title: 'لا توجد بيانات متاحة', subtitle: 'قد تكون بيانات هذه البطولة غير مغطاة في الموسم المختار.');
      if (_mode == 0) {
        final league = response.first['league'] ?? {};
        final rawStandings = league['standings'];
        final table = rawStandings is List && rawStandings.isNotEmpty && rawStandings.first is List
            ? rawStandings.first as List
            : <dynamic>[];
        return Panel(padding: const EdgeInsets.all(10), child: Column(children: [
          Row(children: const [SizedBox(width: 25, child: Text('#', style: TextStyle(color: cMuted, fontSize: 10))), Expanded(child: Text('النادي', style: TextStyle(color: cMuted, fontSize: 10))), Text('لعب', style: TextStyle(color: cMuted, fontSize: 10)), SizedBox(width: 28, child: Text('ف', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 10))), SizedBox(width: 28, child: Text('ن', textAlign: TextAlign.center, style: TextStyle(color: cMuted, fontSize: 10)))]),
          const Divider(color: cLine),
          ...table.map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [SizedBox(width: 25, child: Text(_mapText(r['rank']), style: const TextStyle(color: cMint, fontWeight: FontWeight.w800, fontSize: 11))), Expanded(child: Row(children: [NetworkBadge(url: r['team']?['logo']?.toString() ?? '', label: r['team']?['name']?.toString() ?? '', size: 26), const SizedBox(width: 7), Expanded(child: Text(_mapText(r['team']?['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))])), Text(_mapText(r['all']?['played']), style: const TextStyle(fontSize: 11)), SizedBox(width: 28, child: Text(_mapText(r['all']?['win']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))), SizedBox(width: 28, child: Text(_mapText(r['points']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)))]))),
        ]));
      }
      return Column(children: response.take(30).map((r) {
        final player = r['player'] ?? {};
        final stats = _firstOrEmpty(r['statistics']);
        final goals = stats['goals'] ?? {};
        final team = stats['team'] ?? {};
        final metric = _mode == 1 ? goals['total'] : goals['assists'];
        final metricLabel = _mode == 1 ? 'هدف' : 'صناعة';
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(child: Row(children: [NetworkBadge(url: player['photo']?.toString() ?? '', label: player['name']?.toString() ?? '', size: 42), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_mapText(player['name']), style: const TextStyle(fontWeight: FontWeight.w800)), Text(_mapText(team['name']), style: const TextStyle(color: cMuted, fontSize: 10))])), Text(_mapText(metric), style: const TextStyle(color: cMint, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 4), Text(metricLabel, style: const TextStyle(color: cMuted, fontSize: 10))])));
      }).toList());
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
      _future = _mode == 0 ? FootballApi.instance.searchPlayers(q, nowAden().year) : FootballApi.instance.searchTeams(q);
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
    _future = FootballApi.instance.get('players', {'id': '${widget.playerId}', 'season': '${nowAden().year}'});
    _transfers = FootballApi.instance.get('transfers', {'player': '${widget.playerId}'}).then((v) => (v['response'] as List?) ?? const []);
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('ملف اللاعب', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), body: FutureBuilder<Map<String, dynamic>>(future: _future, builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: cMint));
    if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(16), child: ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() => _future = FootballApi.instance.get('players', {'id': '${widget.playerId}', 'season': '${nowAden().year}'}))));
    final rows = (snapshot.data?['response'] as List?) ?? [];
    if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: EmptyPanel(title: 'ملف اللاعب غير متاح', subtitle: 'لا توجد إحصائيات لهذا اللاعب في الموسم الحالي.'));
    final row = rows.first;
    final p = row['player'] ?? {};
    final stats = _firstOrEmpty(row['statistics']);
    final team = stats['team'] ?? {};
    final games = stats['games'] ?? {};
    final goals = stats['goals'] ?? {};
    return ListView(padding: const EdgeInsets.all(16), children: [
      Panel(child: Column(children: [NetworkBadge(url: p['photo']?.toString() ?? '', label: _mapText(p['name']), size: 90), const SizedBox(height: 10), Text(_mapText(p['name']), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), Text('${_mapText(p['nationality'], '')} · ${_mapText(p['age'], '')} سنة', style: const TextStyle(color: cMuted, fontSize: 11)), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_metric('الفريق', _mapText(team['name'])), _metric('المركز', _mapText(games['position'])), _metric('الرقم', _mapText(games['number']))])])),
      const SizedBox(height: 12),
      Row(children: [_metricPanel('المشاركات', _mapText(games['appearences'])), const SizedBox(width: 8), _metricPanel('الأهداف', _mapText(goals['total'])), const SizedBox(width: 8), _metricPanel('الصناعة', _mapText(goals['assists']))]),
      const SizedBox(height: 18),
      const SectionHeading('تاريخ الانتقالات'), const SizedBox(height: 9),
      FutureBuilder<List<dynamic>>(future: _transfers, builder: (context, ts) {
        if (ts.connectionState == ConnectionState.waiting) return const LoadingPanel(label: 'جاري تحميل الانتقالات');
        if (ts.hasError) return ErrorPanel(message: ts.error.toString(), onRetry: () => setState(() => _transfers = FootballApi.instance.get('transfers', {'player': '${widget.playerId}'}).then((v) => (v['response'] as List?) ?? const [])));
        final transfers = ts.data ?? [];
        if (transfers.isEmpty) return const EmptyPanel(title: 'لا توجد انتقالات مسجلة', subtitle: 'لم يرجع المصدر سجلاً للانتقالات.');
        return Column(children: transfers.map((t) { final x = t['transfers'] as List? ?? []; return Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_mapText(t['player']?['name']), style: const TextStyle(fontWeight: FontWeight.w800)), ...x.map((v) => Text('${_mapText(v['date'])} · ${_mapText(v['type'])} · ${_mapText(v['teams']?['out']?['name'])} ← ${_mapText(v['teams']?['in']?['name'])}', style: const TextStyle(color: cMuted, fontSize: 10)))]))); }).toList());
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
  void initState() { super.initState(); _team = FootballApi.instance.get('teams', {'id': '${widget.teamId}'}); _players = FootballApi.instance.teamPlayers(widget.teamId, nowAden().year); }
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
      if (snapshot.hasError) return ErrorPanel(message: snapshot.error.toString(), onRetry: () => setState(() => _players = FootballApi.instance.teamPlayers(widget.teamId, nowAden().year)));
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
