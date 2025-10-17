import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdService {
  // Different banner ad units for different pages
  static const String _homeAdUnitId =
      'ca-app-pub-5975958510203735/2418977875'; // Home page
  static const String _exploreAdUnitId =
      'ca-app-pub-5975958510203735/1219614958'; // Explore page
  static const String _chatAdUnitId =
      'ca-app-pub-5975958510203735/3515923426'; // Chat page
  static const String _settingsAdUnitId =
      'ca-app-pub-5975958510203735/3515923426'; // Settings page
  static const String _profileAdUnitId =
      'ca-app-pub-5975958510203735/2418977875'; // Profile page

  static String getAdUnitIdForPage(String pageName) {
    switch (pageName.toLowerCase()) {
      case 'home':
        return _homeAdUnitId;
      case 'explore':
        return _exploreAdUnitId;
      case 'chat':
        return _chatAdUnitId;
      case 'settings':
        return _settingsAdUnitId;
      case 'profile':
        return _profileAdUnitId;
      default:
        return _homeAdUnitId; // Default to home page ad unit
    }
  }
}

class BannerAdWidget extends StatefulWidget {
  final String? pageName; // Optional page name to use specific ad unit

  const BannerAdWidget({super.key, this.pageName});

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
    final adUnitId =
        BannerAdService.getAdUnitIdForPage(widget.pageName ?? 'home');

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print(
              'Banner ad loaded successfully for ${widget.pageName ?? 'home'}');
          setState(() {
            _isAdLoaded = true;
            _errorMessage = null;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print(
              'Failed to load banner ad for ${widget.pageName ?? 'home'}: $error');
          setState(() {
            _errorMessage = error.message;
          });
          ad.dispose();
        },
        onAdOpened: (_) =>
            print('Banner ad opened for ${widget.pageName ?? 'home'}'),
        onAdClosed: (_) =>
            print('Banner ad closed for ${widget.pageName ?? 'home'}'),
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
        color: Colors.red.withOpacity(0.1),
        child: Center(
          child: Text(
            'Ad Error: $_errorMessage',
            style: TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // Show loading indicator
      return Container(
        height: 50,
        color: Colors.grey.withOpacity(0.1),
        child: Center(
          child: Text(
            'Loading Ad...',
            style: TextStyle(color: Colors.grey, fontSize: 12),
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
