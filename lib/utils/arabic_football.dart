/// Arabic labels used by both API-Football and Highlightly screens.
/// Unknown player/team proper names are intentionally preserved rather than
/// being mistranslated by an unreliable generic transliteration.
class ArabicFootball {
  ArabicFootball._();

  static String text(dynamic value, {String fallback = '—'}) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return fallback;
    final key = _normalize(raw);
    return _labels[key] ?? _clubs[key] ?? _players[key] ?? _countries[key] ?? raw;
  }

  /// Translate only names explicitly present in the club dictionary.
  /// Team names are proper nouns: an unknown name must remain unchanged,
  /// even when it happens to normalize to a generic label such as 'unknown'.
  static String team(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return 'الفريق';
    return _clubs[_normalize(raw)] ?? raw;
  }
  static String country(String value) => _countries[_normalize(value)] ?? value;

  static String league(String value, [String countryName = '']) {
    final direct = _leagues[_normalize(value)];
    if (direct != null) return direct;
    final countryKey = _normalize(countryName);
    if (countryKey == 'england' && _normalize(value) == 'premier league') {
      return 'الدوري الإنجليزي الممتاز';
    }
    if (countryKey == 'yemen' && _normalize(value).contains('league')) {
      return 'الدوري اليمني';
    }
    return text(value);
  }

  static String _normalize(String value) {
    var result = value.trim().toLowerCase().replaceAll(RegExp(r"[’'`.]"), '');
    const accents = <String, String>{
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', 'ñ': 'n', 'ç': 'c',
    };
    accents.forEach((from, to) => result = result.replaceAll(from, to));
    if (result.startsWith('fc ')) result = result.substring(3);
    result = result.replaceAll(RegExp(r'\s+(fc|cf|sc|club)$'), '');
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const Map<String, String> _labels = {
    'not started': 'لم تبدأ', 'to be announced': 'الموعد يحدد لاحقاً',
    'first half': 'الشوط الأول', 'second half': 'الشوط الثاني',
    'half time': 'استراحة بين الشوطين', 'extra time': 'وقت إضافي',
    'break time': 'استراحة إضافية', 'penalties': 'ركلات الترجيح',
    'finished': 'انتهت المباراة', 'finished after penalties': 'انتهت بركلات الترجيح',
    'finished after extra time': 'انتهت بعد الوقت الإضافي',
    'postponed': 'مؤجلة', 'suspended': 'معلّقة', 'interrupted': 'متوقفة مؤقتاً',
    'cancelled': 'ملغاة', 'abandoned': 'أُلغيت بعد بدايتها', 'awarded': 'نتيجة إدارية',
    'in progress': 'جارية', 'unknown': 'غير معروفة',
    'goal': 'هدف', 'own goal': 'هدف عكسي', 'penalty': 'ركلة جزاء',
    'saved': 'تصدى لها الحارس', 'missed': 'خارج المرمى', 'blocked': 'تم اعتراضها',
    'on target': 'على المرمى', 'high left': 'الزاوية العليا اليسرى', 'high right': 'الزاوية العليا اليمنى',
    'low left': 'الزاوية السفلى اليسرى', 'low right': 'الزاوية السفلى اليمنى', 'middle': 'المنتصف',
    'missed penalty': 'ركلة جزاء ضائعة', 'yellow card': 'بطاقة صفراء',
    'red card': 'بطاقة حمراء', 'substitution': 'تبديل',
    'var goal confirmed': 'تأكيد الهدف عبر تقنية الفيديو',
    'var goal cancelled': 'إلغاء الهدف عبر تقنية الفيديو',
    'var goal cancelled - offside': 'إلغاء الهدف بداعي التسلل بعد مراجعة الفيديو',
    'var penalty': 'احتساب ركلة جزاء بعد مراجعة الفيديو',
    'var penalty cancelled': 'إلغاء ركلة الجزاء بعد مراجعة الفيديو',
    'goalkeeper': 'حارس مرمى', 'defender': 'مدافع', 'midfielder': 'لاعب وسط',
    'forward': 'مهاجم', 'right winger': 'جناح أيمن', 'left winger': 'جناح أيسر',
    'right back': 'ظهير أيمن', 'left back': 'ظهير أيسر', 'full back': 'ظهير',
    'centre back': 'قلب دفاع', 'center back': 'قلب دفاع', 'left centre back': 'قلب دفاع أيسر',
    'right centre back': 'قلب دفاع أيمن', 'left center back': 'قلب دفاع أيسر', 'right center back': 'قلب دفاع أيمن',
    'central midfielder': 'لاعب وسط مركزي', 'left midfield': 'وسط أيسر', 'right midfield': 'وسط أيمن',
    'left midfielder': 'وسط أيسر', 'right midfielder': 'وسط أيمن', 'winger': 'جناح',
    'centre forward': 'رأس حربة', 'center forward': 'رأس حربة', 'second striker': 'مهاجم ثانٍ',
    'sweeper': 'ليبرو',
    'striker': 'مهاجم صريح', 'attacking midfielder': 'وسط هجومي',
    'defensive midfielder': 'وسط دفاعي', 'both': 'كلتا القدمين', 'right': 'اليمنى', 'left': 'اليسرى',
    'cloudy': 'غائم', 'clear': 'صحو', 'sunny': 'مشمس', 'rain': 'ممطر', 'rainy': 'ممطر',
    'light rain': 'أمطار خفيفة', 'heavy rain': 'أمطار غزيرة', 'overcast': 'غائم كلياً', 'snow': 'ثلوج',
    'muscle injury': 'إصابة عضلية', 'hamstring injury': 'إصابة في العضلة الخلفية',
    'knee injury': 'إصابة في الركبة', 'ankle injury': 'إصابة في الكاحل',
    'calf injury': 'إصابة في عضلة الساق', 'ligament injury': 'إصابة في الأربطة',
    'cruciate ligament injury': 'إصابة في الرباط الصليبي', 'illness': 'مرض', 'suspension': 'إيقاف',
    'possession': 'الاستحواذ', 'ball possession': 'الاستحواذ', 'goals': 'الأهداف',
    'shots blocked': 'تسديدات تم اعتراضها', 'blocked shots': 'تسديدات تم اعتراضها',
    'shots inside box': 'تسديدات من داخل المنطقة', 'shots outside box': 'تسديدات من خارج المنطقة',
    'big chances': 'فرص محققة', 'big chances missed': 'فرص محققة ضائعة',
    'fouls committed': 'الأخطاء المرتكبة', 'fouls suffered': 'الأخطاء التي تعرض لها',
    'fouls received': 'الأخطاء التي تعرض لها', 'total tackles': 'إجمالي التدخلات',
    'total interceptions': 'إجمالي الاعتراضات', 'clearances': 'الإبعادات',
    'long balls': 'الكرات الطويلة',
    'crosses': 'العرضيات', 'accurate crosses': 'العرضيات الصحيحة',
    'duels': 'الالتحامات', 'aerial duels won': 'الالتحامات الهوائية الناجحة',
    'ground duels won': 'الالتحامات الأرضية الناجحة', 'recoveries': 'استعادة الكرة',
    'possession lost': 'فقدان الكرة', 'touches': 'لمسات الكرة',
    'shots on target': 'تسديدات على المرمى', 'shots off target': 'تسديدات خارج المرمى',
    'shots off goal': 'تسديدات خارج المرمى', 'total shots': 'إجمالي التسديدات',
    'shots accuracy': 'دقة التسديد', 'corners': 'الركلات الركنية', 'corner kicks': 'الركلات الركنية',
    'fouls': 'الأخطاء', 'offsides': 'التسلل', 'yellow cards': 'البطاقات الصفراء',
    'red cards': 'البطاقات الحمراء', 'saves': 'تصديات الحارس', 'goalkeeper saves': 'تصديات الحارس',
    'passes': 'التمريرات', 'total passes': 'إجمالي التمريرات',
    'accurate passes': 'التمريرات الصحيحة', 'passes accurate': 'التمريرات الصحيحة',
    'pass accuracy': 'دقة التمرير', 'expected goals': 'الأهداف المتوقعة',
    'expected assists': 'التمريرات الحاسمة المتوقعة', 'tackles': 'التدخلات',
    'interceptions': 'الاعتراضات', 'duels won': 'الالتحامات الناجحة',
    'dribbles successful': 'المراوغات الناجحة', 'total': 'الإجمالي',
    'home': 'داخل الأرض', 'away': 'خارج الأرض', 'regular season': 'الموسم العادي',
    'round of 16': 'دور الـ16', 'quarter-finals': 'ربع النهائي',
    'premier league - regular season': 'الدوري الممتاز - الموسم العادي',
    'league': 'دوري', 'cup': 'كأس',
    'semi-finals': 'نصف النهائي', 'final': 'النهائي',
    'transfer': 'انتقال', 'loan': 'إعارة', 'end of loan': 'نهاية الإعارة',
    'retired': 'اعتزال', 'national league': 'دوري محلي',
    'national cup': 'كأس محلي', 'international cup': 'بطولة دولية',
  };

  static const Map<String, String> _leagues = {
    'premier league': 'الدوري الإنجليزي الممتاز',
    'english premier league': 'الدوري الإنجليزي الممتاز',
    'la liga': 'الدوري الإسباني', 'primera division': 'الدوري الإسباني',
    'serie a': 'الدوري الإيطالي', 'bundesliga': 'الدوري الألماني',
    'ligue 1': 'الدوري الفرنسي', 'eredivisie': 'الدوري الهولندي الممتاز',
    'primeira liga': 'الدوري البرتغالي الممتاز', 'liga portugal': 'الدوري البرتغالي الممتاز',
    'uefa champions league': 'دوري أبطال أوروبا',
    'afc champions league elite': 'دوري أبطال آسيا للنخبة',
    'afc champions league two': 'دوري أبطال آسيا 2',
    'afc champions league': 'دوري أبطال آسيا',
    'uefa europa league': 'الدوري الأوروبي',
    'uefa europa conference league': 'دوري المؤتمر الأوروبي',
    'fa cup': 'كأس الاتحاد الإنجليزي', 'efl cup': 'كأس الرابطة الإنجليزية',
    'copa del rey': 'كأس ملك إسبانيا', 'coppa italia': 'كأس إيطاليا',
    'dfb pokal': 'كأس ألمانيا', 'fifa world cup': 'كأس العالم',
    'saudi pro league': 'دوري روشن السعودي', 'roshn saudi league': 'دوري روشن السعودي',
    'pro league': 'الدوري المحترف', 'stars league': 'دوري نجوم قطر',
    'qatar stars league': 'دوري نجوم قطر', 'yemeni league': 'الدوري اليمني',
    'yemen league': 'الدوري اليمني', 'iraqi league': 'الدوري العراقي',
    'persian gulf pro league': 'الدوري الإيراني الممتاز', 'j1 league': 'الدوري الياباني الممتاز',
    'k league 1': 'الدوري الكوري الجنوبي', 'mls': 'الدوري الأمريكي',
  };

  static const Map<String, String> _players = {
    'cristiano ronaldo': 'كريستيانو رونالدو', 'lionel messi': 'ليونيل ميسي',
    'mohamed salah': 'محمد صلاح', 'kylian mbappe': 'كيليان مبابي',
    'erling haaland': 'إيرلينغ هالاند', 'neymar jr': 'نيمار جونيور',
    'neymar': 'نيمار', 'karim benzema': 'كريم بنزيما',
    'vinicius junior': 'فينيسيوس جونيور', 'jude bellingham': 'جود بيلينغهام',
    'kevin de bruyne': 'كيفن دي بروين', 'harry kane': 'هاري كين',
    'robert lewandowski': 'روبرت ليفاندوفسكي', 'lamine yamal': 'لامين يامال',
    'bukayo saka': 'بوكايو ساكا', 'bruno fernandes': 'برونو فيرنانديز',
    'son heung min': 'سون هيونغ مين', 'phil foden': 'فيل فودين',
    'virgil van dijk': 'فيرجيل فان دايك', 'declan rice': 'ديكلان رايس',
    'pedri': 'بيدري', 'gavi': 'غافي', 'federico valverde': 'فيديريكو فالفيردي',
    'thibaut courtois': 'تيبو كورتوا', 'alisson becker': 'أليسون بيكر',
    'rodri': 'رودري', 'lautaro martinez': 'لاوتارو مارتينيز',
    'paulo dybala': 'باولو ديبالا', 'sadio mane': 'ساديو ماني',
    'riyad mahrez': 'رياض محرز', 'salem al dawsari': 'سالم الدوسري',
  };

  static const Map<String, String> _countries = {
    'saudi arabia': 'السعودية', 'united arab emirates': 'الإمارات',
    'uae': 'الإمارات', 'qatar': 'قطر', 'bahrain': 'البحرين', 'kuwait': 'الكويت',
    'oman': 'عُمان', 'yemen': 'اليمن', 'iraq': 'العراق', 'iran': 'إيران',
    'england': 'إنجلترا', 'spain': 'إسبانيا', 'italy': 'إيطاليا',
    'germany': 'ألمانيا', 'france': 'فرنسا', 'netherlands': 'هولندا', 'austria': 'النمسا', 'switzerland': 'سويسرا',
    'denmark': 'الدنمارك', 'norway': 'النرويج', 'sweden': 'السويد', 'russia': 'روسيا',
    'ukraine': 'أوكرانيا', 'czech republic': 'التشيك', 'poland': 'بولندا',
    'croatia': 'كرواتيا', 'serbia': 'صربيا', 'finland': 'فنلندا', 'romania': 'رومانيا',
    'hungary': 'المجر', 'bulgaria': 'بلغاريا', 'cyprus': 'قبرص', 'georgia': 'جورجيا',
    'uzbekistan': 'أوزبكستان', 'kazakhstan': 'كازاخستان', 'lebanon': 'لبنان',
    'jordan': 'الأردن', 'syria': 'سوريا', 'palestine': 'فلسطين', 'south africa': 'جنوب أفريقيا',
    'senegal': 'السنغال', 'ghana': 'غانا', 'nigeria': 'نيجيريا', 'cameroon': 'الكاميرون',
    'ivory coast': 'ساحل العاج', 'cote d ivoire': 'ساحل العاج', 'mexico': 'المكسيك',
    'canada': 'كندا', 'uruguay': 'أوروغواي', 'chile': 'تشيلي', 'colombia': 'كولومبيا',
    'paraguay': 'باراغواي', 'peru': 'بيرو', 'ecuador': 'الإكوادور',
    'portugal': 'البرتغال', 'belgium': 'بلجيكا', 'turkey': 'تركيا',
    'türkiye': 'تركيا', 'scotland': 'اسكتلندا', 'greece': 'اليونان',
    'japan': 'اليابان', 'south korea': 'كوريا الجنوبية', 'china': 'الصين',
    'india': 'الهند', 'indonesia': 'إندونيسيا', 'thailand': 'تايلاند',
    'australia': 'أستراليا', 'world': 'العالم', 'europe': 'أوروبا', 'asia': 'آسيا',
    'ireland': 'أيرلندا', 'wales': 'ويلز', 'northern ireland': 'أيرلندا الشمالية',
    'united states': 'الولايات المتحدة', 'usa': 'الولايات المتحدة',
    'brazil': 'البرازيل', 'argentina': 'الأرجنتين', 'morocco': 'المغرب',
    'egypt': 'مصر', 'tunisia': 'تونس', 'algeria': 'الجزائر',
  };

  static const Map<String, String> _clubs = {
    'manchester city': 'مانشستر سيتي', 'manchester united': 'مانشستر يونايتد',
    'liverpool': 'ليفربول', 'arsenal': 'أرسنال', 'chelsea': 'تشيلسي',
    'tottenham': 'توتنهام', 'tottenham hotspur': 'توتنهام', 'newcastle united': 'نيوكاسل يونايتد', 'west ham united': 'وست هام يونايتد',
    'aston villa': 'أستون فيلا', 'brighton': 'برايتون', 'brighton and hove albion': 'برايتون',
    'wolverhampton wanderers': 'وولفرهامبتون', 'wolves': 'وولفرهامبتون',
    'crystal palace': 'كريستال بالاس', 'everton': 'إيفرتون', 'fulham': 'فولهام',
    'nottingham forest': 'نوتنغهام فورست', 'brentford': 'برينتفورد',
    'bournemouth': 'بورنموث', 'burnley': 'بيرنلي', 'leeds united': 'ليدز يونايتد',
    'sunderland': 'سندرلاند', 'leicester city': 'ليستر سيتي', 'ipswich town': 'إيبسويتش تاون',
    'real madrid': 'ريال مدريد', 'barcelona': 'برشلونة', 'atletico madrid': 'أتلتيكو مدريد',
    'atletico de madrid': 'أتلتيكو مدريد', 'sevilla': 'إشبيلية', 'valencia': 'فالنسيا',
    'girona': 'جيرونا', 'athletic club': 'أتلتيك بلباو', 'real sociedad': 'ريال سوسيداد', 'real betis': 'ريال بيتيس', 'villarreal': 'فياريال',
    'celta vigo': 'سيلتا فيغو', 'osasuna': 'أوساسونا', 'getafe': 'خيتافي', 'mallorca': 'ريال مايوركا',
    'inter': 'إنتر ميلان', 'inter milan': 'إنتر ميلان', 'ac milan': 'إيه سي ميلان',
    'juventus': 'يوفنتوس', 'napoli': 'نابولي', 'roma': 'روما', 'lazio': 'لاتسيو',
    'atalanta': 'أتالانتا', 'bayern munich': 'بايرن ميونخ', 'borussia dortmund': 'بوروسيا دورتموند',
    'bayer leverkusen': 'باير ليفركوزن', 'rb leipzig': 'لايبزيغ', 'psg': 'باريس سان جيرمان',
    'paris saint germain': 'باريس سان جيرمان', 'marseille': 'مارسيليا', 'monaco': 'موناكو', 'lille': 'ليل', 'nice': 'نيس', 'lens': 'لانس',
    'lyon': 'ليون', 'sporting cp': 'سبورتينغ لشبونة',
    'benfica': 'بنفيكا', 'porto': 'بورتو', 'ajax': 'أياكس', 'psv': 'آيندهوفن',
    'feyenoord': 'فينورد', 'celtic': 'سيلتيك', 'rangers': 'رينجرز', 'al hilal': 'الهلال السعودي', 'al hilal saudi': 'الهلال السعودي', 'al nassr': 'النصر السعودي',
    'al ittihad': 'الاتحاد السعودي', 'al ittihad jeddah': 'الاتحاد السعودي', 'al ahly': 'الأهلي', 'al ahli': 'الأهلي السعودي',
    'al shabab': 'الشباب السعودي', 'al ettifaq': 'الاتفاق', 'al taawoun': 'التعاون',
    'al ain': 'العين الإماراتي', 'shabab al ahli': 'شباب الأهلي', 'al wasl': 'الوصل',
    'al sadd': 'السد القطري', 'al duhail': 'الدحيل', 'al rayyan': 'الريان',
    'al garafa': 'الغرافة', 'al arabi': 'العربي', 'al wakrah': 'الوكرة', 'al shamal': 'الشمال',
    'al khor': 'الخور', 'umm salal': 'أم صلال', 'al ahli doha': 'الأهلي القطري',
    'al fateh': 'الفتح', 'al fayha': 'الفيحاء', 'damac': 'ضمك', 'abha': 'أبها',
    'al raed': 'الرائد', 'al khaleej': 'الخليج', 'al wehda': 'الوحدة السعودي',
    'al hazem': 'الحزم', 'al qadsiah': 'القادسية', 'al ittifaq': 'الاتفاق',
    'al shabab riyadh': 'الشباب السعودي', 'neom sc': 'نيوم', 'al okhdood': 'الأخدود',
  };
}
