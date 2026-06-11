import 'package:flutter/material.dart';
import 'models.dart';
import 'product_detail_page.dart';
import 'product_repository.dart';
import 'navigation_util.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = ['Mango Pickle', 'Chakinalu', 'Ladoo'];
  List<String> trendingSearches = ['Chicken Pickle', 'Garam Masala', 'Amla Pickle'];
  List<Product> searchResults = [];
  bool isSearching = false;

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
      searchResults = ProductRepository.allProducts.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
               product.category.toLowerCase().contains(query.toLowerCase()) ||
               product.description.toLowerCase().contains(query.toLowerCase());
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
          ),
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
        );
      },
    );
  }
}
