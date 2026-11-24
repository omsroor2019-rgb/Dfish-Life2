/// قائمة الدوريات التي يعرضها DFISH LIVE: دوريات الخليج واليمن
/// والدرجة الأولى في أبرز الدوريات الأوروبية فقط.
class LeagueCatalog {
  LeagueCatalog._();

  static const Map<String, List<String>> _allowed = {
    'Saudi Arabia': ['pro league', 'saudi pro league'],
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
  };

  /// البطولات القارية المطلوبة فقط؛ لا نفتح كل الكؤوس المحلية.
  static const Set<String> _internationalCups = {
    'uefa champions league',
    'afc champions league elite',
    'afc champions league two',
    'afc champions league',
  };

  static const Map<String, String> _internationalArabicNames = {
    'uefa champions league': 'دوري أبطال أوروبا',
    'afc champions league elite': 'دوري أبطال آسيا للنخبة',
    'afc champions league two': 'دوري أبطال آسيا 2',
    'afc champions league': 'دوري أبطال آسيا',
  };

  static const Map<String, String> _arabicNames = {
    'Saudi Arabia|pro league': 'دوري روشن السعودي',
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
  };

  static const Map<String, String> _arabicCountries = {
    'Saudi Arabia': 'السعودية',
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
    final name = (league['name'] ?? '').toString().trim().toLowerCase();
    final type = (league['type'] ?? '').toString().toLowerCase();
    if (_internationalCups.contains(name)) {
      return type.isEmpty || type == 'cup' || type == 'league';
    }
    if (type != 'league') return false;
    final allowedNames = _allowed[countryName(item)];
    return allowedNames != null && allowedNames.contains(name);
  }

  static String displayName(Map<String, dynamic> item) =>
      displayNameFor(countryName(item), originalLeagueName(item));

  static String displayNameFor(String country, String leagueName) {
    final name = leagueName.trim().toLowerCase();
    return _internationalArabicNames[name] ?? _arabicNames['$country|$name'] ?? leagueName;
  }

  static String displayCountry(Map<String, dynamic> item) =>
      displayCompetitionCountry(countryName(item), originalLeagueName(item));

  static String displayCompetitionCountry(String country, String leagueName) {
    final name = leagueName.trim().toLowerCase();
    if (name == 'uefa champions league') return 'أوروبا';
    if (_internationalCups.contains(name)) return 'آسيا';
    return displayCountryName(country);
  }

  static String displayCountryName(String country) =>
      _arabicCountries[country] ?? country;

  /// Fixture responses use league.country as a string rather than an object.
  /// تقبل المسابقات القارية المحددة حتى لو كان نوعها Cup.
  static bool isAllowedFixture(Map<String, dynamic> fixture) {
    final league = fixture['league'];
    if (league is! Map) return false;
    final country = (league['country'] ?? '').toString();
    final name = (league['name'] ?? '').toString().trim().toLowerCase();
    if (_internationalCups.contains(name)) return true;
    return (_allowed[country] ?? const <String>[]).contains(name);
  }

  static int priority(Map<String, dynamic> item) {
    final name = originalLeagueName(item).trim().toLowerCase();
    if (name == 'uefa champions league') return 0;
    if (_internationalCups.contains(name)) return 1;
    const countryOrder = [
      'Saudi Arabia', 'Yemen', 'United Arab Emirates', 'Qatar', 'Bahrain',
      'Kuwait', 'Oman', 'England', 'Spain', 'Italy', 'Germany', 'France',
      'Netherlands', 'Portugal', 'Belgium', 'Türkiye', 'Turkey', 'Scotland',
      'Greece', 'Austria', 'Switzerland', 'Denmark', 'Norway', 'Sweden',
      'Russia', 'Ukraine', 'Czech Republic', 'Poland', 'Croatia', 'Serbia',
    ];
    final index = countryOrder.indexOf(countryName(item));
    return index < 0 ? 999 : index + 2;
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
