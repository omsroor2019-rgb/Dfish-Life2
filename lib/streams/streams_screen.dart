import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/cloud_data_service.dart';
import '../services/firebase_runtime.dart';

const _bg = Color(0xFF0B1018);
const _panel = Color(0xFF121B27);
const _panel2 = Color(0xFF172332);
const _line = Color(0xFF263445);
const _mint = Color(0xFF20E6B2);
const _text = Color(0xFFF4F7FA);
const _muted = Color(0xFF8D9AAA);

class StreamMatchesScreen extends StatefulWidget {
  const StreamMatchesScreen({super.key});
  @override
  State<StreamMatchesScreen> createState() => _StreamMatchesScreenState();
}

class _StreamMatchesScreenState extends State<StreamMatchesScreen> {
  late Stream<List<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = CloudDataService.watchPublicMatches();
  }

  Future<void> _refresh() async {
    if (!FirebaseRuntime.isReady) return;
    try {
      await CloudDataService.refreshMatches();
      if (mounted) setState(() => _stream = CloudDataService.watchPublicMatches());
    } catch (_) {
      if (mounted) setState(() => _stream = CloudDataService.watchPublicMatches());
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: _mint,
        backgroundColor: _panel,
        onRefresh: _refresh,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 28), children: [
          const Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('البث المباشر', style: TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w900)),
              SizedBox(height: 3),
              Text('المباريات التي ينشرها مدير DFISH LIVE', style: TextStyle(color: _muted, fontSize: 11)),
            ])),
            Icon(LucideIcons.radioTower, color: _mint, size: 25),
          ]),
          const SizedBox(height: 14),
          if (!FirebaseRuntime.isReady)
            const _StreamState(
              icon: LucideIcons.wifiOff,
              title: 'المزامنة غير مفعلة',
              subtitle: 'أكمل إعداد Firebase في المشروع حتى تظهر المباريات وروابط البث لجميع المستخدمين.',
            )
          else
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _StreamState(icon: LucideIcons.loaderCircle, title: 'جاري تحميل المباريات', subtitle: 'نحدّث قائمة مصادر البث.');
                }
                if (snapshot.hasError) {
                  return _StreamState(
                    icon: LucideIcons.wifiOff,
                    title: 'لا يمكن تحميل البث',
                    subtitle: snapshot.error.toString(),
                    retry: () => setState(() => _stream = CloudDataService.watchPublicMatches()),
                  );
                }
                final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                if (rows.isEmpty) {
                  return const _StreamState(
                    icon: LucideIcons.calendarX,
                    title: 'لا توجد مباريات بث حالياً',
                    subtitle: 'ستظهر المباريات هنا عندما يضيفها المدير من لوحة الإدارة.',
                  );
                }
                return Column(children: rows.map((match) {
                  final sources = (match['sources'] as List?) ?? const [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: _panel,
                      borderRadius: BorderRadius.circular(17),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(17),
                        onTap: sources.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => StreamMatchScreen(match: match))),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text((match['league']?.toString().isNotEmpty == true) ? match['league'].toString() : 'مباراة مباشرة', style: const TextStyle(color: _mint, fontSize: 11, fontWeight: FontWeight.w800))),
                              const Icon(LucideIcons.chevronLeft, color: _muted, size: 18),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: _team(match['home']?.toString() ?? 'الفريق الأول', match['homeLogo']?.toString() ?? '')),
                              Column(children: [
                                Text(match['time']?.toString() ?? '--:--', style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w900)),
                                Text(match['date']?.toString() ?? '', style: const TextStyle(color: _muted, fontSize: 10)),
                              ]),
                              Expanded(child: _team(match['away']?.toString() ?? 'الفريق الثاني', match['awayLogo']?.toString() ?? '', alignEnd: true)),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              const Icon(LucideIcons.playCircle, color: _mint, size: 17),
                              const SizedBox(width: 7),
                              Text(sources.isEmpty ? 'لا يوجد مصدر بث' : '${sources.length} مصادر متاحة', style: const TextStyle(color: _muted, fontSize: 11)),
                              const Spacer(),
                              if (match['commentator']?.toString().isNotEmpty == true)
                                Text('المعلق: ${match['commentator']}', style: const TextStyle(color: _muted, fontSize: 10)),
                            ]),
                          ]),
                        ),
                      ),
                    ),
                  );
                }).toList());
              },
            ),
          const SizedBox(height: 8),
          const Text('تظهر هنا روابط البث التي أضافها المدير. يجب أن تكون المصادر مأذوناً بعرضها، وقد يختلف دعم التشغيل حسب صيغة الرابط ومصدره.', style: TextStyle(color: _muted, fontSize: 10, height: 1.7)),
        ]),
      );

  Widget _team(String name, String logo, {bool alignEnd = false}) => Row(
        mainAxisAlignment: alignEnd ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!alignEnd) ...[
            Flexible(child: Text(name, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 12))),
            const SizedBox(width: 8),
          ],
          _Logo(url: logo, label: name),
          if (alignEnd) ...[
            const SizedBox(width: 8),
            Flexible(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 12))),
          ],
        ],
      );
}

class StreamMatchScreen extends StatefulWidget {
  const StreamMatchScreen({super.key, required this.match});
  final Map<String, dynamic> match;
  @override
  State<StreamMatchScreen> createState() => _StreamMatchScreenState();
}

class _StreamMatchScreenState extends State<StreamMatchScreen> {
  VideoPlayerController? _controller;
  int _selected = -1;
  bool _loading = false;
  String? _error;
  List<VideoTrack> _qualityTracks = const [];

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  Future<void> _play(Map<String, dynamic> source, int index) async {
    final rawUrl = source['url']?.toString() ?? '';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) { _show('رابط المصدر غير صالح أو غير آمن.'); return; }
    final path = uri.path.toLowerCase();
    final isDirectMedia = path.endsWith('.m3u8') || path.endsWith('.mp4') || path.endsWith('.mpd');
    if (!isDirectMedia) {
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => WebStreamScreen(uri: uri)));
      return;
    }
    setState(() { _loading = true; _error = null; _selected = index; _qualityTracks = const []; });
    await _controller?.dispose();
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 35));
      List<VideoTrack> tracks = const [];
      try {
        if (controller.isVideoTrackSupportAvailable()) tracks = await controller.getVideoTracks();
      } catch (_) { tracks = const []; }
      if (!mounted) return;
      setState(() { _loading = false; _qualityTracks = tracks; });
      // Playback intentionally starts only after the user taps a source.
      await controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'تعذر تشغيل هذا المصدر. قد يكون الرابط منتهياً أو يحتاج إلى صلاحية أو صيغة أخرى.'; _qualityTracks = const []; });
      await controller.dispose();
      if (identical(_controller, controller)) _controller = null;
    }
  }

  void _show(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final sources = ((m['sources'] as List?) ?? []).where((e) => e is Map && e['enabled'] != false).toList();
    final c = _controller;
    return Scaffold(backgroundColor: _bg, appBar: AppBar(title: const Text('مشاهدة المباراة', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w800))), body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)), child: Column(children: [Text(m['league']?.toString() ?? 'مباراة', style: const TextStyle(color: _mint, fontSize: 11)), const SizedBox(height: 10), Row(children: [Expanded(child: Text(m['home']?.toString() ?? '', textAlign: TextAlign.center, style: const TextStyle(color: _text, fontWeight: FontWeight.w800))), const Text('×', style: TextStyle(color: _muted, fontSize: 18)), Expanded(child: Text(m['away']?.toString() ?? '', textAlign: TextAlign.center, style: const TextStyle(color: _text, fontWeight: FontWeight.w800)))]), const SizedBox(height: 8), Text('${m['date'] ?? ''} · ${m['time'] ?? ''} بتوقيت اليمن', style: const TextStyle(color: _muted, fontSize: 10))])),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: c != null && c.value.isInitialized ? () { setState(() { c.value.isPlaying ? c.pause() : c.play(); }); } : sources.isNotEmpty && !_loading ? () => _play(Map<String, dynamic>.from(sources.first as Map), 0) : null,
        child: AspectRatio(aspectRatio: c != null && c.value.isInitialized ? c.value.aspectRatio : 16 / 9, child: Container(color: Colors.black, alignment: Alignment.center, child: c != null && c.value.isInitialized ? Stack(fit: StackFit.expand, children: [VideoPlayer(c), if (!c.value.isPlaying) const Center(child: Icon(LucideIcons.playCircle, color: _mint, size: 58)), Positioned(left: 8, right: 8, bottom: 7, child: VideoProgressIndicator(c, allowScrubbing: true, colors: const VideoProgressColors(playedColor: _mint, bufferedColor: Colors.white38, backgroundColor: Colors.white12)))]): _loading ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: _mint), SizedBox(height: 12), Text('جاري تحميل مصدر البث...', style: TextStyle(color: _text, fontSize: 12))]) : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.playCircle, color: _mint, size: 56), SizedBox(height: 8), Text('اضغط على الفيديو لبدء البث', style: TextStyle(color: _text, fontSize: 12))]))),
      ),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11))),
      if (c != null && c.value.isInitialized) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: () => setState(() => c.value.isPlaying ? c.pause() : c.play()), icon: Icon(c.value.isPlaying ? LucideIcons.pause : LucideIcons.play, color: _mint)),
        IconButton(onPressed: () => c.setVolume(c.value.volume > 0 ? 0 : 1), icon: Icon(c.value.volume > 0 ? LucideIcons.volume2 : LucideIcons.volumeX, color: _text)),
        if (_qualityTracks.isNotEmpty) PopupMenuButton<VideoTrack>(
          tooltip: 'جودة الفيديو',
          onSelected: (track) async { try { await c.selectVideoTrack(track); } catch (_) { _show('لا يمكن تغيير الجودة لهذا المصدر.'); } },
          itemBuilder: (_) => _qualityTracks.map((track) => PopupMenuItem<VideoTrack>(value: track, child: Text(track.label ?? '${track.height ?? '?'}p'))).toList(),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Row(children: [const Icon(LucideIcons.settings2, color: _mint, size: 17), const SizedBox(width: 5), Text('الجودة', style: const TextStyle(color: _text, fontSize: 11))])),
        ),
      ]),
      const SizedBox(height: 18),
      const Text('مصادر البث', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w900)),
      const SizedBox(height: 9),
      if (sources.isEmpty) const Text('لم تتم إضافة مصادر للمباراة.', style: TextStyle(color: _muted, fontSize: 11)),
      ...sources.asMap().entries.map((entry) {
        final source = Map<String, dynamic>.from(entry.value as Map);
        final selected = entry.key == _selected;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Material(color: selected ? _mint.withValues(alpha: .13) : _panel, borderRadius: BorderRadius.circular(13), child: InkWell(borderRadius: BorderRadius.circular(13), onTap: () => _play(source, entry.key), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(LucideIcons.playCircle, color: selected ? _mint : _muted), const SizedBox(width: 10), Expanded(child: Text(source['name']?.toString() ?? 'مصدر ${entry.key + 1}', style: TextStyle(color: selected ? _mint : _text, fontWeight: FontWeight.w800))), if (selected) const Icon(LucideIcons.check, color: _mint)])))));
      }),
      const SizedBox(height: 12),
      const Text('التشغيل داخل التطبيق يدعم روابط الفيديو المباشرة المعروفة مثل HLS (.m3u8) وMP4. صفحات الويب تفتح داخل متصفح مدمج مقيّد؛ لا نحاول استخراج أو تجاوز مشغلات محمية أو إعلانات أو قيود وصول.', style: TextStyle(color: _muted, fontSize: 10, height: 1.7)),
    ]));
  }
}

class WebStreamScreen extends StatefulWidget {
  const WebStreamScreen({super.key, required this.uri});
  final Uri uri;
  @override
  State<WebStreamScreen> createState() => _WebStreamScreenState();
}

class _WebStreamScreenState extends State<WebStreamScreen> {
  late final WebViewController _web;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final originalHost = widget.uri.host.toLowerCase();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (value) { if (mounted) setState(() => _progress = value); },
        onPageFinished: (_) { if (mounted) setState(() => _progress = 100); },
        onWebResourceError: (error) { if (error.isForMainFrame == true && mounted) setState(() => _error = error.description); },
        onNavigationRequest: (request) {
          final target = Uri.tryParse(request.url);
          if (target == null) return NavigationDecision.prevent;
          if (target.scheme == 'about' && target.path == 'blank') return NavigationDecision.navigate;
          if (target.scheme != 'https') return NavigationDecision.prevent;
          // Keep top-level browsing on the source site. HTTPS iframe resources
          // remain available so legitimate embedded players can load normally.
          if (request.isMainFrame && target.host.toLowerCase() != originalHost) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(widget.uri);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: _bg,
      title: Text('مشغل المصدر · ${widget.uri.host}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w800)),
      actions: [IconButton(tooltip: 'إعادة تحميل', onPressed: () { setState(() { _progress = 0; _error = null; }); _web.reload(); }, icon: const Icon(LucideIcons.refreshCw, color: _mint))],
    ),
    body: Column(children: [
      Container(width: double.infinity, color: _panel, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), child: const Text('صفحة خارجية داخل التطبيق. اضغط على الفيديو في الصفحة لبدء التشغيل. لا تدخل بيانات حسابك أو كلمات مرور في صفحات غير موثوقة.', style: TextStyle(color: _muted, fontSize: 10, height: 1.5))),
      if (_progress < 100) LinearProgressIndicator(value: _progress / 100, minHeight: 2, color: _mint, backgroundColor: _line),
      if (_error != null) Padding(padding: const EdgeInsets.all(10), child: Text('تعذر تحميل جزء من الصفحة: $_error', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10))),
      Expanded(child: WebViewWidget(controller: _web)),
    ]),
  );
}

class _Logo extends StatelessWidget {
  const _Logo({required this.url, required this.label});
  final String url;
  final String label;
  @override
  Widget build(BuildContext context) => Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: _panel2, borderRadius: BorderRadius.circular(11)), child: url.isEmpty ? Text(label.isEmpty ? '?' : label[0], style: const TextStyle(color: _mint, fontWeight: FontWeight.w900)) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url, width: 34, height: 34, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Text(label.isEmpty ? '?' : label[0], style: const TextStyle(color: _mint, fontWeight: FontWeight.w900)))));
}

class _StreamState extends StatelessWidget {
  const _StreamState({required this.icon, required this.title, required this.subtitle, this.retry});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: _line)), child: Column(children: [Icon(icon, color: _mint, size: 34), const SizedBox(height: 10), Text(title, style: const TextStyle(color: _text, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 11, height: 1.6)), if (retry != null) Padding(padding: const EdgeInsets.only(top: 12), child: OutlinedButton.icon(onPressed: retry, icon: const Icon(LucideIcons.refreshCw, size: 16), label: const Text('إعادة المحاولة')))]));
}
