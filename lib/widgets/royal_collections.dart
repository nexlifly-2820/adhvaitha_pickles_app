import 'package:flutter/material.dart';

class CollectionItem {
  final String name;
  final String varieties; // e.g. '12+ varieties'
  final String imageUrl;  // https://... from backend, or 'assets/...'
  const CollectionItem(this.name, this.varieties, this.imageUrl);
}

class RoyalCollectionsSection extends StatelessWidget {
  final List<CollectionItem> items;
  final ValueChanged<CollectionItem>? onItemTap;
  final VoidCallback? onViewAll;
  final String kicker;
  final String title;
  final String pill;

  const RoyalCollectionsSection({
    super.key,
    required this.items,
    this.onItemTap,
    this.onViewAll,
    this.kicker = 'TRADITIONAL ANDHRA FLAVOURS',
    this.title = 'Royal Collections',
    this.pill = 'FOR EVERY HOME',
  });

  static const maroonTop = Color(0xFFA3161B);
  static const maroon = Color(0xFF7A0F12);
  static const maroonDark = Color(0xFF5C0A0D);
  static const gold = Color(0xFFF6C453);
  static const cream = Color(0xFFFDEBC8);

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 390; // design scale

    return Column(
      children: [
        // arched dome on top
        SizedBox(
          height: 40 * s,
          width: double.infinity,
          child: CustomPaint(painter: _DomePainter()),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -1),
              radius: 1.4,
              colors: [maroonTop, maroon, maroonDark],
              stops: [0, .55, 1],
            ),
          ),
          padding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 14 * s),
          child: Column(
            children: [
              _header(s),
              SizedBox(height: 14 * s),
              _grid(s),
              SizedBox(height: 16 * s),
              if (onViewAll != null) _viewAll(s),
            ],
          ),
        ),
        // diamond border
        Container(
          height: 20 * s,
          color: maroonDark,
          child: LayoutBuilder(builder: (_, c) {
            final n = (c.maxWidth / (16 * s)).floor();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                n,
                (_) => Transform.rotate(
                  angle: .785,
                  child: Container(
                    width: 7 * s,
                    height: 7 * s,
                    decoration: BoxDecoration(border: Border.all(color: gold, width: 1.5)),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _header(double s) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
        children: [
          Positioned(left: 4 * s, top: 0, child: _Lamp(size: 48 * s)),
          Positioned(right: 4 * s, top: 0, child: _Lamp(size: 48 * s)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(kicker,
                  style: TextStyle(
                      color: gold, fontSize: 11 * s, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              SizedBox(height: 4 * s),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.diamond_rounded,
                    color: gold,
                    size: 13 * s,
                  ),
                  SizedBox(width: 12 * s),
                  Text(title,
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: const Color(0xFFFFE6A8),
                        fontSize: 26 * s,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: Color(0xFF4A0507), offset: Offset(0, 2)),
                          Shadow(color: Color(0x59FFC864), blurRadius: 14),
                        ],
                      )),
                  SizedBox(width: 12 * s),
                  Icon(
                    Icons.diamond_rounded,
                    color: gold,
                    size: 13 * s,
                  ),
                ],
              ),
              SizedBox(height: 6 * s),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 4 * s),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.28),
                  borderRadius: BorderRadius.circular(20 * s),
                  border: Border.all(color: gold.withOpacity(.4)),
                ),
                child: Text(pill,
                    style: TextStyle(
                        color: const Color(0xFFFFE9C2),
                        fontSize: 11 * s,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
        ],
      );
  }

  Widget _grid(double s) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8 * s,
        mainAxisSpacing: 12 * s,
        childAspectRatio: 116 / 156,
      ),
      itemBuilder: (_, i) => _card(items[i], s),
    );
  }

  Widget _card(CollectionItem it, double s) {
    final img = it.imageUrl.startsWith('http')
        ? Image.network(
            it.imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (c, e, s) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.restaurant, color: Colors.grey),
            ),
          )
        : Image.asset(
            it.imageUrl.startsWith('assets/') ? it.imageUrl : 'assets/images/${it.imageUrl}',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (c, e, s) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.restaurant, color: Colors.grey),
            ),
          );

    return GestureDetector(
      onTap: () => onItemTap?.call(it),
      child: CustomPaint(
        painter: _ArchCardPainter(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8 * s, 20 * s, 8 * s, 8 * s),
          child: Column(children: [
            Text(it.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: const Color(0xFF4A0A0C), fontSize: 13.5 * s, fontWeight: FontWeight.w700)),
            Text(it.varieties,
                style: TextStyle(
                    color: const Color(0xFF9A5A12), fontSize: 10 * s, fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              height: 86 * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12 * s),
                border: Border.all(color: gold, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10 * s),
                child: SizedBox.expand(child: img),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _viewAll(double s) {
    return GestureDetector(
      onTap: onViewAll,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 8 * s),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE39A), gold]),
          borderRadius: BorderRadius.circular(22 * s),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Text('Explore all collections →',
            style: TextStyle(color: const Color(0xFF5A0A0C), fontSize: 12.5 * s, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ArchCardPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    final w = z.width, h = z.height;
    final k = w / 116;
    final p = Path()
      ..moveTo(0, 30 * k)
      ..quadraticBezierTo(0, 20 * k, 10 * k, 16 * k)
      ..lineTo(52 * k, 2 * k)
      ..quadraticBezierTo(58 * k, 0, 64 * k, 2 * k)
      ..lineTo(w - 10 * k, 16 * k)
      ..quadraticBezierTo(w, 20 * k, w, 30 * k)
      ..lineTo(w, h - 12 * k)
      ..quadraticBezierTo(w, h, w - 12 * k, h)
      ..lineTo(12 * k, h)
      ..quadraticBezierTo(0, h, 0, h - 12 * k)
      ..close();
    c.drawShadow(p, Colors.black, 4, false);
    c.drawPath(p, Paint()..color = RoyalCollectionsSection.cream);
    c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFF3CF86));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DomePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    final w = z.width, h = z.height, cx = w / 2;
    final fill = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * .62)
      ..lineTo(cx - 70, h * .62)
      ..quadraticBezierTo(cx - 40, h * .62, cx - 26, h * .3)
      ..quadraticBezierTo(cx - 14, 0, cx, 0)
      ..quadraticBezierTo(cx + 14, 0, cx + 26, h * .3)
      ..quadraticBezierTo(cx + 40, h * .62, cx + 70, h * .62)
      ..lineTo(w, h * .62)
      ..lineTo(w, h)
      ..close();
    c.drawPath(fill, Paint()..color = RoyalCollectionsSection.maroonTop);
    final line = Path()
      ..moveTo(cx - 60, h * .8)
      ..quadraticBezierTo(cx - 32, h * .8, cx - 20, h * .45)
      ..quadraticBezierTo(cx - 10, h * .18, cx, h * .18)
      ..quadraticBezierTo(cx + 10, h * .18, cx + 20, h * .45)
      ..quadraticBezierTo(cx + 32, h * .8, cx + 60, h * .8);
    c.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = RoyalCollectionsSection.gold.withOpacity(.7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Lamp extends StatelessWidget {
  final double size;
  const _Lamp({required this.size});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size * 70 / 60, child: CustomPaint(painter: _LampPainter()));
}

class _LampPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    final k = z.width / 60;
    Offset o(double x, double y) => Offset(x * k, y * k);
    c.drawCircle(
        o(30, 22),
        22 * k,
        Paint()
          ..shader = const RadialGradient(colors: [
            Color(0xE6FFD27A),
            Color(0x00FFD27A)
          ]).createShader(Rect.fromCircle(center: o(30, 22), radius: 22 * k)));
    c.drawPath(Path()..addPolygon([o(30, 6), o(40, 18), o(30, 30), o(20, 18)], true),
        Paint()..color = Colors.white);
    c.drawPath(Path()..addPolygon([o(30, 12), o(35, 18), o(30, 24), o(25, 18)], true),
        Paint()..color = const Color(0xFFF2711C));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = k
      ..color = const Color(0xFFC98A2E);
    Path petal(List<double> v) => Path()
      ..moveTo(v[0] * k, v[1] * k)
      ..quadraticBezierTo(v[2] * k, v[3] * k, 30 * k, 66 * k)
      ..quadraticBezierTo((60 - v[2]) * k, v[3] * k, (60 - v[0]) * k, v[1] * k)
      ..quadraticBezierTo(v[4] * k, v[5] * k, 30 * k, v[5] * k)
      ..quadraticBezierTo((60 - v[4]) * k, v[5] * k, v[0] * k, v[1] * k);
    final outer = petal([8, 40, 12, 64, 40, 50]);
    c.drawPath(
        outer,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF3D6), Color(0xFFE9A948)])
              .createShader(Rect.fromLTWH(0, 38 * k, 60 * k, 30 * k)));
    c.drawPath(outer, edge);
    final mid = petal([18, 38, 20, 60, 36, 46]);
    c.drawPath(mid, Paint()..color = const Color(0xFFFFF8E8));
    c.drawPath(mid, edge);
    final inner = petal([26, 40, 27, 58, 30, 44]);
    c.drawPath(inner, Paint()..color = const Color(0xFFF7C873));
    c.drawPath(inner, edge);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
