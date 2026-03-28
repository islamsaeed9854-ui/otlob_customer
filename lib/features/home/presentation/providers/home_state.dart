class HomeData {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic>? activeOrder;

  HomeData({
    required this.categories,
    required this.products,
    this.activeOrder,
  });
}
