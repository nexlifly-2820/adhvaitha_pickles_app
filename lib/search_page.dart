import 'package:flutter/material.dart';
import 'models.dart';
import 'product_detail_page.dart';
import 'product_repository.dart';
import 'navigation_util.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchPage extends StatefulWidget {
  final bool autoListen;
  final String? initialQuery;
  const SearchPage({super.key, this.autoListen = false, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = ['Mango Pickle', 'Chakinalu', 'Ladoo'];
  List<String> trendingSearches = ['Chicken Pickle', 'Garam Masala', 'Amla Pickle'];
  List<Product> searchResults = [];
  bool isSearching = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    if (widget.autoListen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _searchController.text = val.recognizedWords;
            _performSearch(val.recognizedWords);
            if (val.hasConfidenceRating && val.confidence > 0) {
              // Optionally handle confidence
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }

    final String lowerQuery = query.toLowerCase();

    setState(() {
      isSearching = true;
      searchResults = ProductRepository.allProducts.where((product) {
        final bool matchesName = product.name.toLowerCase().contains(lowerQuery);
        final bool matchesCategory = product.category.toLowerCase().contains(lowerQuery);
        final bool matchesDescription = product.description.toLowerCase().contains(lowerQuery);
        final bool matchesIngredient = product.ingredients.any((i) => i.toLowerCase().contains(lowerQuery));
        final bool matchesSpice = product.secretIngredient.name.toLowerCase().contains(lowerQuery);
        
        // Mood-based mappings
        bool matchesMood = false;
        if (lowerQuery.contains('spicy') || lowerQuery.contains('hot')) {
          matchesMood = product.description.toLowerCase().contains('spicy') || 
                        product.name.toLowerCase().contains('karam') ||
                        product.name.toLowerCase().contains('chilli');
        } else if (lowerQuery.contains('sweet')) {
          matchesMood = product.description.toLowerCase().contains('sweet') || 
                        product.name.toLowerCase().contains('bellam') ||
                        product.name.toLowerCase().contains('jaggery');
        } else if (lowerQuery.contains('andhra')) {
          matchesMood = product.origin.toLowerCase().contains('andhra');
        }

        return matchesName || matchesCategory || matchesDescription || matchesIngredient || matchesSpice || matchesMood;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _performSearch,
          decoration: const InputDecoration(
            hintText: 'Search flavors of tradition...',
            border: InputBorder.none,
          ),
          onSubmitted: (val) {
            if (val.isNotEmpty && !recentSearches.contains(val)) {
              setState(() => recentSearches.insert(0, val));
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: _listen,
            icon: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListening ? Colors.red : const Color(0xFF18453B),
            ),
          ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)).then().shimmer(),
          IconButton(
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            }, 
            icon: const Icon(Icons.close_rounded)
          ),
        ],
      ),
      body: !isSearching 
        ? _buildDiscoveryView() 
        : _buildResultsView(),
    );
  }

  Widget _buildDiscoveryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            const Text('RECENT SEARCHES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              children: recentSearches.map((s) => ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onPressed: () {
                  _searchController.text = s;
                  _performSearch(s);
                },
              )).toList(),
            ),
            const SizedBox(height: 40),
          ],
          const Text('TRENDING NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trendingSearches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.trending_up_rounded, color: Color(0xFFD4AF37), size: 20),
              title: Text(trendingSearches[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                _searchController.text = trendingSearches[index];
                _performSearch(trendingSearches[index]);
              },
            ),
          ),
          const SizedBox(height: 40),
          const Text('DISCOVER BY MOOD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 15),
          Row(
            children: [
              _MoodChip(
                label: 'Feeling Spicy?', 
                color: Colors.red.shade700, 
                icon: Icons.whatshot, 
                onTap: () {
                  _searchController.text = 'Spicy';
                  _performSearch('Spicy');
                }
              ),
              const SizedBox(width: 12),
              _MoodChip(
                label: 'Sweet Cravings', 
                color: Colors.orange.shade800, 
                icon: Icons.cookie, 
                onTap: () {
                  _searchController.text = 'Sweet';
                  _performSearch('Sweet');
                }
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MoodChip(
            label: 'The Andhra Special', 
            color: const Color(0xFF18453B), 
            icon: Icons.auto_awesome, 
            onTap: () {
              _searchController.text = 'Andhra';
              _performSearch('Andhra');
            }
          ),
          
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF18453B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFFD4AF37)),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    'AI: Try searching "spicy morning snack"',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: const Color(0xFF18453B).withOpacity(0.1)),
            const SizedBox(height: 20),
            const Text('No flavors matched your search.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final product = searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(product.image, width: 60, height: 60, fit: BoxFit.cover),
              ),
              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(product.category, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
              trailing: Text(product.defaultPrice, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
              onTap: () => AppNavigator.push(context, ProductDetailPage(product: product)),
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _MoodChip({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
