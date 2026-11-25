// pickle_showcase_section.dart — "Pickle Paradise" (clean quick-commerce style, fresh green).
// Managed from the admin dashboard → Content → Pickle Paradise (app settings doc "pickle_paradise").
// Changes only when the user taps a pill, an arrow, or swipes — nothing moves on its own.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../image_util.dart';
import 'love_button.dart';

const Color _green = Color(0xFF0C831F);
const Color _greenDark = Color(0xFF086015);
const Color _bg = Color(0xFFF4FBF4);
const Color _text = Color(0xFF1C1C1C);
const Color _muted = Color(0xFF777777);
const Color _line = Color(0xFFE3DDD5);
const Color _offRed = Color(0xFFD32F2F);

class ShowcaseVariant {
  final String id, label;
  final double price, mrp;
  ShowcaseVariant(this.id, this.label, this.price, this.mrp);
}

class ShowcaseItem {
  final String id, productId, name, shortName, description, tag, thumb;
  final List<ShowcaseVariant> variants;
  final int defaultVariant;
  ShowcaseItem(this.id, this.productId, this.name, this.shortName, this.description, this.tag, this.thumb, this.variants, this.defaultVariant);
  String get image => thumb;
}

double _n(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
String _rs(double v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

List<ShowcaseItem> _parse(List<dynamic> raw) {
  final List<ShowcaseItem> out = <ShowcaseItem>[];
  for (final dynamic r in raw) {
    if (r is! Map) continue;
    final Map<String, dynamic> m = Map<String, dynamic>.from(r);
    if (m['enabled'] == false) continue;
    final List<ShowcaseVariant> vs = <ShowcaseVariant>[];
    for (final dynamic v in (m['variants'] as List?) ?? <dynamic>[]) {
      if (v is! Map) continue;
      final double price = _n(v['price']);
      if (price <= 0 || '${v['label'] ?? ''}'.isEmpty) continue;
      vs.add(ShowcaseVariant('${v['id'] ?? v['label']}', '${v['label']}', price, _n(v['mrp'])));
    }
    final String name = '${m['name'] ?? ''}'.trim();
    if (vs.isEmpty || name.isEmpty) continue;
    final String short = '${m['shortName'] ?? ''}'.trim();
    out.add(ShowcaseItem('${m['id'] ?? name}', '${m['productId'] ?? ''}', name, short.isEmpty ? name : short, '${m['description'] ?? ''}', '${m['tag'] ?? ''}',
        '${m['image'] ?? ''}', vs, _n(m['defaultVariant']).round().clamp(0, vs.length - 1).toInt()));
  }
  return out;
}

final List<Map<String, dynamic>> _defaultItems = <Map<String, dynamic>>[
  for (final dynamic e in <dynamic>[
  {
    "id": "bellam_avakaya",
    "name": "Bellam Avakaya",
    "shortName": "Avakaya",
    "description": "Raw mango in jaggery-chilli masala",
    "tag": "Sun-cured 21 days",
    "image": "assets/images/pickle_bellam_avakaya.png",
    "enabled": true,
    "defaultVariant": 0,
    "variants": [
      {
        "label": "250 g",
        "price": 219,
        "mrp": 249
      },
      {
        "label": "500 g",
        "price": 416,
        "mrp": 473
      },
      {
        "label": "1 kg",
        "price": 788,
        "mrp": 896
      }
    ]
  },
  {
    "id": "lemon",
    "name": "Lemon Pickle",
    "shortName": "Lemon",
    "description": "Golden lemons in red chilli masala",
    "tag": "Matured 30 days",
    "image": "assets/images/pickle_lemon.png",
    "enabled": true,
    "defaultVariant": 0,
    "variants": [
      {
        "label": "250 g",
        "price": 159,
        "mrp": 185
      },
      {
        "label": "500 g",
        "price": 302,
        "mrp": 352
      },
      {
        "label": "1 kg",
        "price": 572,
        "mrp": 666
      }
    ]
  },
  {
    "id": "allam_velluli",
    "name": "Allam Velluli Pickle",
    "shortName": "Allam",
    "description": "Ginger & garlic in chilli oil",
    "tag": "Freshly made",
    "image": "assets/images/pickle_allam_velluli.png",
    "enabled": true,
    "defaultVariant": 0,
    "variants": [
      {
        "label": "250 g",
        "price": 199,
        "mrp": 230
      },
      {
        "label": "500 g",
        "price": 378,
        "mrp": 437
      },
      {
        "label": "1 kg",
        "price": 716,
        "mrp": 828
      }
    ]
  },
  {
    "id": "usirikaya",
    "name": "Usirikaya Pickle",
    "shortName": "Usirikaya",
    "description": "Amla in chilli & fenugreek masala",
    "tag": "Rich in Vitamin C",
    "image": "assets/images/pickle_usirikaya.png",
    "enabled": true,
    "defaultVariant": 0,
    "variants": [
      {
        "label": "250 g",
        "price": 189,
        "mrp": 215
      },
      {
        "label": "500 g",
        "price": 359,
        "mrp": 408
      },
      {
        "label": "1 kg",
        "price": 680,
        "mrp": 774
      }
    ]
  },
  {
    "id": "maagaya",
    "name": "Maagaya Pickle",
    "shortName": "Maagaya",
    "description": "Sun-dried mango slices in spicy masala",
    "tag": "Sun-dried mangoes",
    "image": "assets/images/pickle_maagaya.png",
    "enabled": true,
    "defaultVariant": 0,
    "variants": [
      {
        "label": "250 g",
        "price": 229,
        "mrp": 259
      },
      {
        "label": "500 g",
        "price": 435,
        "mrp": 492
      },
      {
        "label": "1 kg",
        "price": 824,
        "mrp": 932
      }
    ]
  },
  {
    "id": "pandu_mirapakaya",
    "name": "Pandu Mirapakaya",
    "shortName": "Mirapa",
    "description": "Ripe red chilli & tamarind pickle",
    "tag": "Stone ground",
    "image": "assets/images/pickle_pandu_mirapakaya.png",
    "enabled": true,
    "defaultVariant": 0,
    "variants": [
      {
        "label": "250 g",
        "price": 179,
        "mrp": 205
      },
      {
        "label": "500 g",
        "price": 340,
        "mrp": 390
      },
      {
        "label": "1 kg",
        "price": 644,
        "mrp": 738
      }
    ]
  },
  {
    "id": "gongura",
    "name": "Gongura Pickle",
    "shortName": "Gongura",
    "description": "Sorrel leaves, garlic & sesame oil",
    "tag": "Andhra classic",
    "image": "assets/images/pickle_gongura.png",
    "enabled": true,
    "defaultVariant": 0,
    "variants": [
      {
        "label": "250 g",
        "price": 189,
        "mrp": 220
      },
      {
        "label": "500 g",
        "price": 359,
        "mrp": 418
      },
      {
        "label": "1 kg",
        "price": 680,
        "mrp": 792
      }
    ]
  },
  {
    "id": "tomato",
    "name": "Tomato Pickle",
    "shortName": "Tomato",
    "description": "Country tomatoes slow-cooked with spice",
    "tag": "Slow cooked",
    "image": "assets/images/pickle_tomato.png",
    "enabled": true,
    "defaultVariant": 0,
    "variants": [
      {
        "label": "250 g",
        "price": 169,
        "mrp": 199
      },
      {
        "label": "500 g",
        "price": 321,
        "mrp": 378
      },
      {
        "label": "1 kg",
        "price": 608,
        "mrp": 716
      }
    ]
  }
]) Map<String, dynamic>.from(e as Map),
];

class PickleShowcaseSection extends StatefulWidget {
  final String apiBase;
  final String sectionKey;
  final Map<String, String>? headers;
  final void Function(ShowcaseItem item, ShowcaseVariant variant)? onAddToCart;
  final void Function(ShowcaseItem item)? onOpenProduct;
  final VoidCallback? onViewAll;
  const PickleShowcaseSection({super.key, required this.apiBase, this.sectionKey = 'pickles', this.headers, this.onAddToCart, this.onOpenProduct, this.onViewAll});
  @override
  State<PickleShowcaseSection> createState() => _PickleShowcaseSectionState();
}

class _PickleShowcaseSectionState extends State<PickleShowcaseSection> {
  List<ShowcaseItem> _items = _parse(_defaultItems);
  String _title = 'Pickle Paradise', _subtitle = 'Handmade in small batches · sun-cured', _viewAll = 'See all';
  bool _enabled = true;
  int _cur = 0, _dir = 1;
  final Map<int, int> _sel = <int, int>{};
  bool _added = false;
  final ScrollController _pills = ScrollController();
  final List<GlobalKey> _pillKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pills.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Map<String, dynamic> d = await ApiService.getAppConfig('pickle_paradise');
      if (!mounted || d.isEmpty) return;
      final List<ShowcaseItem> items = _parse((d['items'] as List?) ?? <dynamic>[]);
      final Map<String, dynamic> s = (d['settings'] is Map) ? Map<String, dynamic>.from(d['settings'] as Map) : <String, dynamic>{};
      setState(() {
        if (items.isNotEmpty) {
          _items = items;
          _cur = 0;
          _sel.clear();
        }
        _enabled = s['enabled'] != false;
        if ('${s['title'] ?? ''}'.trim().isNotEmpty) _title = '${s['title']}';
        if (s['subtitle'] != null) _subtitle = '${s['subtitle']}';
        if ('${s['viewAll'] ?? ''}'.trim().isNotEmpty) _viewAll = '${s['viewAll']}';
      });
    } catch (_) {}
  }

  int _vi(int i) => (_sel[i] ?? _items[i].defaultVariant).clamp(0, _items[i].variants.length - 1).toInt();

  void _go(int i) {
    if (_items.isEmpty) return;
    final int n = (i % _items.length + _items.length) % _items.length;
    if (n == _cur) return;
    HapticFeedback.selectionClick();
    setState(() {
      _dir = (n > _cur) ? 1 : -1;
      _cur = n;
      _added = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (n < _pillKeys.length && _pillKeys[n].currentContext != null) {
        Scrollable.ensureVisible(_pillKeys[n].currentContext!, alignment: 0.5, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      }
    });
  }

  void _add() {
    final ShowcaseItem it = _items[_cur];
    final ShowcaseVariant v = it.variants[_vi(_cur)];
    HapticFeedback.mediumImpact();
    widget.onAddToCart?.call(it, v);
    setState(() => _added = true);
    final int at = _cur;
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _cur == at) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || _items.isEmpty) return const SizedBox.shrink();
    if (_cur >= _items.length) _cur = 0;
    while (_pillKeys.length < _items.length) {
      _pillKeys.add(GlobalKey());
    }
    final ShowcaseItem it = _items[_cur];
    final ShowcaseVariant v = it.variants[_vi(_cur)];
    final int off = v.mrp > v.price ? ((1 - v.price / v.mrp) * 100).round() : 0;

    return Container(
      width: double.infinity,
      color: _bg,
      padding: const EdgeInsets.only(top: 16, bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        // header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: <Widget>[
            Expanded(child: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w800, color: _text, letterSpacing: -0.2))),
            if (widget.onViewAll != null)
              GestureDetector(
                onTap: widget.onViewAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('$_viewAll ›', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _green)),
                ),
              ),
          ]),
        ),
        if (_subtitle.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(_subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF6B6B6B))),
          ),
        const SizedBox(height: 12),
        // pills
        SizedBox(
          height: 40,
          child: ListView.separated(
            controller: _pills,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext c, int k) {
              final bool on = k == _cur;
              return GestureDetector(
                key: _pillKeys[k],
                onTap: () => _go(k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                  decoration: BoxDecoration(
                    color: on ? _green : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: on ? _green : const Color(0xFFE8E2DA)),
                    boxShadow: on ? const <BoxShadow>[BoxShadow(color: Color(0x330C831F), blurRadius: 8, offset: Offset(0, 3))] : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    Container(
                      width: 30,
                      height: 30,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: on ? const Color(0x33FFFFFF) : const Color(0xFFF6F1EA)),
                      child: buildSmartImage(_items[k].thumb, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 6),
                    Text(_items[k].shortName, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: on ? Colors.white : const Color(0xFF333333))),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // product card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFE9E1)),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            // photo
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onOpenProduct?.call(it),
              onHorizontalDragEnd: (DragEndDetails d) {
                final double vx = d.primaryVelocity ?? 0;
                if (vx.abs() > 200 && _items.length > 1) _go(vx < 0 ? _cur + 1 : _cur - 1);
              },
              child: Container(
                height: 200,
                decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, 0.2), radius: 0.9, colors: <Color>[Color(0xFFFFF7EC), Color(0xFFFBE9D3)])),
                child: Stack(children: <Widget>[
                  Positioned.fill(
                    top: 12,
                    bottom: 22,
                    child: RepaintBoundary(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (Widget w, Animation<double> a) {
                          final bool incoming = w.key == ValueKey<String>(it.id);
                          final Offset from = Offset((incoming ? 0.25 : -0.25) * _dir, 0);
                          return FadeTransition(
                            opacity: a,
                            child: SlideTransition(position: Tween<Offset>(begin: from, end: Offset.zero).animate(a), child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1).animate(a), child: w)),
                          );
                        },
                        child: Center(key: ValueKey<String>(it.id), child: buildSmartImage(it.thumb, fit: BoxFit.contain)),
                      ),
                    ),
                  ),
                  if (off > 0)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _offRed, borderRadius: BorderRadius.circular(6)),
                        child: Text('$off% OFF', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: LoveButton(name: it.name, image: it.thumb, price: v.price, category: 'Pickles', size: 17, box: 32, circleColor: Colors.white, fillColor: _green, outlineColor: _green),
                  ),
                  if (_items.length > 1) ...<Widget>[
                    Positioned(left: 10, top: 84, child: _arrow(Icons.chevron_left_rounded, () => _go(_cur - 1))),
                    Positioned(right: 10, top: 84, child: _arrow(Icons.chevron_right_rounded, () => _go(_cur + 1))),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                        for (int d = 0; d < _items.length; d++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: d == _cur ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: d == _cur ? _green : const Color(0x22000000)),
                          ),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),
            // details
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                GestureDetector(
                  onTap: () => widget.onOpenProduct?.call(it),
                  child: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: _text)),
                ),
                if (it.description.isNotEmpty)
                  Text(it.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
                if (it.tag.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(6)),
                    child: Text('☀ ${it.tag}', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF8A5A00))),
                  ),
                ],
                const SizedBox(height: 12),
                Row(children: <Widget>[
                  for (int k = 0; k < it.variants.length && k < 4; k++) ...<Widget>[
                    if (k > 0) const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _sel[_cur] = k;
                            _added = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: k == _vi(_cur) ? const Color(0x0F0C831F) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: k == _vi(_cur) ? _green : _line, width: k == _vi(_cur) ? 1.5 : 1),
                          ),
                          child: Text(it.variants[k].label, maxLines: 1, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: k == _vi(_cur) ? _green : const Color(0xFF444444))),
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 14),
                Row(children: <Widget>[
                  Text(_rs(v.price), style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w700, color: _text)),
                  if (v.mrp > v.price) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(_rs(v.mrp), style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF999999), decoration: TextDecoration.lineThrough, decorationColor: const Color(0xFF999999))),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: _add,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: _added ? _greenDark : _green,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x440C831F), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        if (_added) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check_rounded, color: Colors.white, size: 16)),
                        Text(_added ? 'ADDED' : 'ADD', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: <BoxShadow>[BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))]),
          child: Icon(icon, size: 22, color: const Color(0xFF333333)),
        ),
      );
}
