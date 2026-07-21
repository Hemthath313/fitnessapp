import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fitness_app/utils/ad_config.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:provider/provider.dart';

class BannerAdService {
  static String getAdUnitIdForPage(String pageName) {
    return AdConfig.getBannerAdUnitIdForPage(pageName);
  }
}

class BannerAdWidget extends StatefulWidget {
  final String? pageName; // Optional page name to use specific ad unit
  final double bottomMargin;

  const BannerAdWidget({
    super.key,
    this.pageName,
    this.bottomMargin = 0.0,
  });

  @override
  _BannerAdWidgetState createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  AdSize? _adSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    if (!mounted) return;

    try {
      final adUnitId =
          BannerAdService.getAdUnitIdForPage(widget.pageName ?? 'home');

      double screenWidth = MediaQuery.of(context).size.width;

      if (screenWidth <= 0) {
        // Fallback to standard banner if width not available
        _createBannerAd(adUnitId, AdSize.banner);
        return;
      }

      final AnchoredAdaptiveBannerAdSize? size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
              screenWidth.truncate());

      _createBannerAd(adUnitId, size ?? AdSize.banner);
    } catch (e) {
      print('Error in _loadAd: $e');
      final adUnitId = BannerAdService.getAdUnitIdForPage(widget.pageName ?? 'home');
      _createBannerAd(adUnitId, AdSize.banner);
    }
  }

  void _createBannerAd(String adUnitId, AdSize size) {
    if (!mounted) return;
    
    setState(() {
      _adSize = size;
    });

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final double displayHeight = _adSize?.height.toDouble() ?? 50.0;

    Widget adWidget = SizedBox(
      width: double.infinity,
      height: displayHeight,
      child: AdWidget(ad: _bannerAd!),
    );

    if (widget.bottomMargin > 0.0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          adWidget,
          SizedBox(height: widget.bottomMargin),
        ],
      );
    }

    return adWidget;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}

class PremiumAwareBannerAd extends StatelessWidget {
  final String? pageName;
  final double bottomMargin;

  const PremiumAwareBannerAd({
    super.key,
    this.pageName,
    this.bottomMargin = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        if (subProvider.isPremium) return const SizedBox.shrink();
        
        return BannerAdWidget(
          pageName: pageName,
          bottomMargin: bottomMargin,
        );
      },
    );
  }
}
