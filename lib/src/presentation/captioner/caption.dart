import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/services.dart';

import '../../domain/providers/notifiers/control_provider.dart';

class Captioner extends StatefulWidget {
  const Captioner({super.key, required this.controlNotifier});

  final ControlNotifier controlNotifier;

  @override
  State<Captioner> createState() => _CaptionerState();
}

class _CaptionerState extends State<Captioner> {
  late TextEditingController _textEditingController;

  final List<TextInputFormatter> _inputFormatters = [
    FilteringTextInputFormatter.deny(RegExp(r"\n")), // Deny newlines
  ];

  @override
  void initState() {
    _textEditingController = widget.controlNotifier.textEditingController;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.controlNotifier.isTextEdit = true;
        });
      },
      child: Container(
        color: Colors.white54,
        width: 330,
        child: widget.controlNotifier.isTextEdit == true
            ? AutoSizeTextField(
                controller: _textEditingController,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.start,
                minFontSize: 14,
                maxLines: 2,
                maxLength: 100,
                stepGranularity: 7,
                enabled: widget.controlNotifier.isTextEdit,
                inputFormatters: _inputFormatters,
                onChanged: (value) {
                  widget.controlNotifier.textCaption = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Caption here',
                  hintStyle: TextStyle(fontSize: 20),
                ),
                onEditingComplete: () {
                  setState(() {
                    widget.controlNotifier.isTextEdit = false;
                  });
                },
              )
            : AutoSizeText(
                _textEditingController.text,
                style: const TextStyle(fontSize: 30),
                minFontSize: 20,
                stepGranularity: 10,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
