class Species {
  final String id;
  final String commonName;
  final String? scientificName;
  final String? description;
  final String? careInstructions;
  final double? idealTemperatureMin;
  final double? idealTemperatureMax;
  final double? idealHumidityMin;
  final double? idealHumidityMax;
  final String? idealLightConditions;
  final String? imagePath;
  final String? sourceUrl;
  final String? license;
  final String? attribution;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Species({
    required this.id,
    required this.commonName,
    this.scientificName,
    this.description,
    this.careInstructions,
    this.idealTemperatureMin,
    this.idealTemperatureMax,
    this.idealHumidityMin,
    this.idealHumidityMax,
    this.idealLightConditions,
    this.imagePath,
    this.sourceUrl,
    this.license,
    this.attribution,
    this.isPublished = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['id'] as String,
      commonName: json['common_name'] as String,
      scientificName: json['scientific_name'] as String?,
      description: json['description'] as String?,
      careInstructions: json['care_instructions'] as String?,
      idealTemperatureMin: json['ideal_temperature_min'] != null
          ? (json['ideal_temperature_min'] as num).toDouble()
          : null,
      idealTemperatureMax: json['ideal_temperature_max'] != null
          ? (json['ideal_temperature_max'] as num).toDouble()
          : null,
      idealHumidityMin: json['ideal_humidity_min'] != null
          ? (json['ideal_humidity_min'] as num).toDouble()
          : null,
      idealHumidityMax: json['ideal_humidity_max'] != null
          ? (json['ideal_humidity_max'] as num).toDouble()
          : null,
      idealLightConditions: json['ideal_light_conditions'] as String?,
      imagePath: json['image_path'] as String?,
      sourceUrl: json['source_url'] as String?,
      license: json['license'] as String?,
      attribution: json['attribution'] as String?,
      isPublished: (json['is_published'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'common_name': commonName,
      'scientific_name': scientificName,
      'description': description,
      'care_instructions': careInstructions,
      'ideal_temperature_min': idealTemperatureMin,
      'ideal_temperature_max': idealTemperatureMax,
      'ideal_humidity_min': idealHumidityMin,
      'ideal_humidity_max': idealHumidityMax,
      'ideal_light_conditions': idealLightConditions,
      'image_path': imagePath,
      'source_url': sourceUrl,
      'license': license,
      'attribution': attribution,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Returns localized common name based on active language
  String localizedName(bool isArabic) {
    if (!isArabic) return commonName;
    switch (commonName.toLowerCase().trim()) {
      case 'tomato':
        return 'طماطم (Tomato)';
      case 'sweet basil':
      case 'basil':
        return 'ريحان (Sweet Basil)';
      case 'spearmint':
      case 'mint':
        return 'نعناع (Spearmint)';
      case 'butterhead lettuce':
      case 'lettuce':
        return 'خس (Butterhead Lettuce)';
      case 'bell pepper':
      case 'pepper':
        return 'فلفل حلو (Bell Pepper)';
      case 'garden strawberry':
      case 'strawberry':
        return 'فراولة (Garden Strawberry)';
      default:
        return commonName;
    }
  }

  /// Returns localized description based on active language
  String? localizedDescription(bool isArabic) {
    if (description != null && description!.isNotEmpty) {
      final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(description!);
      if (isArabic && hasArabic) {
        return description;
      }
      if (!isArabic && !hasArabic) {
        return description;
      }
    }
    if (!isArabic) return description;
    switch (commonName.toLowerCase().trim()) {
      case 'tomato':
        return 'محصول خضري ثمري عالي الإنتاجية، يلائم الزراعة الرأسية والبيوت المحمية، ويتميز بنموه الرأسي وثماره الغنية بالعناصر الغذائية.';
      case 'sweet basil':
      case 'basil':
        return 'نبات عشبي عطري ينمو بكفاءة عالية في الأنظمة الرأسية والمائية، ذو أوراق خضراء عطرية غنية بالزيوت الطيارة المفيدة.';
      case 'spearmint':
      case 'mint':
        return 'عشب معمر سريع النمو ومنعش، مثالي للأبراج والطبقات الرأسية، ويتميز بتجدد نموه السريع وقدرته العالية على التكيف.';
      case 'butterhead lettuce':
      case 'lettuce':
        return 'محصول ورقي سريع النضج ومثالي للطبقات الرأسية والزراعة المائية، يمتاز بأوراق طرية غنية بالألياف والمعادن.';
      case 'bell pepper':
      case 'pepper':
        return 'محصول ثمري مفضل للزراعة المحمية، ينتج ثماراً غنية بفيتامين C ويتطلب دعامات تثبيت رأسية جيدة.';
      case 'garden strawberry':
      case 'strawberry':
        return 'محصول ثمري مميز للأبراج الرأسية والمزاريب المعلقة، يوفر استغلالاً مثالياً للمساحة وحصاداً نظيفاً.';
      default:
        return description;
    }
  }

  /// Returns localized care guidelines based on active language
  String? localizedCareInstructions(bool isArabic) {
    if (!isArabic) return careInstructions;
    switch (commonName.toLowerCase().trim()) {
      case 'tomato':
        return 'الري المنتظم عند قاعدة النبات لتجنب بلل الأوراق، وضمان تهوية جيدة، واستخدام دعامات رأسية لحمل الثمار وتسميد غني بالبوتاسيوم والفوسفور.';
      case 'sweet basil':
      case 'basil':
        return 'الحفاظ على رطوبة التربة باعتدال وتصريف جيد، وتوفير إضاءة كافية، وتقليم القمم النامية دورياً لتحفيز التفرع الجانبي والكثافة الورقية.';
      case 'spearmint':
      case 'mint':
        return 'تربة رطبة دائماً، وحصاد دوري للأطراف العلوية لتشجيع نمو أوراق طرية جديدة ومنع الإزهار المبكر.';
      case 'butterhead lettuce':
      case 'lettuce':
        return 'الحفاظ على برودة منطقة الجذور ودرجة رطوبة منتظمة ومستقرة لتفادي الاستطالة والتزهير المبكر وحروق حواف الأوراق.';
      case 'bell pepper':
      case 'pepper':
        return 'ري عميق منتظم، وتوفير إضاءة وافرة، وزيادة التسميد الفوسفوري أثناء عقد الأزهار، واستخدام دعامات تثبيت قوية.';
      case 'garden strawberry':
      case 'strawberry':
        return 'ري بالتنقيط للحفاظ على الثمار جافة ونظيفة، وضمان تصريف ممتاز، وإزالة المدادات الزائدة لتركيز الطاقة على الإنتاج الثمري.';
      default:
        return careInstructions;
    }
  }
}

