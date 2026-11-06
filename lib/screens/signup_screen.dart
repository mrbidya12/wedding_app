import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weddingpro_connect/models/user_model.dart';
import 'package:weddingpro_connect/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Location Controllers (Required for all)
  final countryController = TextEditingController(text: 'India');
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final blockController = TextEditingController();
  final pincodeController = TextEditingController();
  
  // Provider Specific Controllers
  final experienceController = TextEditingController();
  final minPriceController = TextEditingController();
  final maxPriceController = TextEditingController();
  
  String? selectedCategory;
  UserRole selectedRole = UserRole.client;

  final List<String> categories = [
    'Brahmana', 'Mandop Owner', 'Wedding Cook', 
    'Mehendi Artist', 'Sound System', 'Bridal Makeup', 
    'Wedding Organizer', 'Photography'
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    countryController.dispose();
    stateController.dispose();
    cityController.dispose();
    blockController.dispose();
    pincodeController.dispose();
    experienceController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('WHO ARE YOU?'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildRoleOption(UserRole.client, 'CLIENT', Icons.person_outline, primaryColor),
                  const SizedBox(width: 15),
                  _buildRoleOption(UserRole.serviceProvider, 'PROVIDER', Icons.business_center_outlined, primaryColor),
                ],
              ),
              const SizedBox(height: 35),

              _buildSectionHeader('PERSONAL DETAILS'),
              const SizedBox(height: 15),
              _buildTextField(nameController, 'FULL NAME', Icons.person),
              _buildTextField(emailController, 'EMAIL ADDRESS', Icons.email, keyboardType: TextInputType.emailAddress),
              _buildTextField(phoneController, 'PHONE NUMBER', Icons.phone, keyboardType: TextInputType.phone),
              _buildTextField(passwordController, 'PASSWORD', Icons.lock, obscure: true),
              
              const SizedBox(height: 30),
              _buildSectionHeader('LOCATION'),
              const SizedBox(height: 15),
              _buildTextField(countryController, 'COUNTRY', Icons.public),
              _buildTextField(stateController, 'STATE', Icons.map),
              _buildTextField(cityController, 'CITY', Icons.location_city),
              _buildTextField(blockController, 'BLOCK / AREA', Icons.home_work),
              _buildTextField(pincodeController, 'PINCODE', Icons.pin_drop, keyboardType: TextInputType.number),

              if (selectedRole == UserRole.serviceProvider) ...[
                const SizedBox(height: 30),
                _buildSectionHeader('PROFESSIONAL PROFILE'),
                const SizedBox(height: 15),
                _buildDropdownField(),
                _buildTextField(experienceController, 'YEARS OF EXPERIENCE', Icons.history, keyboardType: TextInputType.number),
                Row(
                  children: [
                    Expanded(child: _buildTextField(minPriceController, 'MIN PRICE', Icons.currency_rupee, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(maxPriceController, 'MAX PRICE', Icons.trending_up, keyboardType: TextInputType.number)),
                  ],
                ),
              ],

              const SizedBox(height: 50),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      bool success = await authProvider.signUp(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                        fullName: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        role: selectedRole,
                        country: countryController.text.trim(),
                        state: stateController.text.trim(),
                        city: cityController.text.trim(),
                        block: blockController.text.trim(),
                        pincode: pincodeController.text.trim(),
                        category: selectedCategory,
                        yearsOfExperience: experienceController.text.trim(),
                        minPrice: int.tryParse(minPriceController.text.trim()),
                        maxPrice: int.tryParse(maxPriceController.text.trim()),
                      );
                      
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: Colors.green),
                        );
                        Navigator.pop(context); // Go back to login
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authProvider.errorMessage ?? 'Signup failed'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: authProvider.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5));
  }

  Widget _buildRoleOption(UserRole role, String label, IconData icon, Color primaryColor) {
    bool isSelected = selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? primaryColor : Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'CATEGORY',
          prefixIcon: const Icon(Icons.category, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        initialValue: selectedCategory,
        items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
        onChanged: (v) => setState(() => selectedCategory = v),
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }
}
