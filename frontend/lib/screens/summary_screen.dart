import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  final int duration;
  const SummaryScreen({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF0F0F1E), const Color(0xFF1E1E2E)]
              : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 100, color: Color(0xFF6A11CB)),
            const SizedBox(height: 30),
            const Text(
              'انتهت النبضة',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'استغرقت مكالمتك $duration ثانية',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            const Text(
              'كيف كانت ثقتك بنفسك اليوم؟',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEmojiButton('😊', 'عالية'),
                _buildEmojiButton('😐', 'متوسطة'),
                _buildEmojiButton('😔', 'تحتاج تطوير'),
              ],
            ),
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  Text(
                    '💡 نصيحة لتعزيز الثقة',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A11CB)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'التحدث مع الغرباء يكسر حاجز الخوف الاجتماعي. أنت قمت بعمل رائع اليوم!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A11CB),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('العودة للرئيسية', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
