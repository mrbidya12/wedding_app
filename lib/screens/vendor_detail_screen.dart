import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:weddingpro_connect/models/vendor_model.dart';
import 'package:weddingpro_connect/providers/auth_provider.dart';
import 'package:weddingpro_connect/providers/language_provider.dart';
import 'package:weddingpro_connect/screens/login_selection_screen.dart';
import 'package:weddingpro_connect/screens/chat_detail_screen.dart';
import 'package:weddingpro_connect/services/vendor_service.dart';

class VendorDetailScreen extends StatefulWidget {
  final Vendor vendor;
  const VendorDetailScreen({super.key, required this.vendor});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _complaintImage;
  bool _isSubmitting = false;

  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color darkPurple = const Color(0xFF2D1B4D);
  final Color accentPink = const Color(0xFFD84B6B);

  void _checkAuthAndAction(BuildContext context, VoidCallback onAuthenticated) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      onAuthenticated();
    } else {
      _showLoginPrompt(context);
    }
  }

  void _showLoginPrompt(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Text('Please login to contact vendors or file complaints.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.translate('cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginSelectionScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(lang.translate('login')),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(StateSetter setDialogState) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setDialogState(() {
        _complaintImage = File(image.path);
      });
    }
  }

  void _showComplaintDialog(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final theme = Theme.of(context);
    final descriptionController = TextEditingController();
    _complaintImage = null;

    showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.report_problem_rounded, color: Colors.red),
              const SizedBox(width: 10),
              Flexible(child: Text(lang.translate('complaints'), style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Reporting: ${widget.vendor.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(height: 10),
                const Text('Please describe the issue and upload a photo as proof.'),
                const SizedBox(height: 15),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter details here...',
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => _pickImage(setDialogState),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _complaintImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(_complaintImage!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: theme.colorScheme.primary, size: 30),
                              const SizedBox(height: 8),
                              const Text('Upload Proof', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context), 
              child: Text(lang.translate('cancel'))
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () async {
                if (descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description')));
                  return;
                }
                
                setDialogState(() => _isSubmitting = true);
                
                try {
                  final success = await VendorService.submitComplaint(
                    vendorId: widget.vendor.id,
                    vendorName: widget.vendor.name,
                    description: descriptionController.text.trim(),
                    imageUrl: _complaintImage?.path,
                  );
                  
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Complaint sent to Admin. A copy is saved in your records.'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red));
                } finally {
                  setDialogState(() => _isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250, // More compact
            pinned: true,
            stretch: true,
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.vendor.imageUrl, 
                    fit: BoxFit.cover, 
                    errorWidget: (context, url, error) => Container(color: theme.disabledColor.withOpacity(0.1), child: const Icon(Icons.image, color: Colors.grey, size: 50))
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- VENDOR NAME ---
                  Text(
                    widget.vendor.name, 
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: darkPurple,
                      letterSpacing: -0.5,
                    )
                  ),
                  const SizedBox(height: 8),
                  
                  // --- RATING ROW ---
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < widget.vendor.rating.floor() ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${widget.vendor.rating} (${widget.vendor.reviewCount})', 
                          style: TextStyle(
                            fontSize: 13, 
                            color: darkPurple.withOpacity(0.7), 
                            fontWeight: FontWeight.w600
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- DETAILS LIST ---
                  _buildIconText(Icons.phone_rounded, '+91 98765 43210'),
                  _buildIconText(Icons.location_on_rounded, '${widget.vendor.city}, ${widget.vendor.state}'),
                  _buildPriceText(widget.vendor.minPrice, widget.vendor.maxPrice),
                  _buildIconText(Icons.business_center_rounded, '${widget.vendor.yearsOfExperience} years experience'),
                  
                  const SizedBox(height: 20),

                  // --- STATS HIGHLIGHTS ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: primaryPurple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('${widget.vendor.weddingsCount}+', 'Weddings'),
                        Container(height: 25, width: 1, color: Colors.grey.withOpacity(0.2)),
                        _buildStatColumn('${widget.vendor.satisfactionRate}%', 'Happy'),
                        Container(height: 25, width: 1, color: Colors.grey.withOpacity(0.2)),
                        _buildStatColumn(widget.vendor.status, 'Status'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  Text(
                    'About', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkPurple)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.vendor.description,
                    style: TextStyle(fontSize: 14, color: darkPurple.withOpacity(0.8), height: 1.5),
                  ),

                  const SizedBox(height: 30),
                  
                  Text(
                    'Portfolio', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkPurple)
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160, 
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.vendor.portfolio.isEmpty ? 3 : widget.vendor.portfolio.length,
                      itemBuilder: (context, index) {
                        String imgUrl = widget.vendor.portfolio.isEmpty 
                          ? 'https://img.freepik.com/free-photo/wedding-setup_23-2148855013.jpg'
                          : widget.vendor.portfolio[index];
                        return Container(
                          width: 220, 
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: CachedNetworkImageProvider(imgUrl), fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white, 
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                  label: const FittedBox(child: Text('CHAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  onPressed: () {
                    _checkAuthAndAction(context, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(receiverId: widget.vendor.id, receiverName: widget.vendor.name, vendorId: widget.vendor.id)));
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const FittedBox(child: Text('CALL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF53B553),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: primaryPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(fontSize: 14, color: darkPurple.withOpacity(0.85), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceText(int min, int? max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, size: 16, color: primaryPurple),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '₹${_formatPrice(min)}${max != null ? " - ₹${_formatPrice(max)}" : ""}', 
              style: TextStyle(fontSize: 14, color: darkPurple.withOpacity(0.85), fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(price).trim();
  }

  Widget _buildStatColumn(String val, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val, 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accentPink),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label, 
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
