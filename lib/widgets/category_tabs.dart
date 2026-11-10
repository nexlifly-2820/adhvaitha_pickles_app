// category_tabs.dart — glass category tabs (matches category_tabs_only.mp4)
// All · Pickles · Snacks · Sweets · Podis · Combos — managed in admin_category_tabs.html (category_tabs_backend.js)
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class CategoryTab {
  final String id, slug, label, image, badge;
  final List<String> allImages; // only for the "All" tab: up to 4 small dishes
  CategoryTab(this.id, this.slug, this.label, this.image, this.badge, this.allImages);
}

class CategoryTabs extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final String initialSlug;
  final ValueChanged<CategoryTab>? onChanged;
  const CategoryTabs({super.key, required this.apiBase, this.headers, this.initialSlug = 'all', this.onChanged});
  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  List<CategoryTab> _tabs = <CategoryTab>[];
  String _sel = 'all';
  String? _pressed;

  @override
  void initState() {
    super.initState();
    _sel = widget.initialSlug;
    _load();
  }

  String _abs(String u) {
    if (u.isEmpty || u.startsWith('http') || u.startsWith('assets/')) return u;
    final String origin = widget.apiBase.replaceAll(RegExp(r'/api/?$'), '');
    return u.startsWith('/') ? '$origin$u' : '$origin/$u';
  }

  Future<void> _load() async {
    final fallbackJson = <String, dynamic>{
      "tabs": [
        {"id": "t1", "slug": "all", "label": "All", "image": "assets/images/avakaya_pickle.png", "badge": "", "allImages": [
          "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg",
          "assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg",
          "assets/images/karam_janthukalu_murukku_strings_snack.jpg",
          "assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg"
        ]},
        {"id": "t2", "slug": "pickles", "label": "Pickles", "image": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg", "badge": "", "allImages": []},
        {"id": "t3", "slug": "snacks", "label": "Snacks", "image": "assets/images/karam_janthukalu_murukku_strings_snack.jpg", "badge": "New", "allImages": []},
        {"id": "t4", "slug": "sweets", "label": "Sweets", "image": "assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg", "badge": "", "allImages": []},
        {"id": "t5", "slug": "podis", "label": "Podis", "image": "assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg", "badge": "", "allImages": []},
        {"id": "t6", "slug": "combos", "label": "Combos", "image": "assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg", "badge": "", "allImages": []}
      ]
    };

    void parseAndApply(Map<String, dynamic> j) {
      final List<CategoryTab> list = <CategoryTab>[];
      for (final dynamic raw in (j['tabs'] as List?) ?? <dynamic>[]) {
        final Map<String, dynamic> m = raw as Map<String, dynamic>;
        list.add(CategoryTab(
          '${m['id']}',
          '${m['slug'] ?? ''}',
          '${m['label'] ?? ''}',
          _abs('${m['image'] ?? ''}'),
          '${m['badge'] ?? ''}',
          ((m['allImages'] as List?) ?? <dynamic>[]).map((dynamic e) => _abs('$e')).toList(),
        ));
      }
      if (list.isNotEmpty && mounted) {
        setState(() {
          _tabs = list;
          if (!list.any((CategoryTab t) => t.slug == _sel)) _sel = list.first.slug;
        });
      }
    }

    parseAndApply(fallbackJson);

    try {
      final http.Response r = await http.get(Uri.parse('${widget.apiBase}/category-tabs'), headers: widget.headers).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (r.statusCode == 200 && !r.body.trim().startsWith('<!DOCTYPE') && !r.body.trim().startsWith('<html')) {
        final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
        if ((j['tabs'] as List? ?? []).isNotEmpty) {
          parseAndApply(j);
        }
      }
    } catch (_) {}
  }

  void _tap(CategoryTab t) {
    if (t.slug == _sel) return;
    HapticFeedback.selectionClick();
    setState(() => _sel = t.slug);
    widget.onChanged?.call(t);
  }

  Widget _img(String url, double w) {
    final Widget err = SizedBox(width: w, height: w * 0.8);
    if (url.isEmpty) return err;
    if (url.startsWith('assets/')) return Image.asset(url, width: w, fit: BoxFit.contain, errorBuilder: (BuildContext c, Object e, StackTrace? s) => err);
    return Image.network(url, width: w, fit: BoxFit.contain, gaplessPlayback: true, errorBuilder: (BuildContext c, Object e, StackTrace? s) => err);
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) return const SizedBox(height: 108);
    return SizedBox(
      height: 108,
      child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints bc) {
        const double itemW = 60;
        final int n = _tabs.length;
        final double gap = n * itemW + 28 <= bc.maxWidth ? (bc.maxWidth - 28 - n * itemW) / (n - 1).clamp(1, 99) : 6.0;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          itemCount: n,
          separatorBuilder: (BuildContext c, int i) => SizedBox(width: gap),
          itemBuilder: (BuildContext c, int i) => _item(_tabs[i], itemW),
        );
      }),
    );
  }

  Widget _item(CategoryTab t, double w) {
    final bool on = t.slug == _sel;
    final bool pressed = _pressed == t.slug;
    return GestureDetector(
      onTapDown: (TapDownDetails d) => setState(() => _pressed = t.slug),
      onTapCancel: () => setState(() => _pressed = null),
      onTapUp: (TapUpDetails d) => setState(() => _pressed = null),
      onTap: () => _tap(t),
      child: AnimatedScale(
        scale: pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: w,
          child: Column(children: <Widget>[
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: <Widget>[
                // glass circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: on ? const <Color>[Color(0x8CFFFFFF), Color(0x38FFFFFF)] : const <Color>[Color(0x38FFFFFF), Color(0x0DFFFFFF), Color(0x0F000000)],
                    ),
                    border: Border.all(color: on ? const Color(0xE6FFFFFF) : const Color(0x59FFFFFF), width: on ? 1.5 : 1),
                    boxShadow: on
                        ? const <BoxShadow>[BoxShadow(color: Color(0x8C280000), blurRadius: 22, offset: Offset(0, 10), spreadRadius: -8), BoxShadow(color: Color(0x1FFFFFFF), spreadRadius: 4)]
                        : const <BoxShadow>[BoxShadow(color: Color(0x99280000), blurRadius: 16, offset: Offset(0, 8), spreadRadius: -10)],
                  ),
                ),
                // top reflection
                Positioned(
                  top: 4,
                  left: 10,
                  right: 10,
                  height: 14,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.elliptical(18, 7)),
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Colors.white.withOpacity(on ? 0.6 : 0.35), Colors.white.withOpacity(0)]),
                      ),
                    ),
                  ),
                ),
                // dish
                AnimatedSlide(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  offset: Offset(0, on ? -0.16 : -0.08),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    scale: on ? 1.1 : 1.0,
                    child: t.slug == 'all' && t.allImages.isNotEmpty ? _allGrid(t) : _shadowed(_img(t.image, 54)),
                  ),
                ),
                if (t.badge.isNotEmpty)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))]),
                      child: Text(t.badge.toUpperCase(), style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFFB5170F))),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 7),
            Text(t.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11.5, letterSpacing: 0.2, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: on ? Colors.white : const Color(0xD9FFF0E4))),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: on ? 6 : 0,
              height: on ? 6 : 0,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _shadowed(Widget child) => DecoratedBox(
        decoration: const BoxDecoration(boxShadow: <BoxShadow>[BoxShadow(color: Color(0x5C320000), blurRadius: 10, offset: Offset(0, 6), spreadRadius: -6)]),
        child: child,
      );

  Widget _allGrid(CategoryTab t) {
    final List<String> im = t.allImages.take(4).toList();
    return SizedBox(
      width: 40,
      height: 40,
      child: Wrap(spacing: 0, runSpacing: 0, children: <Widget>[for (final String u in im) SizedBox(width: 20, height: 20, child: _img(u, 20))]),
    );
  }
}
