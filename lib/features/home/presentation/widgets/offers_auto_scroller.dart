import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/image_utils.dart';

class OffersAutoScroller extends StatefulWidget {
  final List<Map<String, dynamic>> offers;
  final bool isDark;
  final AppStrings s;
  final List<Map<String, dynamic>> allVendors;

  const OffersAutoScroller({
    required this.offers,
    required this.isDark,
    required this.s,
    required this.allVendors,
  });

  @override
  State<OffersAutoScroller> createState() => _OffersAutoScrollerState();
}

class _OffersAutoScrollerState extends State<OffersAutoScroller> {
  late PageController _controller;
  Timer? _timer;
  late int _page;

  @override
  void initState() {
    super.initState();
    _initPageAndController();
    _startTimer();
  }

  void _initPageAndController() {
    _page = widget.offers.length > 0 ? widget.offers.length * 100 : 0;
    _controller = PageController(viewportFraction: 0.85, initialPage: _page);
  }

  @override
  void didUpdateWidget(OffersAutoScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offers.length != widget.offers.length) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.offers.length <= 1) return;
    
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_controller.hasClients && _controller.page != null) {
        setState(() {
          _page = _controller.page!.round() + 1;
        });
        _controller.animateToPage(
          _page,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();
    
    return PageView.builder(
      controller: _controller,
      onPageChanged: (index) {
        setState(() => _page = index);
      },
      itemBuilder: (context, index) {
        final offer = widget.offers[index % widget.offers.length];
        return _buildOfferCard(context, offer);
      },
    );
  }

  Widget _buildOfferCard(BuildContext context, Map<String, dynamic> offer) {
    final isAr = widget.s.isArabic;

    final productName = (isAr && offer['productNameAr'] != null && offer['productNameAr'].toString().isNotEmpty)
        ? offer['productNameAr'].toString()
        : (offer['productName']?.toString() ?? (isAr ? offer['titleAr'] ?? offer['title'] : offer['title']) ?? '');

    final vendorName = (isAr && offer['vendorStoreNameAr'] != null && offer['vendorStoreNameAr'].toString().isNotEmpty)
        ? offer['vendorStoreNameAr'].toString()
        : (offer['vendorStoreName']?.toString() ?? '');

    final String? rawImageUrl = offer['productImageUrl']?.toString().isNotEmpty == true
        ? offer['productImageUrl'].toString()
        : offer['imageUrl']?.toString();
    final String imageUrl = rawImageUrl != null ? ImageUtils.formatImageUrl(rawImageUrl) : '';

    // Price resolution: use explicit offer/original if set, else use product prices
    final double? offerPrice = _toDouble(offer['offerPrice']) ?? _toDouble(offer['productBasePrice']);
    final double? originalPrice = _toDouble(offer['originalPrice']) ?? _toDouble(offer['productComparePrice']);

    final vendorId = offer['vendorId']?.toString();
    final vendorList = widget.allVendors.where((v) => v['id']?.toString() == vendorId).toList();
    final Map<String, dynamic>? vendorObj = vendorList.isNotEmpty ? vendorList.first : null;

    return GestureDetector(
      onTap: () {
        if (vendorId != null) {
          context.push('/vendor', extra: {
            'id': vendorId,
            'name': vendorName,
            'productId': offer['productId']?.toString(),
          });
        }
      },
      child: Container(
        margin: const EdgeInsetsDirectional.only(start: 16, end: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border.all(
            color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.4 : 0.1),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image — full top section
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  child: Stack(
                    children: [
                      // Image
                      if (imageUrl.isNotEmpty)
                        Center(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.image_not_supported_rounded, 
                              color: Colors.grey, 
                              size: 40
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 48),
                        ),
                      // OFFER badge
                      PositionedDirectional(
                        top: 10,
                        start: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade600, Colors.red.shade800],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, color: Colors.white, size: 10),
                              const SizedBox(width: 4),
                              Text(
                                widget.s.offerBadge.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom info section
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vendorName.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.storefront_rounded, color: AppColors.primary, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vendorName,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (vendorObj != null && vendorObj['rating'] != null) ...[
                            const SizedBox(width: 8),
                            Builder(builder: (context) {
                              double rating = double.tryParse(vendorObj['rating']?.toString() ?? '0') ?? 0.0;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (index) {
                                  if (index < rating.floor()) {
                                    return const Icon(Icons.star_rounded, color: Colors.amber, size: 14);
                                  } else if (index < rating) {
                                    return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 14);
                                  } else {
                                    return Icon(Icons.star_rounded, color: widget.isDark ? Colors.white12 : Colors.grey.shade300, size: 14);
                                  }
                                }),
                              );
                            }),
                          ],
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      productName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: widget.isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (offerPrice != null)
                                Text(
                                  '${offerPrice.toStringAsFixed(0)}${widget.s.egp}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              if (offerPrice != null && originalPrice != null && originalPrice > offerPrice) ...[
                                Text(
                                  '${originalPrice.toStringAsFixed(0)}${widget.s.egp}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDark ? Colors.white : Colors.black54,
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 2,
                                    decorationColor: Colors.red.withOpacity(0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                _buildDiscountBadge(offerPrice, originalPrice),
                              ],
                            ],
                          ),
                        ),
                        // Order Button
                        ElevatedButton(
                          onPressed: () {
                            if (vendorId != null) {
                              context.push('/vendor', extra: {
                                'id': vendorId,
                                'name': vendorName,
                                'productId': offer['productId']?.toString(),
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            minimumSize: const Size(60, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                          ),
                          child: Text(
                            widget.s.isArabic ? 'اطلب' : 'Order',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountBadge(double offer, double original) {
    final pct = (((original - offer) / original) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        '-$pct%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.red.shade600,
        ),
      ),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
