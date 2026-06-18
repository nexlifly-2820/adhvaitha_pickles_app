import 'package:cloud_firestore/cloud_firestore.dart';

class KitchenStoryData {
  final String appBarTitle;
  final BeginningSection beginning;
  final String historyText;
  final AuthenticSection authentic;
  final IngredientsSection ingredients;
  final VisionSection vision;
  final ReachSection reach;
  final FooterSection footer;

  KitchenStoryData({
    required this.appBarTitle,
    required this.beginning,
    required this.historyText,
    required this.authentic,
    required this.ingredients,
    required this.vision,
    required this.reach,
    required this.footer,
  });

  factory KitchenStoryData.fromFirestore(Map<String, dynamic> json) {
    return KitchenStoryData(
      appBarTitle: json['app_bar_title'] ?? 'OUR JOURNEY',
      beginning: BeginningSection.fromMap(json['beginning'] ?? {}),
      historyText: json['history_text'] ?? '',
      authentic: AuthenticSection.fromMap(json['authentic'] ?? {}),
      ingredients: IngredientsSection.fromMap(json['ingredients'] ?? {}),
      vision: VisionSection.fromMap(json['vision'] ?? {}),
      reach: ReachSection.fromMap(json['reach'] ?? {}),
      footer: FooterSection.fromMap(json['footer'] ?? {}),
    );
  }
}

class BeginningSection {
  final String imagePath;
  final String label;
  final double angle;
  final bool hasPin;

  BeginningSection({
    required this.imagePath,
    required this.label,
    required this.angle,
    required this.hasPin,
  });

  factory BeginningSection.fromMap(Map<String, dynamic> map) {
    return BeginningSection(
      imagePath: map['image_path'] ?? 'assets/images/allam_velli_pickle_ginger_garlic_pickle.jpg',
      label: map['label'] ?? 'OUR BEGINNING',
      angle: (map['angle'] ?? -0.05).toDouble(),
      hasPin: map['has_pin'] ?? true,
    );
  }
}

class AuthenticSection {
  final String imagePath;
  final String bannerText;
  final double angle;

  AuthenticSection({
    required this.imagePath,
    required this.bannerText,
    required this.angle,
  });

  factory AuthenticSection.fromMap(Map<String, dynamic> map) {
    return AuthenticSection(
      imagePath: map['image_path'] ?? 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      bannerText: map['banner_text'] ?? 'PURE & AUTHENTIC',
      angle: (map['angle'] ?? 0.05).toDouble(),
    );
  }
}

class IngredientItem {
  final String imagePath;
  final String text;
  final bool isLeft;

  IngredientItem({
    required this.imagePath,
    required this.text,
    required this.isLeft,
  });

  factory IngredientItem.fromMap(Map<String, dynamic> map) {
    return IngredientItem(
      imagePath: map['image_path'] ?? '',
      text: map['text'] ?? '',
      isLeft: map['is_left'] ?? true,
    );
  }
}

class IngredientsSection {
  final String headerText;
  final List<IngredientItem> items;
  final String footerTitle;
  final String footerSubtitle;

  IngredientsSection({
    required this.headerText,
    required this.items,
    required this.footerTitle,
    required this.footerSubtitle,
  });

  factory IngredientsSection.fromMap(Map<String, dynamic> map) {
    return IngredientsSection(
      headerText: map['header_text'] ?? "WHILE YOU ARE BROWSING OUR APP\nWE'RE PROBABLY OUT",
      items: (map['items'] as List? ?? [])
          .map((item) => IngredientItem.fromMap(item))
          .toList(),
      footerTitle: map['footer_title'] ?? '& CHOOSING THE PUREST\nCOLD-PRESSED OILS',
      footerSubtitle: map['footer_subtitle'] ?? 'FROM DIFFERENT\nFARMS ACROSS\nINDIA',
    );
  }
}

class VisionSection {
  final String mainText;
  final String highlightText;
  final String suffixText;

  VisionSection({
    required this.mainText,
    required this.highlightText,
    required this.suffixText,
  });

  factory VisionSection.fromMap(Map<String, dynamic> map) {
    return VisionSection(
      mainText: map['main_text'] ?? 'Our vision of making ',
      highlightText: map['highlight_text'] ?? 'HONESTLY\nGOOD',
      suffixText: map['suffix_text'] ?? ', authentic and traditional Indian food came to life',
    );
  }
}

class ReachSection {
  final String imagePath;
  final String label;
  final String description;

  ReachSection({
    required this.imagePath,
    required this.label,
    required this.description,
  });

  factory ReachSection.fromMap(Map<String, dynamic> map) {
    return ReachSection(
      imagePath: map['image_path'] ?? 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg',
      label: map['label'] ?? 'OUR REACH',
      description: map['description'] ?? 'The same love and authenticity goes into every Adhvaitha pack!',
    );
  }
}

class FooterSection {
  final String imagePath;
  final String topText;
  final String bigText;
  final String cursiveText;

  FooterSection({
    required this.imagePath,
    required this.topText,
    required this.bigText,
    required this.cursiveText,
  });

  factory FooterSection.fromMap(Map<String, dynamic> map) {
    return FooterSection(
      imagePath: map['image_path'] ?? 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
      topText: map['top_text'] ?? "Bring home the taste of tradition. We'll make sure every bite is",
      bigText: map['big_text'] ?? 'SO TRADITIONAL',
      cursiveText: map['cursive_text'] ?? 'good',
    );
  }
}
