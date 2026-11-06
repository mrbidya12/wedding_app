import 'package:flutter/material.dart';
import '../services/vendor_service.dart';
import '../widgets/vendor_card.dart';
import '../models/vendor_model.dart';

class BrowseScreen extends StatefulWidget {
  final String? initialCategory;
  const BrowseScreen({super.key, this.initialCategory});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final searchController = TextEditingController();
  late String selectedCategory;
  String searchQuery = '';
  
  List<Vendor> _allVendors = [];
  List<Vendor> _filteredVendors = [];
  bool _isLoading = true;

  final List<String> categories = [
    'All', 'Photography', 'Florist', 'Venue', 'Music', 'Catering', 'Mehendi Artist', 'Makeup'
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory ?? 'All';
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    
    // Immediate dummy data for responsiveness
    _allVendors = VendorService.getLocalVendors();
    _applyFilters();

    try {
      final vendors = await VendorService.getVendors(category: 'All');
      if (mounted) {
        setState(() {
          _allVendors = vendors;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredVendors = _allVendors.where((v) {
        final matchesCategory = selectedCategory == 'All' || v.category.toLowerCase() == selectedCategory.toLowerCase();
        final matchesSearch = searchQuery.isEmpty || v.name.toLowerCase().contains(searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryPurple = const Color(0xFF6A1B9A);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(24, topPadding + 10, 12, 25),
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryPurple,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore Experts',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (v) {
                      searchQuery = v;
                      _applyFilters();
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (s) {
                      setState(() => selectedCategory = cat);
                      _applyFilters();
                    },
                    selectedColor: const Color(0xFFD84B6B),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    backgroundColor: Colors.white,
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2))),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading && _filteredVendors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredVendors.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VendorCard(vendor: _filteredVendors[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
