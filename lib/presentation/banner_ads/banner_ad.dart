import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BannerAdWidget extends StatefulWidget {
  @override
  _BannerAdWidgetState createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5975958510203735/2418977875', // Test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('Banner ad loaded successfully');
          setState(() {
            _isAdLoaded = true;
            _errorMessage = null;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load a banner ad: $error');
          setState(() {
            _errorMessage = error.message;
          });
          ad.dispose();
        },
        onAdOpened: (_) => print('Banner ad opened'),
        onAdClosed: (_) => print('Banner ad closed'),
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded) {
      return Container(
        alignment: Alignment.center,
        height: _bannerAd.size.height.toDouble(),
        width: _bannerAd.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd),
      );
    } else if (_errorMessage != null) {
      // Show error message for debugging
      return Container(
        height: 50,
        color: Colors.red.withValues(alpha: 0.1),
        child: Center(
          child: Text(
            'Ad Error: $_errorMessage',
            style: TextStyle(color: Colors.red, fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // Show loading indicator
      return Container(
        height: 50,
        color: Colors.grey.withValues(alpha: 0.1),
        child: Center(
          child: Text(
            'Loading Ad...',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }
}
