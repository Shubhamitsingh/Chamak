import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_method_model.dart';
import '../services/payment_method_service.dart';

/// Screen for adding/editing payment methods
class AddPaymentMethodScreen extends StatefulWidget {
  final PaymentMethodModel? existingMethod; // If editing
  final String? initialType; // Pre-select type if provided

  const AddPaymentMethodScreen({
    super.key,
    this.existingMethod,
    this.initialType,
  });

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _cryptoAddressController = TextEditingController();
  
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _selectedType;
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? widget.existingMethod?.type;
    
    // Pre-fill if editing
    if (widget.existingMethod != null) {
      final details = widget.existingMethod!.details;
      _isDefault = widget.existingMethod!.isDefault;
      
      if (widget.existingMethod!.type == 'UPI') {
        _upiController.text = details['upiId'] as String? ?? '';
      } else if (widget.existingMethod!.type == 'BANK') {
        _accountHolderController.text = details['accountHolderName'] as String? ?? '';
        _accountNumberController.text = details['accountNumber'] as String? ?? '';
        _ifscController.text = details['ifscCode'] as String? ?? '';
      } else if (widget.existingMethod!.type == 'CRYPTO') {
        _cryptoAddressController.text = details['walletAddress'] as String? ?? '';
      }
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _cryptoAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF1B7C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingMethod != null
              ? 'Edit Payment Method'
              : 'Add Payment Method',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Type Selection (if not editing)
              if (widget.existingMethod == null) ...[
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentTypeOption('UPI', Icons.account_balance, 'Fast & Secure'),
                const SizedBox(height: 8),
                _buildPaymentTypeOption('BANK', Icons.account_balance_outlined, 'Direct to Bank Account'),
                const SizedBox(height: 8),
                _buildPaymentTypeOption('CRYPTO', Icons.currency_bitcoin, 'Cryptocurrency'),
                const SizedBox(height: 20),
              ],

              // Form Fields based on selected type
              if (_selectedType != null) ...[
                if (_selectedType == 'UPI') ..._buildUPIFields(),
                if (_selectedType == 'BANK') ..._buildBankFields(),
                if (_selectedType == 'CRYPTO') ..._buildCryptoFields(),

                const SizedBox(height: 16),

                // Set as Default checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFFFF1B7C),
                    ),
                    const Text(
                      'Set as default payment method',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1B7C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Payment Method',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeOption(String type, IconData icon, String subtitle) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF1B7C).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF1B7C)
                : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getMethodColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 20, color: _getMethodColor(type)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type == 'UPI' ? 'UPI' : type == 'BANK' ? 'Bank Transfer' : 'Crypto Wallet',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF1B7C),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUPIFields() {
    return [
      const Text(
        'UPI ID',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _upiController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Enter UPI ID (e.g., user@paytm)',
          prefixIcon: const Icon(Icons.account_balance),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter UPI ID';
          }
          if (!value.contains('@')) {
            return 'Please enter a valid UPI ID';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildBankFields() {
    return [
      // Account Holder Name
      const Text(
        'Account Holder Name',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _accountHolderController,
        decoration: InputDecoration(
          hintText: 'Enter account holder name',
          prefixIcon: const Icon(Icons.person_outline),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter account holder name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      // Account Number
      const Text(
        'Account Number',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _accountNumberController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Enter account number',
          prefixIcon: const Icon(Icons.credit_card),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter account number';
          }
          if (value.length < 9 || value.length > 18) {
            return 'Account number must be 9-18 digits';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      // IFSC Code
      const Text(
        'IFSC Code',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _ifscController,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: 'Enter IFSC code',
          prefixIcon: const Icon(Icons.business),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter IFSC code';
          }
          if (value.length != 11) {
            return 'IFSC code must be 11 characters';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildCryptoFields() {
    return [
      const Text(
        'Wallet Address',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _cryptoAddressController,
        decoration: InputDecoration(
          hintText: 'Enter wallet address',
          prefixIcon: const Icon(Icons.currency_bitcoin),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF1B7C), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter wallet address';
          }
          if (value.length < 26) {
            return 'Wallet address must be at least 26 characters';
          }
          return null;
        },
      ),
    ];
  }

  Color _getMethodColor(String type) {
    switch (type) {
      case 'UPI':
        return Colors.blue;
      case 'BANK':
        return Colors.green;
      case 'CRYPTO':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      Map<String, dynamic> details = {};
      String displayName = '';

      if (_selectedType == 'UPI') {
        final upiId = _upiController.text.trim();
        details = {'upiId': upiId};
        displayName = 'UPI: $upiId';
      } else if (_selectedType == 'BANK') {
        final accountNumber = _accountNumberController.text.trim();
        final last4 = accountNumber.length >= 4
            ? accountNumber.substring(accountNumber.length - 4)
            : accountNumber;
        details = {
          'accountHolderName': _accountHolderController.text.trim(),
          'accountNumber': accountNumber,
          'ifscCode': _ifscController.text.trim(),
        };
        displayName = 'Bank: ****$last4';
      } else if (_selectedType == 'CRYPTO') {
        final address = _cryptoAddressController.text.trim();
        final shortAddress = address.length >= 8
            ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
            : address;
        details = {'walletAddress': address};
        displayName = 'Crypto: $shortAddress';
      }

      if (widget.existingMethod != null) {
        // Update existing
        final success = await _paymentMethodService.updatePaymentMethod(
          userId: currentUser.uid,
          methodId: widget.existingMethod!.id,
          displayName: displayName,
          details: details,
          setAsDefault: _isDefault,
        );

        if (success && mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          throw Exception('Failed to update payment method');
        }
      } else {
        // Save new
        final methodId = await _paymentMethodService.savePaymentMethod(
          userId: currentUser.uid,
          type: _selectedType!,
          displayName: displayName,
          details: details,
          setAsDefault: _isDefault,
        );

        if (methodId != null && mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          throw Exception('Failed to save payment method');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
