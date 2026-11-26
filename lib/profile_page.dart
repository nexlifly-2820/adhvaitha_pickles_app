// profile_page.dart — the customer's real profile: details, saved addresses, orders, wishlist,
// help & legal pages, logout. Everything comes from the signed-in account (no demo data).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'address_book.dart';
import 'address_form_sheet.dart';
import 'user_manager.dart';
import 'order_manager.dart';
import 'wishlist_manager.dart';
import 'models.dart';
import 'main.dart';
import 'navigation_util.dart';
import 'login_page.dart';
import 'contact_us_page.dart';
import 'faq_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';
import 'refund_policy_page.dart';
import 'coupons_page.dart';
import 'profile_extras.dart';
import 'cart_page.dart';
import 'screens/order_details_screen.dart';

const Color _bg = Color(0xFFFBF6EF), _ink = Color(0xFF2A1A14), _muted = Color(0xFF8A7464), _line = Color(0xFFEADFD2);
const Color _maroon = Color(0xFF7A1426), _gold = Color(0xFFE9C46A), _green = Color(0xFF1F7A45);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    AddressBook().ensureLoaded();
    OrderManager().ensureLoaded();
    AppPrefs().load();
  }

  String get _initials {
    final List<String> p = UserManager().userName.trim().split(RegExp(r'\s+')).where((String e) => e.isNotEmpty).toList();
    if (p.isEmpty) return '🙏';
    return (p.first[0] + (p.length > 1 ? p.last[0] : '')).toUpperCase();
  }

  String get _since {
    final DateTime? d = UserManager().memberSince;
    if (d == null) return '';
    const List<String> m = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Member since ${m[d.month - 1]} ${d.year}';
  }

  void _go(int tab) {
    HapticFeedback.selectionClick();
    final dynamic main = MainScreen.of(context);
    if (main != null) main.setIndex(tab);
  }

  void _open(Widget page) {
    HapticFeedback.selectionClick();
    AppNavigator.push(context, page);
  }

  Future<void> _editProfile() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _EditProfileSheet());
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext c) => AlertDialog(
            title: Text('Log out?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            content: Text('You can log back in anytime with your email.', style: GoogleFonts.poppins(fontSize: 13)),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: GoogleFonts.poppins(color: _muted))),
              TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Log out', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _maroon))),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    await UserManager().logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const LoginPage()), (Route<dynamic> r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
        body: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[UserManager(), AddressBook(), OrderManager(), WishlistManager(), AppPrefs()]),
          builder: (BuildContext c, _) => CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _stats()),
              SliverToBoxAdapter(child: _orderCards()),
              SliverToBoxAdapter(child: _addresses()),
              SliverToBoxAdapter(
                child: _section('MY ACCOUNT', <Widget>[
                  _row(Icons.receipt_long_rounded, 'My orders', 'Track, view details, reorder', () => _go(3)),
                  _row(Icons.favorite_rounded, 'Wishlist', 'Products you saved', () => _go(2)),
                  _row(Icons.local_offer_rounded, 'Coupons & offers', 'Save more on your next order', () => _open(const CouponsPage())),
                  _row(Icons.rate_review_rounded, 'My reviews', 'Letters you wrote to Amma', () => _open(const MyReviewsPage())),
                  _row(Icons.person_rounded, 'Edit profile', 'Name, phone and email', _editProfile),
                ]),
              ),
              SliverToBoxAdapter(
                child: _section('SETTINGS', <Widget>[
                  _row(Icons.notifications_active_rounded, 'Notifications', 'Order updates, offers, reminders', () => showNotificationSettings(context)),
                  _row(Icons.translate_rounded, 'Language', AppPrefs().language == 'te' ? 'తెలుగు' : 'English', () => showLanguagePicker(context)),
                ]),
              ),
              SliverToBoxAdapter(
                child: _section('SPREAD THE LOVE', <Widget>[
                  _row(Icons.card_giftcard_rounded, 'Refer a friend', 'Share your welcome code', () => shareReferral(context)),
                  _row(Icons.star_rate_rounded, 'Rate us on Play Store', "Tell others about Amma's kitchen", () => rateApp(context)),
                  _row(Icons.share_rounded, 'Share the app', 'Send Ambhujakshi to family & friends', shareApp),
                ]),
              ),
              SliverToBoxAdapter(
                child: _section('HELP & SUPPORT', <Widget>[
                  _row(Icons.support_agent_rounded, 'Contact us', 'Call, WhatsApp or email us', () => _open(const ContactUsPage())),
                  _row(Icons.help_outline_rounded, 'FAQs', 'Delivery, payments, returns', () => _open(const FaqPage())),
                ]),
              ),
              SliverToBoxAdapter(
                child: _section('LEGAL', <Widget>[
                  _row(Icons.privacy_tip_outlined, 'Privacy policy', null, () => _open(const PrivacyPolicyPage())),
                  _row(Icons.description_outlined, 'Terms of service', null, () => _open(const TermsOfServicePage())),
                  _row(Icons.currency_rupee_rounded, 'Refund & cancellation', null, () => _open(const RefundPolicyPage())),
                ]),
              ),
              SliverToBoxAdapter(child: _logoutButton()),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  String get _displayName {
    final String n = UserManager().userName.trim();
    if (n.isEmpty) return 'Welcome';
    return n.split(RegExp(r'\s+')).map((String w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  Widget _chip(IconData icon, String text, {bool gold = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: gold ? _gold : Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(icon, size: 12, color: gold ? const Color(0xFF5A1A10) : Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: gold ? FontWeight.w600 : FontWeight.w500, color: gold ? const Color(0xFF5A1A10) : Colors.white)),
          ),
        ]),
      );

  Widget _header() {
    final UserManager u = UserManager();
    final double top = MediaQuery.of(context).padding.top;
    final String n = u.userName.trim();
    return Stack(clipBehavior: Clip.none, children: <Widget>[
      Container(
        margin: const EdgeInsets.only(bottom: 44),
        padding: EdgeInsets.fromLTRB(18, top + 16, 18, 58),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFF9E1424), Color(0xFF6A0F1E)]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFF4E2), border: Border.all(color: _gold, width: 3)),
              child: n.isEmpty
                  ? const Icon(Icons.person_rounded, color: _maroon, size: 32)
                  : Text(n[0].toUpperCase(), style: GoogleFonts.philosopher(fontSize: 28, fontWeight: FontWeight.w700, color: _maroon)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(tr('Namaskaram 🙏'), style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(.85))),
                const SizedBox(height: 2),
                Text(_displayName, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.philosopher(fontSize: 22, height: 1.15, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _editProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(.35))),
                child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(tr('Edit'), style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 6, runSpacing: 6, children: <Widget>[
            if (u.email.isNotEmpty) _chip(Icons.mail_outline_rounded, u.email),
            if (u.phone.isNotEmpty) _chip(Icons.phone_rounded, '+91 ${u.phone}'),
            if (_since.isNotEmpty) _chip(Icons.star_rounded, _since, gold: true),
          ]),
        ]),
      ),
      Positioned(left: 16, right: 16, bottom: 0, child: _statsCard()),
    ]);
  }

  Widget _stats() => const SizedBox(height: 4);

  Widget _orderCards() {
    final List<Order> o = OrderManager().orders;
    if (o.isEmpty) return const SizedBox.shrink();
    Order? live;
    for (final Order x in o) {
      if (isActiveOrder(x)) {
        live = x;
        break;
      }
    }
    final Order last = o.first;
    return Column(children: <Widget>[
      if (live != null) LiveOrderCard(order: live, onTrack: () => _open(OrderDetailsScreen(orderId: live!.id))),
      if (last.items.isNotEmpty) ReorderCard(order: last, onDone: () => _open(const CartPage())),
    ]);
  }

  Widget _statsCard() {
    final List<Order> o = OrderManager().orders;
    final int active = o.where((Order x) {
      final String s = x.status.toLowerCase();
      return !s.contains('deliver') && !s.contains('cancel');
    }).length;
    Widget cell(String n, String label, VoidCallback onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Text(n, style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w800, color: _ink)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10.5, color: _muted)),
              ]),
            ),
          ),
        );
    Widget sep() => Container(width: 1, height: 34, color: _line);
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: <BoxShadow>[BoxShadow(color: _maroon.withOpacity(.12), blurRadius: 18, offset: const Offset(0, 8))]),
        child: Row(children: <Widget>[
          cell('${o.length}', active > 0 ? '${tr('Orders')} · $active ${tr('active')}' : tr('Orders'), () => _go(3)),
          sep(),
          cell('${WishlistManager().items.length}', tr('Wishlist'), () => _go(2)),
          sep(),
          cell('${AddressBook().addresses.length}', tr('Addresses'), () async {
            await showAddressForm(context);
          }),
        ]),
      ),
    );
  }

  Widget _addresses() {
    final List<DeliveryAddress> list = AddressBook().addresses;
    return _section(
      'MY ADDRESSES',
      <Widget>[
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text('No saved address yet. Add one to check out faster.', style: GoogleFonts.poppins(fontSize: 12.5, color: _muted)),
          ),
        for (final DeliveryAddress a in list) _addressTile(a),
        InkWell(
          onTap: () => showAddressForm(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: <Widget>[
              const Icon(Icons.add_location_alt_rounded, color: _maroon, size: 20),
              const SizedBox(width: 12),
              Text('Add a new address', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: _maroon)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _addressTile(DeliveryAddress a) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: a.isDefault ? const Color(0xFFFFF6F2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: a.isDefault ? _maroon.withOpacity(.4) : _line),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(a.type == 'OFFICE' ? Icons.work_rounded : a.type == 'OTHER' ? Icons.place_rounded : Icons.home_rounded, size: 20, color: _maroon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: <Widget>[
              Text(a.label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
              if (a.isDefault) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: _green.withOpacity(.12), borderRadius: BorderRadius.circular(6)),
                  child: Text('DEFAULT', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: _green)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text('${a.name} · +91 ${a.phone}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
            Text(a.line, style: GoogleFonts.poppins(fontSize: 11.5, height: 1.35, color: _muted)),
          ]),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: _muted),
          onSelected: (String v) async {
            if (v == 'edit') await showAddressForm(context, edit: a);
            if (v == 'default') await AddressBook().setDefault(a.id);
            if (v == 'delete') {
              final bool ok = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext c) => AlertDialog(
                      title: Text('Delete this address?', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                      content: Text(a.line, style: GoogleFonts.poppins(fontSize: 12.5)),
                      actions: <Widget>[
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: _maroon))),
                      ],
                    ),
                  ) ??
                  false;
              if (ok) await AddressBook().remove(a.id);
            }
          },
          itemBuilder: (_) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
            if (!a.isDefault) const PopupMenuItem<String>(value: 'default', child: Text('Set as default')),
            const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
          ],
        ),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(tr(title), style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: _muted)),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ]),
      );

  Widget _row(IconData icon, String title, String? sub, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: <Widget>[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFFBEFE6), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 19, color: _maroon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(tr(title), style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: _ink)),
                if (sub != null) Text(tr(sub), style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ]),
        ),
      );

  Widget _logoutButton() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Column(children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: _maroon),
              label: Text(tr('Log out'), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _maroon)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: _maroon), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          TextButton(
            onPressed: () => deleteAccountFlow(context, onDeleted: () {
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const LoginPage()), (Route<dynamic> r) => false);
            }),
            child: Text(tr('Delete my account'), style: GoogleFonts.poppins(fontSize: 12, color: _muted, decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: 4),
          Text('Ambhujakshi v$kAppVersion · Made with love in Andhra', style: GoogleFonts.poppins(fontSize: 10.5, color: _muted)),
        ]),
      );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final TextEditingController _name = TextEditingController(text: UserManager().userName);
  final TextEditingController _phone = TextEditingController(text: UserManager().phone);
  bool _tried = false, _saving = false;

  bool get _nameOk => _name.text.trim().length >= 2;
  bool get _phoneOk => _phone.text.trim().isEmpty || RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text.trim());

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_nameOk || !_phoneOk) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _saving = true);
    await UserManager().setUser(name: _name.text.trim(), email: UserManager().email, phone: _phone.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration dec(String l, String? err) => InputDecoration(
          labelText: l,
          errorText: err,
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _maroon, width: 1.4)),
        );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: _bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDACDB8), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Text('Edit profile', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 14),
            TextField(controller: _name, textCapitalization: TextCapitalization.words, onChanged: (_) => setState(() {}), decoration: dec('Full name', _tried && !_nameOk ? 'Enter your name' : null)),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: dec('Phone number', _tried && !_phoneOk ? 'Enter a valid 10-digit number' : null).copyWith(prefixText: '+91 '),
            ),
            const SizedBox(height: 10),
            TextField(
              enabled: false,
              controller: TextEditingController(text: UserManager().email),
              decoration: dec('Email (used to log in)', null),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : Text('Save', style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
