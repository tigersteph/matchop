class Restaurant {
  final String name;
  final String imageUrl;
  final String cuisine;
  final double rating;
  final String address;
  final String description;

  const Restaurant({
    required this.name,
    required this.imageUrl,
    required this.cuisine,
    required this.rating,
    required this.address,
    required this.description,
  });

  static List<Restaurant> sampleData = [
    Restaurant(
      name: 'Le Petit Bistro',
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      cuisine: 'French',
      rating: 4.5,
      address: '123 Gourmet Street',
      description: 'Authentic French cuisine in a cozy atmosphere',
    ),
    Restaurant(
      name: 'Sushi Master',
      imageUrl: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c',
      cuisine: 'Japanese',
      rating: 4.8,
      address: '456 Seafood Avenue',
      description: 'Fresh sushi and Japanese delicacies',
    ),
    Restaurant(
      name: 'Pasta Paradise',
      imageUrl: 'https://images.unsplash.com/photo-1481931098730-318b6f776db0',
      cuisine: 'Italian',
      rating: 4.3,
      address: '789 Pasta Lane',
      description: 'Homemade pasta and authentic Italian recipes',
    ),
  ];
}
