import 'package:flutter/material.dart';

class MealImagePicker extends StatefulWidget {
  const MealImagePicker({super.key});

  @override
  State<MealImagePicker> createState() {
    return _MealImagePickerState();
  }
}

class _MealImagePickerState extends State<MealImagePicker> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: Text("MealImagePicker Widget"),
      ),
    );
  }
}
