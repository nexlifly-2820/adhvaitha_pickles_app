import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kitchen_story_model.dart';

class KitchenStoryPage extends StatefulWidget {
  const KitchenStoryPage({super.key});

  @override
  State<KitchenStoryPage> createState() => _KitchenStoryPageState();
}

class _KitchenStoryPageState extends State<KitchenStoryPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('settings').doc('kitchen_story').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9E9CF),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF18453B))),
          );
        }

        KitchenStoryData data;
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Fallback to default data if Firestore document doesn't exist yet
          data = KitchenStoryData(
            appBarTitle: 'OUR JOURNEY',
            beginning: BeginningSection(
              imagePath: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
              label: 'OUR BEGINNING',
              angle: -0.05,
              hasPin: true,
            ),
            historyText: "Founded with a passion for tradition, our journey began in a small home kitchen, bringing the authentic taste of Telugu pickles to your table!",
            authentic: AuthenticSection(
              imagePath: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
              bannerText: 'PURE & AUTHENTIC',
              angle: 0.05,
            ),
            ingredients: IngredientsSection(
              headerText: 'WHILE YOU ARE BROWSING OUR APP\nWE\'RE PROBABLY OUT',
              items: [
                IngredientItem(
                  imagePath: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
                  text: 'PICKING THE FINEST\nHAND-PICKED\nMANGOES',
                  isLeft: true,
                ),
                IngredientItem(
                  imagePath: 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg',
                  text: 'SOURCING THE\nJUICIEST\nGOOSEBERRIES',
                  isLeft: false,
                ),
              ],
              footerTitle: '& CHOOSING THE PUREST\nCOLD-PRESSED OILS',
              footerSubtitle: 'FROM DIFFERENT\nFARMS ACROSS\nINDIA',
            ),
            vision: VisionSection(
              mainText: 'Our vision of making ',
              highlightText: 'HONESTLY\nGOOD',
              suffixText: ', authentic and traditional Indian food came to life',
            ),
            reach: ReachSection(
              imagePath: 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg',
              label: 'OUR REACH',
              description: 'The same love and authenticity goes into every Adhvaitha pack!',
            ),
            footer: FooterSection(
              imagePath: 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
              topText: 'Bring home the taste of tradition. We\'ll make sure every bite is',
              bigText: 'SO TRADITIONAL',
              cursiveText: 'good',
            ),
          );
        } else {
          data = KitchenStoryData.fromFirestore(snapshot.data!.data() as Map<String, dynamic>);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9E9CF),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(data.appBarTitle),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      _buildFirstStoreSection(data.beginning),
                      _buildHistoryTextSection(data.historyText),
                      _buildKitchenSection(data.authentic),
                      _buildIngredientsDesignSection(data.ingredients),
                      _buildVisionSection(data.vision),
                      _buildHundredStoresSection(data.reach),
                      _buildFooterSection(data.footer),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(String title) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF18453B),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(title, style: GoogleFonts.bangers(letterSpacing: 2, color: Colors.white)),
      centerTitle: true,
    );
  }

  Widget _buildFirstStoreSection(BeginningSection beginning) {
    return Column(
      children: [
        _PhotoCard(
          imagePath: beginning.imagePath,
          angle: beginning.angle,
          hasPin: beginning.hasPin,
          label: beginning.label,
          icons: const [
            _FloatingIcon(icon: Icons.eco_outlined, top: 40, right: -20, color: Colors.green),
            _FloatingIcon(icon: Icons.agriculture_outlined, bottom: 20, left: -30, color: Colors.orange),
          ],
        ),
        const SizedBox(height: 30),
        const _CurvedArrow(angle: 0.5),
      ],
    );
  }

  Widget _buildHistoryTextSection(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF18453B),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildKitchenSection(AuthenticSection authentic) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: _PhotoCard(
            imagePath: authentic.imagePath,
            angle: authentic.angle,
            hasPin: true,
            icons: const [
              _FloatingIcon(icon: Icons.spa_outlined, top: -10, right: 20, color: Colors.green),
            ],
          ),
        ),
        Positioned(
          right: 0,
          bottom: 40,
          child: _RedBanner(text: authentic.bannerText),
        ),
      ],
    );
  }

  Widget _buildIngredientsDesignSection(IngredientsSection ingredients) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedPathPainter(),
            ),
          ),
          Column(
            children: [
              Text(
                ingredients.headerText,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF18453B),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              ...ingredients.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: _IngredientRow(
                  imagePath: item.imagePath,
                  text: item.text,
                  isLeft: item.isLeft,
                ),
              )).toList(),
              Text(
                ingredients.footerTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF18453B),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                ingredients.footerSubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF18453B),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, size: 60, color: Colors.red.withOpacity(0.5)),
                  const SizedBox(width: 20),
                  Icon(Icons.home, size: 80, color: Colors.red.withOpacity(0.7)),
                  const SizedBox(width: 20),
                  Icon(Icons.nature_people, size: 60, color: Colors.red.withOpacity(0.5)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisionSection(VisionSection vision) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Row(
        children: [
          const Icon(Icons.spa_outlined, color: Colors.green, size: 50),
          const SizedBox(width: 20),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF18453B), fontSize: 18, height: 1.4, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(text: vision.mainText),
                  TextSpan(text: vision.highlightText, style: const TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(text: vision.suffixText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHundredStoresSection(ReachSection reach) {
    return Column(
      children: [
        _PhotoCard(
          imagePath: reach.imagePath,
          angle: 0.05,
          hasPin: true,
          label: reach.label,
        ),
        Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            reach.description,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF18453B), fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection(FooterSection footer) {
    return Column(
      children: [
        _PhotoCard(
          imagePath: footer.imagePath,
          angle: -0.03,
          icons: const [
            _FloatingIcon(icon: Icons.local_florist_outlined, bottom: -20, right: 20, color: Colors.green),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
               Text(
                footer.topText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF18453B), fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Text(
                footer.bigText,
                style: GoogleFonts.bangers(fontSize: 44, color: const Color(0xFF18453B), letterSpacing: 2),
              ),
              Text(
                footer.cursiveText,
                style: GoogleFonts.permanentMarker(fontSize: 48, color: const Color(0xFFE21B23)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final String imagePath;
  final String text;
  final bool isLeft;

  const _IngredientRow({required this.imagePath, required this.text, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isLeft) ...[
            _CircularIngredient(imagePath: imagePath),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF18453B),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF18453B),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 20),
            _CircularIngredient(imagePath: imagePath),
          ],
        ],
      ),
    );
  }
}

class _CircularIngredient extends StatelessWidget {
  final String imagePath;
  const _CircularIngredient({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: ClipOval(
        child: _buildImage(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}

class _DashedPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.1);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.05, size.width * 0.4, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.4, size.width * 0.8, size.height * 0.3);
    path.quadraticBezierTo(size.width, size.height * 0.2, size.width, size.height * 0.5);

    path.moveTo(size.width, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.9, size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.7, 0, size.height * 0.9);

    final dashPath = _dashPath(path, 10, 5);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, double dashWidth, double dashSpace) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dest.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PhotoCard extends StatelessWidget {
  final String imagePath;
  final double angle;
  final bool hasPin;
  final String? label;
  final List<_FloatingIcon> icons;

  const _PhotoCard({
    required this.imagePath,
    this.angle = 0,
    this.hasPin = false,
    this.label,
    this.icons = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: CustomPaint(
              painter: _CheckeredPainter(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: _buildImage(imagePath, width: 280, height: 200, fit: BoxFit.cover),
              ),
            ),
          ),
          if (hasPin)
            const Positioned(
              top: -15,
              left: 20,
              child: Icon(Icons.push_pin, color: Color(0xFFE21B23), size: 30),
            ),
          if (label != null)
            Positioned(
              bottom: -10,
              right: -10,
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE21B23),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    label!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
            ),
          ...icons,
        ],
      ),
    );
  }
}

class _CheckeredPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintYellow = Paint()..color = const Color(0xFFFFD700);
    const double squareSize = 15.0;

    for (double x = 0; x < size.width; x += squareSize) {
      for (double y = 0; y < size.height; y += squareSize) {
        if ((x / squareSize).floor() % 2 == (y / squareSize).floor() % 2) {
        } else {
          canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paintYellow);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final double? top, bottom, left, right;
  final Color color;

  const _FloatingIcon({required this.icon, this.top, this.bottom, this.left, this.right, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Transform.rotate(
        angle: 0.1,
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }
}

class _CurvedArrow extends StatelessWidget {
  final double angle;
  final bool flip;
  const _CurvedArrow({this.angle = 0, this.flip = false});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationZ(angle)..scale(flip ? -1.0 : 1.0, 1.0),
      child: const Icon(Icons.subdirectory_arrow_right_rounded, color: Color(0xFF18453B), size: 60),
    );
  }
}

class _RedBanner extends StatelessWidget {
  final String text;
  const _RedBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        decoration: const BoxDecoration(
          color: Color(0xFFE21B23),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }
}

Widget _buildImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (path.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
  if (path.startsWith('http') || path.startsWith('https')) {
    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  } else {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
