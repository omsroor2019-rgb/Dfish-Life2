/// البطولات المعتمدة في DFISH LIVE: الدوريات الكبرى، الخليج واليمن،
/// والبطولات القارية والعالمية الرئيسية.
class LeagueCatalog {
  LeagueCatalog._();

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static List<String> _allowedNamesForCountry(String country) {
    final key = _normalize(country);
    for (final entry in _allowed.entries) {
      if (_normalize(entry.key) == key) return entry.value.map(_normalize).toList();
    }
    return const [];
  }

  static String _arabicCountry(String country) {
    final key = _normalize(country);
    for (final entry in _arabicCountries.entries) {
      if (_normalize(entry.key) == key) return entry.value;
    }
    return country;
  }

  static String _arabicLeague(String country, String league) {
    final countryKey = _normalize(country);
    final leagueKey = _normalize(league);
    for (final entry in _arabicNames.entries) {
      final parts = entry.key.split('|');
      if (parts.length == 2 && _normalize(parts[0]) == countryKey && _normalize(parts[1]) == leagueKey) {
        return entry.value;
      }
    }
    return league;
  }

  static const Map<String, List<String>> _allowed = {
    'Saudi Arabia': ['pro league', 'saudi pro league'],
    'Brazil': ['serie a', 'brasileirão série a', 'brasileirao serie a'],
    'Argentina': ['liga profesional argentina', 'primera division', 'primera división'],
    'Mexico': ['liga mx', 'primera division'],
    'United States': ['major league soccer', 'mls'],
    'USA': ['major league soccer', 'mls'],
    'Egypt': ['premier league', 'egyptian premier league'],
    'Morocco': ['botola pro', 'botola'],
    'Algeria': ['ligue 1', 'algerian ligue 1'],
    'Tunisia': ['ligue 1', 'tunisian ligue 1'],
    'South Africa': ['premier soccer league', 'psl'],
    'United Arab Emirates': ['pro league', 'uae pro league'],
    'Qatar': ['stars league', 'qatar stars league'],
    'Bahrain': ['premier league', 'bahrain premier league'],
    'Kuwait': ['premier league', 'kuwait premier league', 'viva premier league'],
    'Oman': ['professional league', 'oman professional league'],
    'Yemen': ['yemeni league', 'yemen league', 'premier league'],
    'England': ['premier league'],
    'Spain': ['la liga', 'primera division', 'primera división'],
    'Italy': ['serie a'],
    'Germany': ['bundesliga'],
    'France': ['ligue 1'],
    'Netherlands': ['eredivisie'],
    'Portugal': ['primeira liga', 'liga portugal'],
    'Belgium': ['pro league', 'jupiler pro league'],
    'Türkiye': ['süper lig', 'super lig'],
    'Turkey': ['süper lig', 'super lig'],
    'Scotland': ['premiership'],
    'Greece': ['super league 1', 'super league'],
    'Austria': ['bundesliga'],
    'Switzerland': ['super league'],
    'Denmark': ['superliga'],
    'Norway': ['eliteserien'],
    'Sweden': ['allsvenskan'],
    'Russia': ['premier league'],
    'Ukraine': ['premier league'],
    'Czech Republic': ['first league'],
    'Poland': ['ekstraklasa'],
    'Croatia': ['hnl'],
    'Serbia': ['super liga'],
    'Japan': ['j1 league'],
    'South Korea': ['k league 1'],
    'China': ['super league'],
    'Iran': ['persian gulf pro league'],
    'Iraq': ['iraqi league'],
    'India': ['indian super league'],
    'Indonesia': ['liga 1'],
    'Thailand': ['thai league 1'],
    'Australia': ['a-league'],
    'Uzbekistan': ['super league'],
  };

  /// البطولات القارية المطلوبة فقط؛ لا نفتح كل الكؤوس المحلية.
  static const Set<String> _internationalCups = {
    'fifa world cup',
    'fifa club world cup',
    'uefa european championship',
    'european championship',
    'uefa champions league',
    'uefa europa league',
    'uefa europa conference league',
    'uefa conference league',
    'afc asian cup',
    'afc champions league elite',
    'afc champions league two',
    'afc champions league',
    'afc challenge league',
    'caf africa cup of nations',
    'africa cup of nations',
    'caf champions league',
    'concacaf champions cup',
    'concacaf champions league',
    'copa america',
    'conmebol copa america',
    'conmebol libertadores',
    'copa libertadores',
    'conmebol sudamericana',
    'copa sudamericana',
  };

  static const Map<String, int> _internationalPriorities = {
    'fifa world cup': 0,
    'uefa european championship': 1,
    'european championship': 1,
    'uefa champions league': 2,
    'fifa club world cup': 3,
    'uefa europa league': 4,
    'afc champions league elite': 4,
    'afc champions league': 5,
    'afc champions league two': 6,
    'conmebol libertadores': 6,
    'copa libertadores': 6,
    'copa america': 6,
    'conmebol copa america': 6,
    'caf africa cup of nations': 7,
    'africa cup of nations': 7,
    'concacaf champions cup': 7,
    'concacaf champions league': 7,
    'uefa europa conference league': 8,
    'uefa conference league': 8,
    'afc challenge league': 9,
    'caf champions league': 9,
    'conmebol sudamericana': 9,
    'copa sudamericana': 9,
    'afc asian cup': 5,
  };

  static const Map<String, String> _internationalArabicNames = {
    'fifa world cup': 'كأس العالم',
    'fifa club world cup': 'كأس العالم للأندية',
    'uefa european championship': 'بطولة أمم أوروبا',
    'european championship': 'بطولة أمم أوروبا',
    'uefa champions league': 'دوري أبطال أوروبا',
    'afc champions league elite': 'دوري أبطال آسيا للنخبة',
    'afc champions league two': 'دوري أبطال آسيا 2',
    'afc champions league': 'دوري أبطال آسيا',
    'uefa europa league': 'الدوري الأوروبي',
    'uefa europa conference league': 'دوري المؤتمر الأوروبي',
    'uefa conference league': 'دوري المؤتمر الأوروبي',
    'afc challenge league': 'دوري التحدي الآسيوي',
    'afc asian cup': 'كأس آسيا',
    'caf africa cup of nations': 'كأس أمم أفريقيا',
    'africa cup of nations': 'كأس أمم أفريقيا',
    'caf champions league': 'دوري أبطال أفريقيا',
    'concacaf champions cup': 'كأس أبطال الكونكاكاف',
    'concacaf champions league': 'دوري أبطال الكونكاكاف',
    'copa america': 'كوبا أمريكا',
    'conmebol copa america': 'كوبا أمريكا',
    'conmebol libertadores': 'كوبا ليبرتادوريس',
    'copa libertadores': 'كوبا ليبرتادوريس',
    'conmebol sudamericana': 'كوبا سود أمريكانا',
    'copa sudamericana': 'كوبا سود أمريكانا',
  };

  static const Map<String, String> _arabicNames = {
    'Saudi Arabia|pro league': 'دوري روشن السعودي',
    'Brazil|serie a': 'الدوري البرازيلي الممتاز',
    'Brazil|brasileirão série a': 'الدوري البرازيلي الممتاز',
    'Brazil|brasileirao serie a': 'الدوري البرازيلي الممتاز',
    'Argentina|liga profesional argentina': 'الدوري الأرجنتيني',
    'Argentina|primera division': 'الدوري الأرجنتيني',
    'Argentina|primera división': 'الدوري الأرجنتيني',
    'Mexico|liga mx': 'الدوري المكسيكي',
    'Mexico|primera division': 'الدوري المكسيكي',
    'United States|major league soccer': 'الدوري الأمريكي',
    'United States|mls': 'الدوري الأمريكي',
    'USA|major league soccer': 'الدوري الأمريكي',
    'USA|mls': 'الدوري الأمريكي',
    'Egypt|premier league': 'الدوري المصري الممتاز',
    'Egypt|egyptian premier league': 'الدوري المصري الممتاز',
    'Morocco|botola pro': 'الدوري المغربي',
    'Morocco|botola': 'الدوري المغربي',
    'Algeria|ligue 1': 'الدوري الجزائري',
    'Algeria|algerian ligue 1': 'الدوري الجزائري',
    'Tunisia|ligue 1': 'الدوري التونسي',
    'Tunisia|tunisian ligue 1': 'الدوري التونسي',
    'South Africa|premier soccer league': 'الدوري الجنوب أفريقي',
    'South Africa|psl': 'الدوري الجنوب أفريقي',
    'Saudi Arabia|saudi pro league': 'دوري روشن السعودي',
    'United Arab Emirates|pro league': 'دوري المحترفين الإماراتي',
    'United Arab Emirates|uae pro league': 'دوري المحترفين الإماراتي',
    'Qatar|stars league': 'دوري نجوم قطر',
    'Qatar|qatar stars league': 'دوري نجوم قطر',
    'Bahrain|premier league': 'الدوري البحريني الممتاز',
    'Bahrain|bahrain premier league': 'الدوري البحريني الممتاز',
    'Kuwait|premier league': 'الدوري الكويتي الممتاز',
    'Kuwait|kuwait premier league': 'الدوري الكويتي الممتاز',
    'Kuwait|viva premier league': 'الدوري الكويتي الممتاز',
    'Oman|professional league': 'الدوري العماني للمحترفين',
    'Oman|oman professional league': 'الدوري العماني للمحترفين',
    'Yemen|yemeni league': 'الدوري اليمني',
    'Yemen|yemen league': 'الدوري اليمني',
    'Yemen|premier league': 'الدوري اليمني',
    'England|premier league': 'الدوري الإنجليزي الممتاز',
    'Spain|la liga': 'الدوري الإسباني',
    'Spain|primera division': 'الدوري الإسباني',
    'Spain|primera división': 'الدوري الإسباني',
    'Italy|serie a': 'الدوري الإيطالي',
    'Germany|bundesliga': 'الدوري الألماني',
    'France|ligue 1': 'الدوري الفرنسي',
    'Netherlands|eredivisie': 'الدوري الهولندي الممتاز',
    'Portugal|primeira liga': 'الدوري البرتغالي الممتاز',
    'Portugal|liga portugal': 'الدوري البرتغالي الممتاز',
    'Belgium|pro league': 'الدوري البلجيكي الممتاز',
    'Belgium|jupiler pro league': 'الدوري البلجيكي الممتاز',
    'Türkiye|süper lig': 'الدوري التركي الممتاز',
    'Türkiye|super lig': 'الدوري التركي الممتاز',
    'Turkey|süper lig': 'الدوري التركي الممتاز',
    'Turkey|super lig': 'الدوري التركي الممتاز',
    'Scotland|premiership': 'الدوري الاسكتلندي الممتاز',
    'Greece|super league 1': 'الدوري اليوناني الممتاز',
    'Greece|super league': 'الدوري اليوناني الممتاز',
    'Austria|bundesliga': 'الدوري النمساوي الممتاز',
    'Switzerland|super league': 'الدوري السويسري الممتاز',
    'Denmark|superliga': 'الدوري الدنماركي الممتاز',
    'Norway|eliteserien': 'الدوري النرويجي الممتاز',
    'Sweden|allsvenskan': 'الدوري السويدي الممتاز',
    'Russia|premier league': 'الدوري الروسي الممتاز',
    'Ukraine|premier league': 'الدوري الأوكراني الممتاز',
    'Czech Republic|first league': 'الدوري التشيكي الممتاز',
    'Poland|ekstraklasa': 'الدوري البولندي الممتاز',
    'Croatia|hnl': 'الدوري الكرواتي الممتاز',
    'Serbia|super liga': 'الدوري الصربي الممتاز',
    'Japan|j1 league': 'الدوري الياباني الممتاز',
    'South Korea|k league 1': 'الدوري الكوري الجنوبي الممتاز',
    'China|super league': 'الدوري الصيني الممتاز',
    'Iran|persian gulf pro league': 'الدوري الإيراني الممتاز',
    'Iraq|iraqi league': 'الدوري العراقي الممتاز',
    'India|indian super league': 'الدوري الهندي الممتاز',
    'Indonesia|liga 1': 'الدوري الإندونيسي الممتاز',
    'Thailand|thai league 1': 'الدوري التايلاندي الممتاز',
    'Australia|a-league': 'الدوري الأسترالي',
    'Uzbekistan|super league': 'الدوري الأوزبكي الممتاز',
  };

  static const Map<String, String> _arabicCountries = {
    'Saudi Arabia': 'السعودية',
    'Brazil': 'البرازيل',
    'Argentina': 'الأرجنتين',
    'Mexico': 'المكسيك',
    'United States': 'الولايات المتحدة',
    'USA': 'الولايات المتحدة',
    'Egypt': 'مصر',
    'Morocco': 'المغرب',
    'Algeria': 'الجزائر',
    'Tunisia': 'تونس',
    'South Africa': 'جنوب أفريقيا',
    'United Arab Emirates': 'الإمارات',
    'Qatar': 'قطر',
    'Bahrain': 'البحرين',
    'Kuwait': 'الكويت',
    'Oman': 'عُمان',
    'Yemen': 'اليمن',
    'England': 'إنجلترا',
    'Spain': 'إسبانيا',
    'Italy': 'إيطاليا',
    'Germany': 'ألمانيا',
    'France': 'فرنسا',
    'Netherlands': 'هولندا',
    'Portugal': 'البرتغال',
    'Belgium': 'بلجيكا',
    'Türkiye': 'تركيا',
    'Turkey': 'تركيا',
    'Scotland': 'اسكتلندا',
    'Greece': 'اليونان',
    'Austria': 'النمسا',
    'Switzerland': 'سويسرا',
    'Denmark': 'الدنمارك',
    'Norway': 'النرويج',
    'Sweden': 'السويد',
    'Russia': 'روسيا',
    'Ukraine': 'أوكرانيا',
    'Czech Republic': 'التشيك',
    'Poland': 'بولندا',
    'Croatia': 'كرواتيا',
    'Serbia': 'صربيا',
    'Japan': 'اليابان',
    'South Korea': 'كوريا الجنوبية',
    'China': 'الصين',
    'Iran': 'إيران',
    'Iraq': 'العراق',
    'India': 'الهند',
    'Indonesia': 'إندونيسيا',
    'Thailand': 'تايلاند',
    'Australia': 'أستراليا',
    'Uzbekistan': 'أوزبكستان',
    'World': 'دولي',
    'Asia': 'آسيا',
  };

  static String countryName(Map<String, dynamic> item) {
    final country = item['country'];
    if (country is Map) return country['name']?.toString() ?? '';
    return country?.toString() ?? '';
  }

  static String originalLeagueName(Map<String, dynamic> item) {
    final league = item['league'];
    if (league is Map) return league['name']?.toString() ?? '';
    return '';
  }

  static bool isAllowed(Map<String, dynamic> item) {
    final league = item['league'];
    if (league is! Map) return false;
    final name = _normalize((league['name'] ?? '').toString());
    final type = _normalize((league['type'] ?? '').toString());
    if (_internationalCups.map(_normalize).contains(name)) {
      return type.isEmpty || type == 'cup' || type == 'league';
    }
    if (type != 'league') return false;
    return _allowedNamesForCountry(countryName(item)).contains(name);
  }

  static String displayName(Map<String, dynamic> item) =>
      displayNameFor(countryName(item), originalLeagueName(item));

  static String displayNameFor(String country, String leagueName) {
    final name = _normalize(leagueName);
    for (final entry in _internationalArabicNames.entries) {
      if (_normalize(entry.key) == name) return entry.value;
    }
    return _arabicLeague(country, leagueName);
  }

  static String displayCountry(Map<String, dynamic> item) =>
      displayCompetitionCountry(countryName(item), originalLeagueName(item));

  static String displayCompetitionCountry(String country, String leagueName) {
    final name = _normalize(leagueName);
    if (name.startsWith('uefa ') || name == 'european championship') {
      return 'أوروبا';
    }
    if (name.contains('afc') || name.contains('asian cup')) return 'آسيا';
    if (name.contains('caf') || name.contains('africa')) return 'أفريقيا';
    if (name.contains('concacaf')) return 'أمريكا الشمالية';
    if (name.contains('conmebol') || name.contains('copa')) {
      return 'أمريكا الجنوبية';
    }
    if (name.contains('fifa')) return 'دولي';
    return displayCountryName(country);
  }

  static String displayCountryName(String country) => _arabicCountry(country);

  /// Fixture responses use league.country as a string rather than an object.
  /// تقبل المسابقات القارية المحددة حتى لو كان نوعها Cup.
  static bool isAllowedFixture(Map<String, dynamic> fixture) {
    final league = fixture['league'];
    if (league is! Map) return false;
    final country = (league['country'] ?? '').toString();
    final name = _normalize((league['name'] ?? '').toString());
    if (_internationalCups.map(_normalize).contains(name)) return true;
    return _allowedNamesForCountry(country).contains(name);
  }

  /// أولوية البطولة للاستخدام في ترتيب قائمة المباريات. الرقم الأصغر أهم.
  static int fixturePriority(Map<String, dynamic> fixture) {
    final league = fixture['league'];
    if (league is! Map) return 999;
    final name = _normalize((league['name'] ?? '').toString());
    final international = _internationalPriorities[name];
    if (international != null) return international;

    final country = _normalize((league['country'] ?? '').toString());
    const countryPriority = <String, int>{
      'england': 10,
      'spain': 11,
      'italy': 12,
      'germany': 13,
      'france': 14,
      'saudi arabia': 15,
      'yemen': 16,
      'united arab emirates': 17,
      'qatar': 18,
      'bahrain': 19,
      'kuwait': 20,
      'oman': 21,
      'brazil': 22,
      'argentina': 23,
      'mexico': 24,
      'united states': 25,
      'usa': 25,
      'egypt': 26,
      'morocco': 27,
      'algeria': 28,
      'tunisia': 29,
      'south africa': 30,
      'netherlands': 31,
      'portugal': 32,
      'belgium': 33,
      'türkiye': 34,
      'turkey': 34,
      'scotland': 35,
      'greece': 36,
      'japan': 45,
      'south korea': 46,
      'china': 47,
      'iran': 48,
      'iraq': 49,
      'australia': 50,
      'india': 51,
      'indonesia': 52,
      'thailand': 53,
      'uzbekistan': 54,
    };
    return countryPriority[country] ?? 80;
  }

  /// أولوية حالة المباراة داخل ترتيب البطولة: مباشر، قادمة، منتهية، مؤجلة.
  static int fixtureStatusPriority(Map<String, dynamic> fixture) {
    final fixtureData = fixture['fixture'];
    final statusData = fixtureData is Map ? fixtureData['status'] : null;
    final status = _normalize(
      statusData is Map ? (statusData['short'] ?? '').toString() : '',
    );
    if (const {'1h', 'ht', '2h', 'et', 'bt', 'p', 'live', 'susp', 'int'}
        .contains(status)) return 0;
    if (const {'ns', 'tbd'}.contains(status)) return 1;
    if (const {'ft', 'aet', 'pen', 'awd', 'wo'}.contains(status)) return 2;
    if (const {'pst', 'canc', 'abd'}.contains(status)) return 3;
    return 4;
  }

  /// المقارنة الموحدة لقائمة مباريات اليوم: أهمية البطولة ثم الحالة ثم وقت البدء.
  static int compareFixtures(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final leagueOrder = fixturePriority(a).compareTo(fixturePriority(b));
    if (leagueOrder != 0) return leagueOrder;
    final statusOrder =
        fixtureStatusPriority(a).compareTo(fixtureStatusPriority(b));
    if (statusOrder != 0) return statusOrder;
    final aDate = (a['fixture'] is Map)
        ? ((a['fixture'] as Map)['date']?.toString() ?? '')
        : '';
    final bDate = (b['fixture'] is Map)
        ? ((b['fixture'] as Map)['date']?.toString() ?? '')
        : '';
    return aDate.compareTo(bDate);
  }

  static int priority(Map<String, dynamic> item) {
    final leagueName = _normalize(originalLeagueName(item));
    final international = _internationalPriorities[leagueName];
    if (international != null) return international;

    final country = _normalize(countryName(item));
    const countryOrder = [
      'Saudi Arabia', 'Yemen', 'United Arab Emirates', 'Qatar', 'Bahrain',
      'Kuwait', 'Oman', 'England', 'Spain', 'Italy', 'Germany', 'France',
      'Brazil', 'Argentina', 'Mexico', 'United States', 'USA', 'Egypt',
      'Morocco', 'Algeria', 'Tunisia', 'South Africa',
      'Netherlands', 'Portugal', 'Belgium', 'Türkiye', 'Turkey', 'Scotland',
      'Greece', 'Austria', 'Switzerland', 'Denmark', 'Norway', 'Sweden',
      'Russia', 'Ukraine', 'Czech Republic', 'Poland', 'Croatia', 'Serbia',
      'Japan', 'South Korea', 'China', 'Iran', 'Iraq', 'India', 'Indonesia',
      'Thailand', 'Australia', 'Uzbekistan',
    ];
    final index = countryOrder.indexWhere((value) => _normalize(value) == country);
    return index < 0 ? 999 : index + 10;
  }

  static Map<String, dynamic>? seasonInfo(Map<String, dynamic> item, int year) {
    final seasons = item['seasons'];
    if (seasons is! List) return null;
    for (final season in seasons) {
      if (season is Map && (season['year'] as num?)?.toInt() == year) {
        return Map<String, dynamic>.from(season);
      }
    }
    return null;
  }

  static bool supports(Map<String, dynamic> item, int year, String feature) {
    final info = seasonInfo(item, year);
    final coverage = info?['coverage'];
    if (coverage is! Map || !coverage.containsKey(feature)) return true;
    return coverage[feature] == true;
  }
}
