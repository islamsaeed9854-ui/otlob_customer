class HomeData {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> promotions;
  final Map<String, dynamic>? activeOrder;

  HomeData({
    required this.categories,
    required this.products,
    required this.promotions,
    this.activeOrder,
  });
}
