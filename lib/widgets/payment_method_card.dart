import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';

/// Reusable card widget for displaying payment methods
class PaymentMethodCard extends StatelessWidget {
  final PaymentMethodModel method;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF1B7C).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF1B7C)
                : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _getMethodColor(method.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                _getMethodIcon(method.type),
                color: _getMethodColor(method.type),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          method.displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (method.isDefault)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1B7C),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (method.lastUsed != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        'Last used: ${_formatDate(method.lastUsed!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          height: 1.1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Selection indicator
            if (isSelected) ...[
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF1B7C),
                size: 16,
              ),
              const SizedBox(width: 3),
            ],
            // Edit button
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 15, color: Colors.grey),
                onPressed: onEdit,
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 26,
                  minHeight: 26,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(String type) {
    switch (type) {
      case 'UPI':
        return Icons.account_balance;
      case 'BANK':
        return Icons.account_balance_outlined;
      case 'CRYPTO':
        return Icons.currency_bitcoin;
      default:
        return Icons.payment;
    }
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
