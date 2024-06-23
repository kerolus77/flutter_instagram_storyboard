import 'package:flutter/material.dart';

class InterActiveWidget extends StatefulWidget {
  bool color;
  final FocusNode focusNode;
  // final TextEditingController controller;

  InterActiveWidget({
    Key? key,
    required this.color,
    required this.focusNode,
    // required this.controller,
  }) : super(key: key);

  @override
  State<InterActiveWidget> createState() => _InterActiveWidgetState();
}

class _InterActiveWidgetState extends State<InterActiveWidget> {
 
  @override
  Widget build(BuildContext context) {
     TextEditingController controller = TextEditingController();
    return Container(
      height: 60,
      color: Colors.black,
      child: Row(
        children: [
          SizedBox(
            width: 400,
            child: TextFormField(
              focusNode: widget.focusNode,
              controller: controller,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                hintText: "Write a Reply",
                hintStyle: const TextStyle(fontSize: 16, color: Colors.white),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                fillColor: Colors.grey,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                widget.color = !widget.color;
                // print(controller.text);
              });
            },
            icon: Icon(Icons.heart_broken),
            color: widget.color ? Colors.red : Colors.black,
          ),
        ],
      ),
    );
  }

}
