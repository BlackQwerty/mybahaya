import 'package:flutter/material.dart';

void showCustomModal(BuildContext context, Widget child) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => child,
  );
}