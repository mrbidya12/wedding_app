import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weddingpro_connect/providers/auth_provider.dart';
import 'package:weddingpro_connect/models/user_model.dart';
import 'package:weddingpro_connect/models/complaint_model.dart';
import 'package:weddingpro_connect/services/user_service.dart';
import 'package:weddingpro_connect/services/admin_service.dart';
import 'package:intl/intl.dart';

class ManagementScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const ManagementScreen({super.key, this.scaffoldKey});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime? date1, DateTime date2) {
    if (date1 == null) return false;
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    if (!authProvider.isLoggedIn || authProvider.userData?.role != UserRole.admin) {
      return const Scaffold(body: Center(child: Text('Admin Access Required')));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: widget.scaffoldKey != null ? IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => widget.scaffoldKey!.currentState?.openDrawer(),
        ) : null,
        title: const Text('ADMIN CONTROL HUB', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Filter Records by Date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context, 
                initialDate: _selectedDate, 
                firstDate: DateTime(2020), 
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: theme.copyWith(colorScheme: theme.colorScheme.copyWith(primary: primaryColor)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.group_rounded), text: 'USERS'),
            Tab(icon: Icon(Icons.currency_rupee_rounded), text: 'TRANSFERS'),
            Tab(icon: Icon(Icons.pending_actions_rounded), text: 'REPORTS'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateIndicator(primaryColor),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(primaryColor),
                _buildMoneyTransferTab(primaryColor),
                _buildReportsTab(primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateIndicator(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: primary.withValues(alpha: 0.05),
      child: Text(
        'RECORDS FOR: ${DateFormat('dd MMMM yyyy').format(_selectedDate).toUpperCase()}',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w900, color: primary, fontSize: 13, letterSpacing: 0.5),
      ),
    );
  }

  // 👤 1. USERS & BLOCKING TAB
  Widget _buildUsersTab(Color primary) {
    return FutureBuilder<List<AppUser>>(
      future: UserService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildEmptyState('Error loading users: ${snapshot.error}');
        
        final users = (snapshot.data ?? []).where((u) => _isSameDay(u.createdAt, _selectedDate)).toList();
        
        if (users.isEmpty) return _buildEmptyState('No registration records on this date.');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserCard(users[index], primary),
        );
      },
    );
  }

  Widget _buildUserCard(AppUser user, Color primary) {
    bool isVendor = user.role == UserRole.serviceProvider;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: user.isBlocked 
              ? Colors.red.withValues(alpha: 0.1) 
              : (isVendor ? Colors.orange.withValues(alpha: 0.1) : primary.withValues(alpha: 0.1)),
          child: Icon(isVendor ? Icons.store_rounded : Icons.person_rounded, color: user.isBlocked ? Colors.red : (isVendor ? Colors.orange : primary)),
        ),
        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user.role.name.toUpperCase()),
        trailing: TextButton(
          onPressed: _isLoadingAction ? null : () => _confirmAction(user),
          style: TextButton.styleFrom(foregroundColor: user.isBlocked ? Colors.green : Colors.red),
          child: Text(user.isBlocked ? 'UNBLOCK' : 'BLOCK'),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _detailRow(Icons.email_outlined, 'Email', user.email),
                _detailRow(Icons.phone_android_outlined, 'Contact', user.phone),
                _detailRow(Icons.location_on_outlined, 'Area', '${user.block}, ${user.city}'),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 💰 2. MONEY TRANSFER (PAYOUTS) TAB
  Widget _buildMoneyTransferTab(Color primary) {
    return FutureBuilder<List<dynamic>>(
      future: AdminService.getAllPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildEmptyState('Error loading payments: ${snapshot.error}');

        final payments = (snapshot.data ?? []).where((p) {
          final date = DateTime.tryParse(p['created_at']?.toString() ?? '');
          return _isSameDay(date, _selectedDate);
        }).toList();

        if (payments.isEmpty) return _buildEmptyState('No payout requests on this date.');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final p = payments[index];
            bool isReady = p['status'] == 'paid'; // Client paid, Admin needs to transfer
            return Card(
              color: isReady ? Colors.green.withValues(alpha: 0.05) : null,
              child: ListTile(
                title: Text('₹${p['amount']} to ${p['vendor_name'] ?? "Vendor"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Status: ${isReady ? "READY FOR TRANSFER" : (p['status'] ?? "PENDING").toString().toUpperCase()}'),
                trailing: isReady 
                  ? ElevatedButton(
                      onPressed: _isLoadingAction ? null : () => _showPayoutDialog((p['id'] ?? p['_id']).toString()),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('TRANSFER'),
                    )
                  : (p['status'] == 'completed' || p['status'] == 'payout_completed') 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // 🚩 3. PENDING REPORTS TAB
  Widget _buildReportsTab(Color primary) {
    return FutureBuilder<List<Complaint>>(
      future: AdminService.getAllComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _buildEmptyState('Error loading reports: ${snapshot.error}');

        final reports = (snapshot.data ?? []).where((r) => _isSameDay(r.createdAt, _selectedDate)).toList();
        
        if (reports.isEmpty) return _buildEmptyState('No pending reports for this date.');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final r = reports[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                title: Text('Against: ${r.vendorName}'),
                subtitle: Text(r.description, maxLines: 2),
                trailing: Text(DateFormat('hh:mm a').format(r.createdAt)),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI HELPERS ---

  Widget _detailRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey), 
        const SizedBox(width: 10), 
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)), 
        Expanded(child: Text(val, overflow: TextOverflow.ellipsis))
      ]),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
      const SizedBox(height: 10),
      Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    ]));
  }

  void _confirmAction(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.isBlocked ? "Unblock" : "Block"} ${user.fullName}?'),
        content: Text('Are you sure you want to ${user.isBlocked ? "allow" : "restrict"} this user access?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoadingAction = true);
              try {
                await UserService.toggleBlockUser(user.uid, !user.isBlocked);
                setState(() {
                  user.isBlocked = !user.isBlocked;
                });
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              } finally {
                if (mounted) setState(() => _isLoadingAction = false);
              }
            }, 
            child: const Text('CONFIRM')
          ),
        ],
      ),
    );
  }

  void _showPayoutDialog(String paymentId) {
    final upiIdController = TextEditingController();
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Money Transfer (Payout)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: upiIdController, decoration: const InputDecoration(labelText: 'Admin UPI ID', hintText: 'admin@bank')),
            TextField(controller: pinController, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'UPI PIN')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoadingAction = true);
              try {
                await AdminService.processPayout(paymentId, upiIdController.text.trim(), pinController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer Successful'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              } finally {
                if (mounted) setState(() => _isLoadingAction = false);
              }
            }, 
            child: const Text('SEND MONEY')
          ),
        ],
      ),
    );
  }
}
