import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class KitchenStoryPage extends StatefulWidget {
  const KitchenStoryPage({super.key});

  @override
  State<KitchenStoryPage> createState() => _KitchenStoryPageState();
}

class _KitchenStoryPageState extends State<KitchenStoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildCinematicHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                children: [
                  _AdvancedStoryBlock(
                    index: "01",
                    year: '1982',
                    title: 'The First Spark',
                    content: 'In a sun-drenched kitchen in coastal Andhra, our grandmother started a revolution. With just 5kg of seasonal mangoes and an ancestral blend of hand-ground spices, the first jar of Adhvaitha was born from pure love.',
                    image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
                  ),
                  const SizedBox(height: 120),
                  _AdvancedStoryBlock(
                    index: "02",
                    year: 'Ritual',
                    title: 'Sun, Salt & Patience',
                    content: 'We refuse to rush. Each batch is a commitment to time. We wait for the peak coastal sun to naturally dehydrate our produce for 48 hours, locking in the soul of the fruit before it meets the jar.',
                    image: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
                    isReversed: true,
                  ),
                  const SizedBox(height: 120),
                  _AdvancedStoryBlock(
                    index: "03",
                    year: 'The Legacy',
                    title: 'Stone-Ground Soul',
                    content: 'While industrial grinders destroy flavor with heat, we stay loyal to the stone mortar. Our spices are slowly crushed to release essential oils, preserving the aroma that defines our heritage.',
                    image: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
                  ),
                  const SizedBox(height: 150),
                  _buildStatsGrid(),
                  const SizedBox(height: 150),
                  _buildGrandmotherQuote(),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCinematicHeader() {
    return SliverAppBar(
      expandedHeight: 600,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF18453B),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const CircleAvatar(
          backgroundColor: Colors.black26,
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
              fit: BoxFit.cover,
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.15, 1.15), duration: 20.seconds),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    const Color(0xFF18453B).withOpacity(0.8),
                    const Color(0xFF18453B),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 60)
                      .animate().scale(duration: 1.5.seconds, curve: Curves.elasticOut),
                  const SizedBox(height: 40),
                  Text(
                    'OUR JOURNEY',
                    style: GoogleFonts.philosopher(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 16,
                    ),
                  ).animate().fadeIn(duration: 1.5.seconds).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 20),
                  Container(
                    height: 1.5, width: 100, color: const Color(0xFFD4AF37),
                  ).animate().scaleX(duration: 1.5.seconds, delay: 500.ms),
                  const SizedBox(height: 25),
                  Text(
                    'A TRADITION KEPT SACRED SINCE 1982',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFD4AF37),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      fontSize: 12,
                    ),
                  ).animate().fadeIn(delay: 1.seconds),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF18453B),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF18453B).withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statBox('42+', 'YEARS OF HERITAGE'),
              _statBox('1M+', 'HAND-PACKED JARS'),
            ],
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Divider(color: const Color(0xFFD4AF37).withOpacity(0.2), thickness: 1),
          ),
          const SizedBox(height: 60),
          _statBox('100%', 'NATURAL, PURE & CRAFTED'),
        ],
      ),
    ).animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _statBox(String val, String label) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.philosopher(color: const Color(0xFFD4AF37), fontSize: 48, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 4)),
      ],
    );
  }

  Widget _buildGrandmotherQuote() {
    return Column(
      children: [
        const Icon(Icons.format_quote_rounded, color: Color(0xFFD4AF37), size: 100),
        const SizedBox(height: 40),
        Text(
          '“We don\'t just sell pickles;\nwe sell the lingering warmth\nof my grandmother\'s kitchen.”',
          textAlign: TextAlign.center,
          style: GoogleFonts.philosopher(
            fontStyle: FontStyle.italic,
            fontSize: 34,
            color: const Color(0xFF18453B),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 80),
        const Text(
          'ESTABLISHED 1982 • COASTAL ANDHRA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFFD4AF37),
            letterSpacing: 8,
            fontSize: 12,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 2.seconds);
  }
}

class _AdvancedStoryBlock extends StatelessWidget {
  final String index, year, title, content, image;
  final bool isReversed;

  const _AdvancedStoryBlock({
    required this.index,
    required this.year,
    required this.title,
    required this.content,
    required this.image,
    this.isReversed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isReversed ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isReversed ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Text(
              index,
              style: GoogleFonts.philosopher(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                fontSize: 80,
                fontWeight: FontWeight.w900,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .shimmer(duration: 4.seconds, color: const Color(0xFFD4AF37).withOpacity(0.4)),
            const SizedBox(width: 25),
            Text(
              year,
              style: GoogleFonts.philosopher(
                color: const Color(0xFFD4AF37),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ).animate().blurXY(begin: 10, end: 0, duration: 1.seconds),
          ],
        ).animate().fadeIn(duration: 1.2.seconds).slideX(begin: isReversed ? 0.3 : -0.3, end: 0),
        
        const SizedBox(height: 30),
        
        Text(
          title,
          textAlign: isReversed ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.philosopher(
            fontSize: 46,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF18453B),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0).blurXY(begin: 8, end: 0, delay: 300.ms),
        
        const SizedBox(height: 40),
        
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(image, fit: BoxFit.cover)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 12.seconds),
          ),
        ).animate().scale(delay: 500.ms, duration: 1.seconds, curve: Curves.easeOutQuart),
        
        const SizedBox(height: 40),
        
        Text(
          content,
          textAlign: isReversed ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: const Color(0xFF2D1B12).withOpacity(0.7),
            height: 2.0,
          ),
        ).animate().fadeIn(delay: 1.seconds).blurXY(begin: 5, end: 0, delay: 1.seconds),
      ],
    );
  }
}
