import 'package:flutter/material.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> arguments;

  const OrderSuccessScreen({
    super.key,
    required this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    final orderNo = arguments['orderNo']?.toString() ?? '';
    final amount = arguments['amount'] as int? ?? 0;
    final formattedAmt = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFFFF9100),
                size: 96,
              ),
              const SizedBox(height: 24),
              const Text(
                '주문이 완료되었습니다!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '결제가 안전하게 완료되었습니다.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Breakdown Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('주문 번호', orderNo),
                    const Divider(color: Colors.white12, height: 24),
                    _buildDetailRow('결제 금액', '$formattedAmt 원', isValueHighlighted: true),
                  ],
                ),
              ),

              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9100),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                },
                child: const Text(
                  '홈으로',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isValueHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: isValueHighlighted ? const Color(0xFFFF9100) : Colors.white,
            fontSize: isValueHighlighted ? 18 : 14,
            fontWeight: isValueHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
