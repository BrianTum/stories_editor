import 'dart:io';

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
  late int selectedIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    selectedIndex =
        Provider.of<ControlNotifier>(context, listen: false).filterIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedIndex();
    });

    super.initState();
  }

  void _scrollToSelectedIndex() {
    _scrollController.animateTo(
      selectedIndex * 100.0, // Replace with your desired item extent
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlNotifier>(
        builder: (context, controlNotifier, child) {
      return SizedBox(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          itemCount: FilterType.values.length,
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(
              width: 10.0,
            ); // Adjust the width according to your desired spacing
          },
          itemBuilder: (BuildContext context, int index) {
            return Center(
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
                      child: controlNotifier.mediaPath != ''
                          ? Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedIndex == index
                                      ? Colors.white
                                      : Colors
                                          .transparent, // Set the border color here
                                  width: 5.0, // Set the border thickness here
                                ),
                              ),
                              child: Image.file(
                                File(controlNotifier.mediaPath),
                                filterQuality: FilterQuality.high,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedIndex == index
                                      ? Colors.white
                                      : Colors
                                          .transparent, // Set the border color here
                                  width: 5.0, // Set the border thickness here
                                ),
                              ),
                              child: Image.asset('assets/images/img.png'),
                            ), // Replace with your own image widget
                      colorFilter: CustomColorFilters.getFilter(
                          FilterType.values[index]),
                    ),
                    selectedIndex == index
                        ? const Positioned(
                            bottom: 0,
                            right: 0,
                            top: 0,
                            left: 0,
                            child: Icon(
                              Icons.check_sharp,
                              size: 40,
                              color: Colors.white,
                            ),
                          )
                        : const Center()
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
