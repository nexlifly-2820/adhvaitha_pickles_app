import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_config_repository.dart';

class AdminFestivalDashboardPage extends StatefulWidget {
  const AdminFestivalDashboardPage({super.key});

  @override
  State<AdminFestivalDashboardPage> createState() => _AdminFestivalDashboardPageState();
}

class _AdminFestivalDashboardPageState extends State<AdminFestivalDashboardPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  bool _enabled = true;
  final TextEditingController _idController = TextEditingController(text: 'sankranti-2027');
  final TextEditingController _kickerController = TextEditingController(text: 'CELEBRATE');
  final TextEditingController _titleController = TextEditingController(text: 'Sankranti');
  final TextEditingController _subtitleController = TextEditingController(text: 'Pindi vantalu, sweets & gift boxes, made fresh');
  final TextEditingController _chipsTitleController = TextEditingController(text: 'FESTIVE SPECIALS');

  // Theme Colors (Hex)
  String _bgTopHex = '#F9DFB3';
  String _bgBottomHex = '#F6D6A2';
  String _tileHex = '#B81D3B';
  String _lineHex = '#EFCF8C';
  String _titleHex = '#7A1240';
  String _kickerHex = '#5A1030';
  String _stripHex = '#D98F2E';
  String _chipBgHex = '#FDF3DD';
  String _accentHex = '#E9952C';

  // Strip Slogans
  List<String> _stripSlogans = ['HOMEMADE', 'STONE-GROUND', 'FRESH BATCHES', 'PAN-INDIA'];

  // Tiles (4 Cards)
  List<Map<String, dynamic>> _tiles = [
    {
      'title': 'Pindi\nVantalu',
      'image': 'assets/images/snacks.png',
      'image2': 'assets/images/sweets.png',
      'link': {'category': 'Snacks'}
    },
    {
      'title': 'Festive\nSweets',
      'image': 'assets/images/sweets.png',
      'image2': 'assets/images/snacks.png',
      'link': {'category': 'Sweets'}
    },
    {
      'title': 'Gifting\nCorner',
      'image': 'assets/images/combos.png',
      'image2': 'assets/images/pickles.png',
      'link': {'category': 'Combos'}
    },
    {
      'title': 'Pickles\n& Podis',
      'image': 'assets/images/pickles.png',
      'image2': 'assets/images/spices.png',
      'link': {'category': 'Pickles'}
    }
  ];

  // Chips (Tabs)
  List<Map<String, dynamic>> _chips = [
    {
      'title': 'Sankranti\nEssentials',
      'image': 'assets/images/sweets.png',
      'link': {'tag': 'sankranti'}
    },
    {
      'title': 'Snacks\n& More',
      'image': 'assets/images/snacks.png',
      'link': {'category': 'Snacks'}
    },
    {
      'title': 'Traditional\nSweets',
      'image': 'assets/images/combos.png',
      'link': {'category': 'Sweets'}
    },
    {
      'title': 'Pickles\n& Podis',
      'image': 'assets/images/pickles.png',
      'link': {'category': 'Pickles'}
    },
    {
      'title': 'Under\n₹299',
      'image': 'assets/images/spices.png',
      'link': {'maxPrice': 299}
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    try {
      final data = await AppConfigRepository().getFestivalConfigStream().first;
      if (data.isNotEmpty) {
        setState(() {
          _enabled = data['enabled'] != false;
          _idController.text = data['id']?.toString() ?? 'sankranti-2027';
          _kickerController.text = data['kicker']?.toString() ?? 'CELEBRATE';
          _titleController.text = data['title']?.toString() ?? 'Sankranti';
          _subtitleController.text = data['subtitle']?.toString() ?? '';
          _chipsTitleController.text = data['chipsTitle']?.toString() ?? 'FESTIVE SPECIALS';

          final theme = Map<String, dynamic>.from(data['theme'] ?? {});
          _bgTopHex = theme['bgTop']?.toString() ?? '#F9DFB3';
          _bgBottomHex = theme['bgBottom']?.toString() ?? '#F6D6A2';
          _tileHex = theme['tile']?.toString() ?? '#B81D3B';
          _lineHex = theme['line']?.toString() ?? theme['tileBorder']?.toString() ?? '#EFCF8C';
          _titleHex = theme['title']?.toString() ?? '#7A1240';
          _kickerHex = theme['kicker']?.toString() ?? '#5A1030';
          _stripHex = theme['strip']?.toString() ?? '#D98F2E';
          _chipBgHex = theme['chipBg']?.toString() ?? '#FDF3DD';
          _accentHex = theme['accent']?.toString() ?? '#E9952C';

          if (data['strip'] is List) {
            _stripSlogans = List<String>.from(data['strip']);
          }
          if (data['tiles'] is List) {
            _tiles = (data['tiles'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
          }
          if (data['chips'] is List) {
            _chips = (data['chips'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
          }
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _applyPreset(String presetKey) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (presetKey == 'sankranti') {
        _idController.text = 'sankranti-2027';
        _kickerController.text = 'CELEBRATE';
        _titleController.text = 'Sankranti';
        _subtitleController.text = 'Pindi vantalu, sweets & gift boxes, made fresh';
        _chipsTitleController.text = 'FESTIVE SPECIALS';
        _bgTopHex = '#F9DFB3';
        _bgBottomHex = '#F6D6A2';
        _tileHex = '#B81D3B';
        _lineHex = '#EFCF8C';
        _titleHex = '#7A1240';
        _kickerHex = '#5A1030';
        _stripHex = '#D98F2E';
        _chipBgHex = '#FDF3DD';
        _accentHex = '#E9952C';
      } else if (presetKey == 'diwali') {
        _idController.text = 'diwali-2026';
        _kickerController.text = 'CELEBRATE';
        _titleController.text = 'Diwali';
        _subtitleController.text = 'Pure khoya sweets, crisp savories & royal gift sets';
        _chipsTitleController.text = 'DIWALI SPECIALS';
        _bgTopHex = '#FBE0B8';
        _bgBottomHex = '#F7CF96';
        _tileHex = '#9B1457';
        _lineHex = '#EFCF8C';
        _titleHex = '#7A0F12';
        _kickerHex = '#5A0A0C';
        _stripHex = '#D98F2E';
        _chipBgHex = '#FDF1DC';
        _accentHex = '#E9952C';
      } else if (presetKey == 'mango') {
        _idController.text = 'mango-season-2027';
        _kickerController.text = 'FRESH SEASON';
        _titleController.text = 'Avakaya';
        _subtitleController.text = 'Sun-dried raw mango pickles & hand-ground podis';
        _chipsTitleController.text = 'MANGO SPECIALS';
        _bgTopHex = '#FFF1C2';
        _bgBottomHex = '#FFD978';
        _tileHex = '#2E7D32';
        _lineHex = '#FFD54F';
        _titleHex = '#1B5E20';
        _kickerHex = '#33691E';
        _stripHex = '#F9A825';
        _chipBgHex = '#FFF8E1';
        _accentHex = '#F9A825';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded ${presetKey.toUpperCase()} preset!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    final payload = {
      'enabled': _enabled,
      'id': _idController.text.trim(),
      'kicker': _kickerController.text.trim(),
      'title': _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim(),
      'chipsTitle': _chipsTitleController.text.trim(),
      'theme': {
        'bgTop': _bgTopHex,
        'bgBottom': _bgBottomHex,
        'tile': _tileHex,
        'line': _lineHex,
        'title': _titleHex,
        'kicker': _kickerHex,
        'strip': _stripHex,
        'chipBg': _chipBgHex,
        'accent': _accentHex,
      },
      'tiles': _tiles,
      'strip': _stripSlogans,
      'chips': _chips,
      'products': {'tag': _idController.text.trim(), 'limit': 10},
    };

    final success = await AppConfigRepository().saveFestivalConfig(payload);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Festival configuration saved & published live!' : 'Failed to save configuration.',
          ),
          backgroundColor: success ? const Color(0xFF1F8A3A) : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _parseHex(String hex, Color fallback) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          'FESTIVAL MANAGEMENT',
          style: GoogleFonts.philosopher(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF18453B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFF6C453)),
            onPressed: _saveConfig,
            tooltip: 'Publish Festival Config',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF18453B)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. MASTER TOGGLE SWITCH
                  _buildMasterToggleCard(),

                  const SizedBox(height: 16),

                  // 2. PRESET CAMPAIGN BUTTONS
                  _buildPresetsCard(),

                  const SizedBox(height: 16),

                  // 3. CAMPAIGN DETAILS
                  _buildCampaignDetailsCard(),

                  const SizedBox(height: 16),

                  // 4. THEME COLOR PALETTE
                  _buildThemeColorsCard(),

                  const SizedBox(height: 16),

                  // 5. FEATURE CARDS (4 TILES)
                  _buildFeatureTilesCard(),

                  const SizedBox(height: 16),

                  // 6. STRIP SLOGANS
                  _buildStripSlogansCard(),

                  const SizedBox(height: 24),

                  // SAVE BUTTON
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveConfig,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                    label: Text(
                      _isSaving ? 'PUBLISHING...' : 'PUBLISH FESTIVAL CONFIG LIVE',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18453B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // 1. MASTER TOGGLE
  Widget _buildMasterToggleCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _enabled ? const Color(0xFF18453B).withOpacity(0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _enabled ? Icons.auto_awesome : Icons.visibility_off_outlined,
                color: _enabled ? const Color(0xFF18453B) : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Festival Section Active',
                    style: GoogleFonts.philosopher(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _enabled ? 'Section is live on the home page' : 'Section is hidden on home page',
                    style: TextStyle(fontSize: 12, color: _enabled ? Colors.green.shade700 : Colors.grey),
                  ),
                ],
              ),
            ),
            Switch(
              value: _enabled,
              activeColor: const Color(0xFF18453B),
              onChanged: (val) {
                HapticFeedback.lightImpact();
                setState(() => _enabled = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 2. PRESETS
  Widget _buildPresetsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QUICK CAMPAIGN PRESETS', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF18453B), letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _applyPreset('sankranti'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFB81D3B), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('🌾 Sankranti', style: TextStyle(color: Color(0xFFB81D3B), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _applyPreset('diwali'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF9B1457), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('🪔 Diwali', style: TextStyle(color: Color(0xFF9B1457), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _applyPreset('mango'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('🥭 Mango', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. CAMPAIGN DETAILS
  Widget _buildCampaignDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CAMPAIGN DETAILS', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF18453B), letterSpacing: 1)),
            const SizedBox(height: 14),
            _buildTextField(_idController, 'Campaign ID (Tag Filter)', 'e.g. sankranti-2027'),
            const SizedBox(height: 10),
            _buildTextField(_kickerController, 'Kicker Header', 'e.g. CELEBRATE'),
            const SizedBox(height: 10),
            _buildTextField(_titleController, 'Festival Title', 'e.g. Sankranti'),
            const SizedBox(height: 10),
            _buildTextField(_subtitleController, 'Subtitle', 'e.g. Pindi vantalu, sweets & gift boxes'),
            const SizedBox(height: 10),
            _buildTextField(_chipsTitleController, 'Tabs Section Title', 'e.g. FESTIVE SPECIALS'),
          ],
        ),
      ),
    );
  }

  // 4. THEME COLORS
  Widget _buildThemeColorsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THEME PALETTE (HEX CODES)', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF18453B), letterSpacing: 1)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildColorChip('Background Top', _bgTopHex, (val) => setState(() => _bgTopHex = val)),
                _buildColorChip('Background Bottom', _bgBottomHex, (val) => setState(() => _bgBottomHex = val)),
                _buildColorChip('Tile Color', _tileHex, (val) => setState(() => _tileHex = val)),
                _buildColorChip('Title Color', _titleHex, (val) => setState(() => _titleHex = val)),
                _buildColorChip('Kicker Color', _kickerHex, (val) => setState(() => _kickerHex = val)),
                _buildColorChip('Strip Color', _stripHex, (val) => setState(() => _stripHex = val)),
                _buildColorChip('Accent Gold', _accentHex, (val) => setState(() => _accentHex = val)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 5. FEATURE TILES
  Widget _buildFeatureTilesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('4 FEATURED TILES', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF18453B), letterSpacing: 1)),
            const SizedBox(height: 14),
            for (int i = 0; i < _tiles.length; i++) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tile ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF18453B))),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _tiles[i]['title']?.toString() ?? '',
                      decoration: const InputDecoration(labelText: 'Title', isDense: true),
                      onChanged: (val) => _tiles[i]['title'] = val,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: _tiles[i]['image']?.toString() ?? '',
                      decoration: const InputDecoration(labelText: 'Main Cutout Image Asset/URL', isDense: true),
                      onChanged: (val) => _tiles[i]['image'] = val,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 6. STRIP SLOGANS
  Widget _buildStripSlogansCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RIBBON STRIP SLOGANS', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF18453B), letterSpacing: 1)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _stripSlogans.map((slogan) {
                return Chip(
                  label: Text(slogan, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFFFDEBC8),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _stripSlogans.remove(slogan));
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildColorChip(String label, String hex, ValueChanged<String> onChanged) {
    final color = _parseHex(hex, Colors.amber);
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: hex),
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onSubmitted: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
