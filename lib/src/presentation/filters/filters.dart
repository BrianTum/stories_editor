import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/providers/notifiers/control_provider.dart';
import 'model.dart';

class Filters extends StatefulWidget {
  const Filters({Key? key}) : super(key: key);

  @override
  State<Filters> createState() => _FiltersState();
}

class _FiltersState extends State<Filters> {
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlNotifier>(
        builder: (context, controlNotifier, child) {
      return Row(
        children: [
          // Expanded(
          //   flex: 1,
          //   child: Center(
          //     child: ColorFiltered(
          //       child: Container(
          //         color: Colors.pink,
          //         child: Image.asset('assets/images/img.png'),
          //       ), // Replace with your own image widget
          //       colorFilter: ColorFilters.getColorFilter(
          //           FilterType.values[selectedIndex])!,
          //     ),
          //   ),
          // ),
          Expanded(
            flex: 4,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              itemCount: FilterType.values.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(
                  width: 16.0,
                ); // Adjust the width according to your desired spacing
              },
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedIndex == index
                          ? Colors.white
                          : Colors.transparent, // Set the border color here
                      width: 5.0, // Set the border thickness here
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                      Provider.of<ControlNotifier>(context, listen: false)
                          .filterIndex = index;
                    },
                    child: Stack(
                      children: [
                        ColorFiltered(
                          child: Image.asset(
                              'assets/images/img.png'), // Replace with your own image widget
                          colorFilter: ColorFilters.getColorFilter(
                              FilterType.values[index])!,
                        ),
                        selectedIndex == index
                            ? const Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Icon(
                                  Icons.check_sharp,
                                  size: 60,
                                  color: Colors.white,
                                ))
                            : const Center()
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
