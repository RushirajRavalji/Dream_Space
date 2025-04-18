import 'package:flutter/material.dart';
import 'package:new_furniture_app_fixed/utils/app_theme.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  int selectedCategory = 0;
  int selectedColor = 0;
  Color defaultColor = Colors.blue;
  double currentRangeFrst = 150;
  double currentRangeLast = 800;

  List<String> categories = [
    "All",
    "Chair",
    "Table",
    "Lamp",
    "Floor",
    "Decoration",
    "Furniture",
    "Armchair",
    "Desk",
    "Dresser",
    "Bedside table",
    "Bookshelf",
    "Carpet",
  ];

  List<Color> colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.deepOrange,
  ];

  // Apply filters and navigate to results
  void _applyFilters() {
    // Here you would typically filter products based on selections
    // and pass the filtered results to the next screen

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filters applied successfully'),
        backgroundColor: AppTheme.primaryColor,
        duration: Duration(seconds: 1),
      ),
    );

    // Navigate back (in a real app, would go to filtered results)
    Navigator.pop(context);
  }

  // Reset all filters to default values
  void _resetFilters() {
    setState(() {
      selectedCategory = 0;
      selectedColor = 0;
      selectedBrand = -1;
      currentRangeFrst = 150;
      currentRangeLast = 800;
      defaultColor = Colors.blue;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filters reset'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppTheme.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Filters", style: AppTheme.headingSmall),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              "Reset",
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: _applyFilters,
            child: Text(
              "Apply",
              style: AppTheme.labelLarge.copyWith(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildSectionHeader("Brand"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing_m,
                vertical: AppTheme.spacing_s,
              ),
              color: AppTheme.surfaceColor,
              child: _buildBrandTiles(),
            ),
            _buildSectionHeader("Categories"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing_m,
                vertical: AppTheme.spacing_s,
              ),
              color: AppTheme.surfaceColor,
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children:
                    List<Widget>.generate(categories.length, (int index) {
                      return GestureDetector(
                        child: Chip(
                          backgroundColor:
                              selectedCategory == index
                                  ? AppTheme.primaryColor
                                  : AppTheme.accentColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius_l,
                            ),
                          ),
                          label: Text(
                            categories.elementAt(index),
                            style: AppTheme.bodySmall.copyWith(
                              color:
                                  selectedCategory == index
                                      ? Colors.white
                                      : AppTheme.textSecondaryColor,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing_m,
                            vertical: AppTheme.spacing_xs,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedCategory = index;
                          });

                          // Show selection feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Selected category: ${categories[index]}',
                              ),
                              duration: Duration(milliseconds: 500),
                            ),
                          );
                        },
                      );
                    }).toList(),
              ),
            ),
            _buildSectionHeader("Colors"),
            Container(
              width: double.infinity,
              height: 80,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing_m,
              ),
              color: AppTheme.surfaceColor,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacing_m),
                    child: GestureDetector(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                selectedColor == index
                                    ? colors.elementAt(index)
                                    : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow:
                              selectedColor == index
                                  ? [
                                    BoxShadow(
                                      color: colors
                                          .elementAt(index)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.elementAt(index),
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedColor = index;
                          defaultColor = colors.elementAt(index);
                        });

                        // Show color selection feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Color selected'),
                            backgroundColor: colors.elementAt(index),
                            duration: Duration(milliseconds: 500),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            _buildSectionHeader("Price Range"),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing_m,
                vertical: AppTheme.spacing_m,
              ),
              color: AppTheme.surfaceColor,
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.dividerColor,
                      thumbColor: AppTheme.primaryColor,
                      valueIndicatorColor: AppTheme.primaryColor,
                      trackHeight: 4,
                    ),
                    child: Column(
                      children: <Widget>[
                        RangeSlider(
                          min: 0,
                          max: 1000,
                          divisions: 20,
                          values: RangeValues(
                            currentRangeFrst,
                            currentRangeLast,
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              currentRangeFrst = values.start;
                              currentRangeLast = values.end;
                            });
                          },
                          labels: RangeLabels(
                            "Rs${currentRangeFrst.toInt()}",
                            "Rs${currentRangeLast.toInt()}",
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Rs 0",
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textLightColor,
                              ),
                            ),
                            Text(
                              "Selected: Rs${currentRangeFrst.toInt()} - Rs${currentRangeLast.toInt()}",
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Rs 1000",
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textLightColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing_l),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text("Apply Filters"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing_m,
        vertical: AppTheme.spacing_m,
      ),
      color: AppTheme.backgroundColor,
      child: Text(title, style: AppTheme.labelLarge),
    );
  }

  int selectedBrand = -1;
  List<String> brands = [
    "IKEA",
    "Herman Miller",
    "Ashley",
    "Kartell",
    "Vitra",
    "La-Z-Boy",
  ];

  Widget _buildBrandTiles() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: List<Widget>.generate(brands.length, (int index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedBrand = selectedBrand == index ? -1 : index;
            });

            if (selectedBrand == index) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Brand selected: ${brands[index]}'),
                  duration: Duration(milliseconds: 500),
                ),
              );
            }
          },
          child: Chip(
            backgroundColor:
                selectedBrand == index
                    ? AppTheme.primaryColor
                    : AppTheme.accentColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius_l),
            ),
            label: Text(
              brands[index],
              style: AppTheme.bodySmall.copyWith(
                color:
                    selectedBrand == index
                        ? Colors.white
                        : AppTheme.textSecondaryColor,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing_m,
              vertical: AppTheme.spacing_xs,
            ),
          ),
        );
      }),
    );
  }
}
