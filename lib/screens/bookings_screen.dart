import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import '../services/vendor_service.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../models/complaint_model.dart';
import '../models/vendor_model.dart';
import '../providers/auth_provider.dart';
import 'login_selection_screen.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _activeVendorView = 'dashboard'; 
  String _paymentFilter = 'pending'; 
  bool _isProcessing = false;
  
  // Client filter
  String _selectedStatusFilter = 'All';

  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color darkPurple = const Color(0xFF2D1B4D);
  final Color accentPink = const Color(0xFFD84B6B);
  final Color creamBg = const Color(0xFFF9F7F5);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    if (!auth.isLoggedIn) {
      return _buildLoginRequired(primaryPurple);
    }

    // ⭐ SERVICE PROVIDER MANAGEMENT VIEW
    if (auth.userData?.role == UserRole.serviceProvider) {
      return Scaffold(
        backgroundColor: creamBg,
        body: Column(
          children: [
            _buildVendorTopNav(primaryPurple),
            Expanded(
              child: _buildVendorActiveView(auth.userData!, theme),
            ),
          ],
        ),
      );
    }

    // ⭐ CLIENT BOOKING VIEW
    return Scaffold(
      backgroundColor: creamBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PURPLE HEADER for Client
          Container(
            padding: EdgeInsets.fromLTRB(24, topPadding + 10, 16, 25),
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryPurple,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Bookings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Filter Tabs
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _statusFilterChip('All'),
                _statusFilterChip('Confirmed'),
                _statusFilterChip('Pending'),
                _statusFilterChip('Cancelled'),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          Expanded(
            child: _buildClientBookings(auth.userData!, theme),
          ),
        ],
      ),
    );
  }

  Widget _statusFilterChip(String label) {
    final isSelected = _selectedStatusFilter == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatusFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? accentPink : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? accentPink : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientBookings(AppUser user, ThemeData theme) {
    return FutureBuilder<List<Booking>>(
      future: BookingService.getMyBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: primaryPurple));
        }
        
        var bookings = snapshot.data ?? [];
        if (_selectedStatusFilter != 'All') {
          bookings = bookings.where((b) => 
            b.status.name.toLowerCase() == _selectedStatusFilter.toLowerCase()
          ).toList();
        }

        if (bookings.isEmpty) return _emptyState('No $_selectedStatusFilter bookings found.');

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          itemCount: bookings.length,
          itemBuilder: (context, index) => _buildBookingItem(bookings[index], theme),
        );
      },
    );
  }

  Widget _buildBookingItem(Booking booking, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: accentPink.withOpacity(0.08), borderRadius: BorderRadius.circular(15)),
                child: Icon(Icons.calendar_today_outlined, color: accentPink, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.vendorName, style: TextStyle(color: darkPurple, fontSize: 18, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(booking.vendorCategory, style: TextStyle(color: accentPink, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
              _buildStatusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Column(
              children: [
                _detailInfoRow(Icons.calendar_month_outlined, booking.note.isEmpty ? 'Wedding Event' : booking.note, darkPurple),
                const SizedBox(height: 10),
                _detailInfoRow(Icons.attach_money_rounded, '₹${booking.price} - ₹${(booking.price * 1.5).toInt()}', darkPurple),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (booking.status != BookingStatus.cancelled)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleBookingAction(booking.id, 'cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentPink,
                  side: BorderSide(color: accentPink.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color color = const Color(0xFFFDB528);
    Color bg = const Color(0xFFFFF9E6);
    if (status == BookingStatus.confirmed) {
      color = Colors.green;
      bg = Colors.green.withOpacity(0.1);
    } else if (status == BookingStatus.cancelled) {
      color = Colors.red;
      bg = Colors.red.withOpacity(0.1);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _detailInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.3)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: color.withOpacity(0.6), fontSize: 15, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  // --- VENDOR MANAGEMENT VIEWS ---

  Widget _buildVendorTopNav(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 50, 10, 15),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.dashboard_rounded, 'DASHBOARD', 'dashboard'),
            _navItem(Icons.assignment_ind_rounded, 'REQUESTS', 'requests'),
            _navItem(Icons.account_balance_wallet_rounded, 'PAYMENTS', 'payments'),
            _navItem(Icons.report_problem_rounded, 'REPORTS', 'reports'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, String view) {
    bool isSelected = _activeVendorView == view;
    return GestureDetector(
      onTap: () => setState(() => _activeVendorView = view),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorActiveView(AppUser user, ThemeData theme) {
    switch (_activeVendorView) {
      case 'dashboard': return _buildProviderProfileDashboard(user, theme);
      case 'payments': return _buildVendorPaymentsView(theme);
      case 'reports': return _buildVendorReportsView(theme);
      default: return _buildVendorRequestsView(theme);
    }
  }

  Widget _buildProviderProfileDashboard(AppUser user, ThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: VendorService.getVendor(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) return _emptyState('Vendor profile not found.');
        final vendor = Vendor.fromJson(snapshot.data!);
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vendor.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: darkPurple), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.orange[400], size: 20),
                  const SizedBox(width: 4),
                  Text('${vendor.rating} (${vendor.reviewCount} Reviews)', style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 25),
              LayoutBuilder(
                builder: (context, constraints) {
                  double itemWidth = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _statItemBox('${vendor.viewsCount}', 'Viewers', Colors.blue, itemWidth),
                      _statItemBox('0', 'Messages', Colors.purple, itemWidth),
                      _statItemBox('0', 'Complaints', Colors.red, itemWidth),
                      _statItemBox('${vendor.weddingsCount}', 'Confirmed', Colors.green, itemWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 35),
              Text('Portfolio Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkPurple)),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: vendor.portfolio.isEmpty ? 1 : vendor.portfolio.length,
                  itemBuilder: (context, index) {
                    String imgUrl = vendor.portfolio.isEmpty ? 'https://img.freepik.com/free-photo/wedding-setup_23-2148855013.jpg' : vendor.portfolio[index];
                    return Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: CachedNetworkImageProvider(imgUrl), fit: BoxFit.cover),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 35),
              _buildSectionTitle('Business Details'),
              _infoDetailTile(Icons.phone_rounded, user.phone),
              _infoDetailTile(Icons.location_on_rounded, '${vendor.block}, ${vendor.city}'),
              _infoDetailTile(Icons.work_rounded, '${vendor.yearsOfExperience} years experience'),
              _infoDetailTile(Icons.currency_rupee_rounded, '₹${vendor.minPrice} Base Price'),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _statItemBox(String val, String label, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color))
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withOpacity(0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildVendorRequestsView(ThemeData theme) {
    return FutureBuilder<List<Booking>>(
      future: BookingService.getMyBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = (snapshot.data ?? []).where((b) => b.status == BookingStatus.pending).toList();
        if (requests.isEmpty) return _emptyState('No pending requests found.');
        
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final b = requests[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(b.vendorName, style: TextStyle(fontWeight: FontWeight.w900, color: darkPurple, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Event: ${b.note}\nDate: ${DateFormat('dd MMM yyyy').format(b.createdAt)}', style: const TextStyle(height: 1.5)),
                    trailing: Text('₹${b.price}', style: TextStyle(fontWeight: FontWeight.w900, color: primaryPurple, fontSize: 18)),
                  ),
                  const Divider(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleBookingAction(b.id, 'cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('DECLINE', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleBookingAction(b.id, 'confirm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVendorPaymentsView(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _paymentFilterToggle('PENDING', 'pending', Colors.orange),
              const SizedBox(width: 15),
              _paymentFilterToggle('SUCCESS', 'success', Colors.green),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: PaymentService.getVendorPayments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final payments = (snapshot.data ?? []).where((p) => p['status'] == _paymentFilter).toList();
              if (payments.isEmpty) return _emptyState('No $_paymentFilter payments.');
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final p = payments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _paymentFilter == 'success' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        child: Icon(Icons.payments_rounded, color: _paymentFilter == 'success' ? Colors.green : Colors.orange),
                      ),
                      title: Text('₹${p['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(DateFormat('dd MMM').format(DateTime.parse(p['createdAt'])), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  Widget _paymentFilterToggle(String label, String filter, Color color) {
    bool isSelected = _paymentFilter == filter;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color, width: 2),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)] : null,
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _buildVendorReportsView(ThemeData theme) {
    return FutureBuilder<List<Complaint>>(
      future: VendorService.getMyComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];
        if (reports.isEmpty) return _emptyState('No reports found.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: reports.length,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
            child: Row(
              children: [
                const Icon(Icons.report_problem, color: Colors.redAccent, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reports[index].description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('Reported on: ${DateFormat('dd MMM yyyy').format(reports[index].createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBookingAction(String id, String action) async {
    setState(() => _isProcessing = true);
    try {
      if (action == 'confirm') {
        await BookingService.confirmBooking(id);
      } else {
        await BookingService.cancelVendor(id, 'Action by user');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Booking ${action == "confirm" ? "confirmed" : "cancelled"} successfully'),
          backgroundColor: action == "confirm" ? Colors.green : Colors.red,
        ));
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _infoDetailTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey), 
        const SizedBox(width: 12), 
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis))
      ]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkPurple)),
    );
  }

  Widget _emptyState(String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.withOpacity(0.2)),
      const SizedBox(height: 10),
      Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    ]));
  }

  Widget _buildLoginRequired(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 80, color: primary.withOpacity(0.1)),
          const SizedBox(height: 20),
          const Text('Session Expired', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginSelectionScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('SIGN IN NOW'),
          )
        ],
      ),
    );
  }
}
