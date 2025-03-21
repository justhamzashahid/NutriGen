import 'package:flutter/material.dart';
import 'package:nutrigen/models/nutritionist_model.dart';
import 'package:nutrigen/screens/nutritionist_detail_screen.dart';
import 'package:nutrigen/services/nutritionist_service.dart';

class NutritionistsScreen extends StatefulWidget {
  const NutritionistsScreen({Key? key}) : super(key: key);

  @override
  State<NutritionistsScreen> createState() => _NutritionistsScreenState();
}

class _NutritionistsScreenState extends State<NutritionistsScreen> {
  String _selectedCity = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Nutritionist> _nutritionists = [];
  List<Nutritionist> _filteredNutritionists = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNutritionists();
  }

  Future<void> _loadNutritionists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final nutritionists = await NutritionistService.getNutritionists();
      setState(() {
        _nutritionists = nutritionists;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading nutritionists: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Nutritionist> filteredList = List.from(_nutritionists);

    // Apply city filter
    if (_selectedCity != 'All') {
      filteredList =
          filteredList.where((n) => n.city == _selectedCity).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredList =
          filteredList
              .where(
                (n) =>
                    n.name.toLowerCase().contains(query) ||
                    n.qualification.toLowerCase().contains(query) ||
                    n.specialization.toLowerCase().contains(query),
              )
              .toList();
    }

    setState(() {
      _filteredNutritionists = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get unique cities from nutritionists
    final List<String> cities = ['All'];
    if (_nutritionists.isNotEmpty) {
      final uniqueCities =
          _nutritionists.map((n) => n.city).toSet().toList()..sort();
      cities.addAll(uniqueCities);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Find Nutritionists',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFCC1C14)),
              )
              : Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search nutritionists...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFilters();
                        });
                      },
                    ),
                  ),

                  // City filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children:
                          cities
                              .map(
                                (city) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(city),
                                    selected: _selectedCity == city,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCity = city;
                                        _applyFilters();
                                      });
                                    },
                                    backgroundColor: Colors.grey[100],
                                    selectedColor: const Color(0xFFCC1C14),
                                    labelStyle: TextStyle(
                                      color:
                                          _selectedCity == city
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight:
                                          _selectedCity == city
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nutritionists list
                  Expanded(
                    child:
                        _filteredNutritionists.isEmpty
                            ? Center(
                              child: Text(
                                'No nutritionists found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _filteredNutritionists.length,
                              itemBuilder: (context, index) {
                                final nutritionist =
                                    _filteredNutritionists[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                NutritionistDetailScreen(
                                                  nutritionist: nutritionist,
                                                ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          // Profile image
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: AssetImage(
                                                  nutritionist.imageUrl,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nutritionist.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .business_center_outlined,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      nutritionist.experience,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Arrow icon
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
