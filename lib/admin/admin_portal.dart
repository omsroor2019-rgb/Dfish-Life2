import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/cloud_data_service.dart';
import '../services/firebase_runtime.dart';
import '../services/football_api.dart';

const _bg = Color(0xFF0B1018);
const _panel = Color(0xFF121B27);
const _panel2 = Color(0xFF1A2939);
const _line = Color(0xFF263445);
const _mint = Color(0xFF20E6B2);
const _text = Color(0xFFF4F7FA);
const _muted = Color(0xFF8D9AAA);

class AdminAccessScreen extends StatefulWidget {
  const AdminAccessScreen({super.key});

  @override
  State<AdminAccessScreen> createState() => _AdminAccessScreenState();
}

class _AdminAccessScreenState extends State<AdminAccessScreen> {
  final _password = TextEditingController();
  bool _checking = true;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    if (!FirebaseRuntime.isReady) {
      if (mounted) setState(() => _checking = false);
      return;
    }
    final allowed = await CloudDataService.currentUserIsAdmin();
    if (!mounted) return;
    setState(() {
      _checking = false;
    });
    if (allowed) {
      _openDashboard();
    } else {
      await CloudDataService.signOutAdmin();
    }
  }

  void _openDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
  }

  Future<void> _login() async {
    if (_password.text.trim().isEmpty) {
      _showMessage('أدخل كلمة مرور الإدارة.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await CloudDataService.signInAdmin(_password.text);
      if (mounted) _openDashboard();
    } catch (error) {
      final message = error.toString().replaceFirst('Bad state: ', '');
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('بوابة الإدارة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
      body: _checking
          ? const Center(child: CircularProgressIndicator(color: _mint))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _AdminBrand(),
                const SizedBox(height: 22),
                if (!FirebaseRuntime.isReady) ...[
                  const _AdminNotice(
                    danger: true,
                    text: 'خدمة Firebase غير مربوطة بعد. أكمل إعداد lib/firebase_options.dart واتبع docs/FIREBASE_SETUP_AR.md ثم أعد بناء التطبيق.',
                  ),
                ] else ...[
                  const _AdminNotice(
                    text: 'منطقة مخصصة لمدير DFISH LIVE. سجّل الدخول بكلمة مرور حساب الإدارة.',
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
                    child: Row(children: [
                      const Icon(LucideIcons.users, color: _mint),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('حساب المدير', style: TextStyle(color: _muted, fontSize: 10)),
                        Text(CloudDataService.adminEmail, style: const TextStyle(color: _text, fontWeight: FontWeight.w800)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => _busy ? null : _login(),
                    style: const TextStyle(color: _text),
                    decoration: InputDecoration(
                      labelText: 'كلمة مرور الإدارة',
                      labelStyle: const TextStyle(color: _muted),
                      filled: true,
                      fillColor: _panel,
                      prefixIcon: const Icon(LucideIcons.shieldCheck, color: _muted, size: 19),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                        icon: Icon(_showPassword ? LucideIcons.info : LucideIcons.info, color: _muted, size: 19),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _mint)),
                    ),
                  ),
                  if (_error != null) Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _login,
                      icon: _busy
                          ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: _bg))
                          : const Icon(LucideIcons.shieldCheck, size: 18),
                      label: Text(_busy ? 'جارٍ التحقق...' : 'دخول لوحة التحكم', style: const TextStyle(fontWeight: FontWeight.w900)),
                      style: FilledButton.styleFrom(backgroundColor: _mint, foregroundColor: _bg, padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Text('تطوير عبد العزيز عوض بن ثابت', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 10)),
              ],
            ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _apiCheckBusy = false;
  String? _apiCheckMessage;
  bool _apiCheckOk = false;

  Future<void> _logout() async {
    await CloudDataService.signOutAdmin();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _checkApi() async {
    setState(() {
      _apiCheckBusy = true;
      _apiCheckMessage = null;
    });
    try {
      await FootballApi.instance.checkStatus();
      if (mounted) {
        setState(() {
          _apiCheckOk = true;
          _apiCheckMessage = 'الاتصال بـ API-Football ناجح والمفتاح مقبول حالياً.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _apiCheckOk = false;
          _apiCheckMessage = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _apiCheckBusy = false);
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? match]) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panel,
      builder: (_) => _MatchEditor(existing: match),
    );
    if (result == null) return;
    try {
      await CloudDataService.saveMatch(result, id: match?['id']?.toString());
      _snack(match == null ? 'تم نشر المباراة وروابط البث لجميع المستخدمين.' : 'تم تحديث المباراة لدى جميع المستخدمين.');
    } catch (error) {
      _snack(error.toString());
    }
  }

  Future<void> _delete(Map<String, dynamic> match) async {
    final id = match['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('حذف المباراة؟'),
        content: const Text('سيتم حذف المباراة وجميع مصادر البث المرتبطة بها من أجهزة المستخدمين.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CloudDataService.deleteMatch(id);
      _snack('تم حذف المباراة.');
    } catch (error) {
      _snack(error.toString());
    }
  }

  void _snack(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value.replaceFirst('Bad state: ', ''))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('إدارة DFISH LIVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          actions: [IconButton(onPressed: _logout, tooltip: 'تسجيل الخروج', icon: const Icon(LucideIcons.logOut, color: _muted))],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          backgroundColor: _mint,
          foregroundColor: _bg,
          icon: const Icon(LucideIcons.plus),
          label: const Text('إضافة مباراة'),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: CloudDataService.watchAdminMatches(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _mint));
            }
            if (snapshot.hasError) {
              return _AdminError(message: 'تعذر قراءة المباريات. تحقق من صلاحية المدير وقواعد Firestore.\n${snapshot.error}');
            }
            final items = snapshot.data ?? const <Map<String, dynamic>>[];
            final enabled = items.where((item) => item['enabled'] == true).length;
            final sourceCount = items.fold<int>(0, (sum, item) => sum + ((item['sources'] as List?)?.length ?? 0));
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                const _AdminNotice(text: 'أي مباراة تحفظها هنا تتم مزامنتها مباشرةً لجميع مستخدمي DFISH LIVE. استخدم فقط روابط البث المصرح لك بنشرها.'),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _StatCard(title: 'كل المباريات', value: '${items.length}', icon: LucideIcons.calendarDays)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(title: 'المعروضة', value: '$enabled', icon: LucideIcons.info)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(title: 'مصادر البث', value: '$sourceCount', icon: LucideIcons.radioTower)),
                ]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: _line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(LucideIcons.chartNoAxesCombined, color: _mint, size: 19),
                      const SizedBox(width: 9),
                      const Expanded(child: Text('حالة API-Football', style: TextStyle(fontWeight: FontWeight.w900))),
                      TextButton.icon(
                        onPressed: _apiCheckBusy ? null : _checkApi,
                        icon: _apiCheckBusy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.refreshCw, size: 14),
                        label: const Text('فحص الاتصال'),
                      ),
                    ]),
                    if (_apiCheckMessage != null) Text(_apiCheckMessage!, style: TextStyle(color: _apiCheckOk ? _mint : Colors.orangeAccent, fontSize: 11, height: 1.5)),
                    if (_apiCheckMessage == null) const Text('يمكنك اختبار صلاحية مفتاح API من هنا.', style: TextStyle(color: _muted, fontSize: 10)),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  const Expanded(child: Text('المباريات وروابط البث', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w900))),
                  Text('${items.length} عنصر', style: const TextStyle(color: _muted, fontSize: 10)),
                ]),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const _EmptyAdminMatches()
                else
                  ...items.map((match) => _AdminMatchCard(
                        match: match,
                        onEdit: () => _openEditor(match),
                        onDelete: () => _delete(match),
                      )),
                const SizedBox(height: 12),
                const Text('تطوير عبد العزيز عوض بن ثابت · جميع الحقوق محفوظة', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 10)),
              ],
            );
          },
        ),
      );
}

class _MatchEditor extends StatefulWidget {
  const _MatchEditor({this.existing});
  final Map<String, dynamic>? existing;

  @override
  State<_MatchEditor> createState() => _MatchEditorState();
}

class _MatchEditorState extends State<_MatchEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _home;
  late final TextEditingController _away;
  late final TextEditingController _league;
  late final TextEditingController _date;
  late final TextEditingController _time;
  late final TextEditingController _homeLogo;
  late final TextEditingController _awayLogo;
  late final TextEditingController _leagueLogo;
  late final TextEditingController _commentator;
  late final TextEditingController _channel;
  late final List<TextEditingController> _sourceNames;
  late final List<TextEditingController> _sourceUrls;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    final match = widget.existing ?? <String, dynamic>{};
    _home = TextEditingController(text: match['home']?.toString() ?? '');
    _away = TextEditingController(text: match['away']?.toString() ?? '');
    _league = TextEditingController(text: match['league']?.toString() ?? '');
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    _date = TextEditingController(text: match['date']?.toString() ?? '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
    _time = TextEditingController(text: match['time']?.toString() ?? '20:00');
    _homeLogo = TextEditingController(text: match['homeLogo']?.toString() ?? '');
    _awayLogo = TextEditingController(text: match['awayLogo']?.toString() ?? '');
    _leagueLogo = TextEditingController(text: match['leagueLogo']?.toString() ?? '');
    _commentator = TextEditingController(text: match['commentator']?.toString() ?? '');
    _channel = TextEditingController(text: match['channel']?.toString() ?? '');
    _enabled = match['enabled'] != false;
    final sources = (match['sources'] as List?) ?? const [];
    _sourceNames = List.generate(4, (index) {
      final source = index < sources.length && sources[index] is Map ? Map<String, dynamic>.from(sources[index] as Map) : <String, dynamic>{};
      return TextEditingController(text: source['name']?.toString() ?? 'بث ${index + 1}');
    });
    _sourceUrls = List.generate(4, (index) {
      final source = index < sources.length && sources[index] is Map ? Map<String, dynamic>.from(sources[index] as Map) : <String, dynamic>{};
      return TextEditingController(text: source['url']?.toString() ?? '');
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _home, _away, _league, _date, _time, _homeLogo, _awayLogo,
      _leagueLogo, _commentator, _channel, ..._sourceNames, ..._sourceUrls,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final sources = <Map<String, dynamic>>[];
    for (var index = 0; index < 4; index++) {
      final url = _sourceUrls[index].text.trim();
      if (url.isEmpty) continue;
      sources.add({
        'id': 'source_${index + 1}',
        'name': _sourceNames[index].text.trim().isEmpty ? 'بث ${index + 1}' : _sourceNames[index].text.trim(),
        'url': url,
        'enabled': true,
      });
    }
    Navigator.pop(context, <String, dynamic>{
      'home': _home.text.trim(),
      'away': _away.text.trim(),
      'league': _league.text.trim().isEmpty ? 'مباراة' : _league.text.trim(),
      'date': _date.text.trim(),
      'time': _time.text.trim(),
      'homeLogo': _homeLogo.text.trim(),
      'awayLogo': _awayLogo.text.trim(),
      'leagueLogo': _leagueLogo.text.trim(),
      'commentator': _commentator.text.trim(),
      'channel': _channel.text.trim(),
      'enabled': _enabled,
      'sources': sources,
    });
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;

  String? _validDate(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) || DateTime.tryParse(text) == null) {
      return 'أدخل التاريخ بصيغة YYYY-MM-DD';
    }
    return null;
  }

  String? _validTime(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(text)) {
      return 'أدخل الوقت بصيغة HH:MM';
    }
    return null;
  }

  String? _httpsUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return 'أدخل رابط HTTPS صالحاً';
    return null;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(context).viewInsets.bottom + 18),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(widget.existing == null ? 'إضافة مباراة جديدة' : 'تعديل بيانات المباراة', style: const TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: _muted)),
                ]),
                const SizedBox(height: 8),
                _field(_home, 'الفريق الأول *', validator: _required),
                const SizedBox(height: 9),
                _field(_away, 'الفريق الثاني *', validator: _required),
                const SizedBox(height: 9),
                _field(_league, 'اسم البطولة'),
                const SizedBox(height: 9),
                Row(children: [
                  Expanded(child: _field(_date, 'التاريخ YYYY-MM-DD *', validator: _validDate)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_time, 'الوقت HH:MM *', validator: _validTime)),
                ]),
                const SizedBox(height: 9),
                const Text('الشعارات اختيارية: الصق رابط صورة مباشر HTTPS للشعار (PNG أو JPG). اترك الخانة فارغة إن لم يتوفر الرابط؛ سيظهر اسم الفريق بدلاً من الصورة. رابط الشعار ليس رابط البث.', style: TextStyle(color: _muted, fontSize: 10, height: 1.6)),
                const SizedBox(height: 8),
                _field(_homeLogo, 'رابط صورة شعار الفريق الأول (اختياري)', validator: _httpsUrl),
                const SizedBox(height: 9),
                _field(_awayLogo, 'رابط صورة شعار الفريق الثاني (اختياري)', validator: _httpsUrl),
                const SizedBox(height: 9),
                _field(_leagueLogo, 'رابط صورة شعار البطولة (اختياري)', validator: _httpsUrl),
                const SizedBox(height: 9),
                _field(_commentator, 'اسم المعلق (اختياري)'),
                const SizedBox(height: 9),
                _field(_channel, 'القناة الناقلة (اختياري)'),
                const SizedBox(height: 17),
                const Text('روابط تشغيل البث (حتى 4 مصادر)', style: TextStyle(color: _text, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text('أضف فقط روابط تملك إذناً بنشرها. روابط HLS بصيغة M3U8 وMP4 المباشرة تعمل عبر مشغل التطبيق، أما صفحات الويب فقد تختلف طريقة تشغيلها حسب الموقع.', style: TextStyle(color: _muted, fontSize: 10, height: 1.6)),
                const SizedBox(height: 10),
                for (var index = 0; index < 4; index++) ...[
                  _field(_sourceNames[index], 'اسم المصدر ${index + 1}'),
                  const SizedBox(height: 7),
                  _field(_sourceUrls[index], 'رابط تشغيل HTTPS للمصدر ${index + 1}', validator: _httpsUrl),
                  const SizedBox(height: 11),
                ],
                SwitchListTile.adaptive(
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                  title: const Text('إظهار المباراة لجميع المستخدمين', style: TextStyle(color: _text, fontSize: 13)),
                  activeThumbColor: _mint,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(LucideIcons.radioTower, size: 18),
                    label: const Text('حفظ ومزامنة للجميع', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: FilledButton.styleFrom(backgroundColor: _mint, foregroundColor: _bg, padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _field(TextEditingController controller, String label, {String? Function(String?)? validator}) => TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(color: _text, fontSize: 13),
        autocorrect: false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _muted, fontSize: 12),
          filled: true,
          fillColor: _panel2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _mint)),
          errorStyle: const TextStyle(fontSize: 10),
        ),
      );
}

class _AdminBrand extends StatelessWidget {
  const _AdminBrand();
  @override
  Widget build(BuildContext context) => const Column(children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'DFISH ', style: TextStyle(color: _text, fontSize: 27, fontWeight: FontWeight.w900)),
          TextSpan(text: 'LIVE', style: TextStyle(color: _mint, fontSize: 27, fontWeight: FontWeight.w900)),
        ])),
        SizedBox(height: 5),
        Text('لوحة الإدارة والمحتوى', style: TextStyle(color: _muted, fontSize: 11)),
      ]);
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice({required this.text, this.danger = false});
  final String text;
  final bool danger;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: (danger ? Colors.redAccent : _mint).withValues(alpha: .08),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: (danger ? Colors.redAccent : _mint).withValues(alpha: .24)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(danger ? LucideIcons.alertTriangle : LucideIcons.shieldCheck, size: 19, color: danger ? Colors.redAccent : _mint),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: const TextStyle(color: _muted, fontSize: 11, height: 1.65))),
        ]),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
        child: Column(children: [
          Icon(icon, color: _mint, size: 19),
          const SizedBox(height: 7),
          Text(value, style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: _muted, fontSize: 9), textAlign: TextAlign.center),
        ]),
      );
}

class _AdminMatchCard extends StatelessWidget {
  const _AdminMatchCard({required this.match, required this.onEdit, required this.onDelete});
  final Map<String, dynamic> match;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final sources = (match['sources'] as List?) ?? const [];
    final enabled = match['enabled'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${match['home'] ?? ''} × ${match['away'] ?? ''}', style: const TextStyle(color: _text, fontWeight: FontWeight.w900))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: enabled ? _mint.withValues(alpha: .13) : Colors.red.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
              child: Text(enabled ? 'مفعلة' : 'مخفية', style: TextStyle(color: enabled ? _mint : Colors.redAccent, fontSize: 10)),
            ),
          ]),
          const SizedBox(height: 6),
          Text('${match['league'] ?? 'مباراة'} · ${match['date'] ?? ''} · ${match['time'] ?? ''} بتوقيت اليمن', style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 5),
          Row(children: [
            const Icon(LucideIcons.radioTower, color: _mint, size: 15),
            const SizedBox(width: 6),
            Text('${sources.length} مصادر بث', style: const TextStyle(color: _mint, fontSize: 11)),
            const Spacer(),
            if ((match['channel']?.toString() ?? '').isNotEmpty) Text(match['channel'].toString(), style: const TextStyle(color: _muted, fontSize: 10)),
          ]),
          const Divider(color: _line),
          Row(children: [
            TextButton.icon(onPressed: onEdit, icon: const Icon(LucideIcons.pencil, size: 16), label: const Text('تعديل')),
            TextButton.icon(onPressed: onDelete, icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent), label: const Text('حذف', style: TextStyle(color: Colors.redAccent))),
          ]),
        ]),
      ),
    );
  }
}

class _EmptyAdminMatches extends StatelessWidget {
  const _EmptyAdminMatches();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
        child: const Column(children: [
          Icon(LucideIcons.calendarPlus, size: 42, color: _mint),
          SizedBox(height: 12),
          Text('لا توجد مباريات مضافة', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16)),
          SizedBox(height: 6),
          Text('اضغط إضافة مباراة لإضافة بيانات المباراة وروابط البث. ستظهر للمستخدمين بعد الحفظ.', textAlign: TextAlign.center, style: TextStyle(color: _muted, height: 1.6, fontSize: 11)),
        ]),
      );
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.alertTriangle, size: 38, color: Colors.orangeAccent),
            const SizedBox(height: 12),
            const Text('تعذر تحميل لوحة الإدارة', style: TextStyle(color: _text, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 11, height: 1.6)),
          ]),
        ),
      );
}
