class Nutritionist {
  final String id;
  final String name;
  final String imageUrl;
  final String qualification;
  final String specialization;
  final String experience;
  final String city;
  final String hospitalClinic;
  final String about;
  final double rating;
  final int totalReviews;
  final String email;
  final String phone;
  final double consultationFee;
  final List<String> availableDays;
  final Map<String, List<String>> availableTimeSlots;
  final List<String> languages;
  final List<Map<String, String>> reviews;

  Nutritionist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.qualification,
    required this.specialization,
    required this.experience,
    required this.city,
    required this.hospitalClinic,
    required this.about,
    required this.rating,
    required this.totalReviews,
    required this.email,
    required this.phone,
    required this.consultationFee,
    required this.availableDays,
    required this.availableTimeSlots,
    required this.languages,
    required this.reviews,
  });

  // This will be useful when we implement the web scraper
  factory Nutritionist.fromMap(Map<String, dynamic> map) {
    return Nutritionist(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      qualification: map['qualification'] ?? '',
      specialization: map['specialization'] ?? '',
      experience: map['experience'] ?? '',
      city: map['city'] ?? '',
      hospitalClinic: map['hospitalClinic'] ?? '',
      about: map['about'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      consultationFee: (map['consultationFee'] ?? 0.0).toDouble(),
      availableDays: List<String>.from(map['availableDays'] ?? []),
      availableTimeSlots: Map<String, List<String>>.from(
        (map['availableTimeSlots'] ?? {}).map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      languages: List<String>.from(map['languages'] ?? []),
      reviews: List<Map<String, String>>.from(map['reviews'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'qualification': qualification,
      'specialization': specialization,
      'experience': experience,
      'city': city,
      'hospitalClinic': hospitalClinic,
      'about': about,
      'rating': rating,
      'totalReviews': totalReviews,
      'email': email,
      'phone': phone,
      'consultationFee': consultationFee,
      'availableDays': availableDays,
      'availableTimeSlots': availableTimeSlots,
      'languages': languages,
      'reviews': reviews,
    };
  }
}
