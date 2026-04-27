import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BannerWidget extends StatelessWidget {
  const BannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Precache the banner image
    precacheImage(const AssetImage('assets/images/banner.png'), context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          // Banner Background
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Image.asset(
              'assets/images/banner.png',
              fit: BoxFit.cover,
            ),
          ),

          // Lottie Animation at bottom-right
          Positioned(
            right: 8,
            bottom: 8,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Lottie.asset(
                'assets/lottie/loading.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
