import 'package:flutter/material.dart';

class InterActiveWidget extends StatefulWidget {
   bool color;
   InterActiveWidget({super.key,required this.color});

  @override
  State<InterActiveWidget> createState() => _InterActiveWidgetState();
}

class _InterActiveWidgetState extends State<InterActiveWidget> {
  @override
  Widget build(BuildContext context) {
    return  Container(
                                                   height: 60,
                                                  //  color: Colors.black,
                                                   child: Row(
                                                     children: [
                                                      //  16.width,
                                                      //  StatefulBuilder(
                                                      //    builder: (context, setState) => LikeButton(
                                                      //      isLike: isLike,
                                                      //      width: 40.,
                                                      //      height: 40.,
                                                      //      onPressed: () {
                                                      //       //  setState(() {
                                                      //       //    isLike = !isLike;
                                                      //       //    context.read<HomeCubit>().likeStory( widget.stories[widget.storyIndex].id.toString()).then((value) => setState((){
                                                      //       //      print(widget.stories[widget.storyIndex].view?.liked);
                                                      //       //     isLike=widget.stories[widget.storyIndex].view?.liked??false;
                                                      //       //    }));
                                                      //       //  });
                                                      //      },
                                                      //    ),
                                                      //  ),
                                                       SizedBox(
                                                         width:400,
                                                         child: TextFormField(
                                                           style: const TextStyle(fontSize: 16, color: Colors.white),
                                                           decoration: InputDecoration(
                                                               hintText: "Write a Reply",
                                                               hintStyle:
                                                                   const TextStyle(fontSize: 16, color: Colors.white),
                                                               isDense: true,
                                                               contentPadding: EdgeInsets.symmetric(
                                                                   horizontal: 10, vertical: 10),
                                                               fillColor: Colors.grey,
                                                               filled: true,
                                                               border: OutlineInputBorder(
                                                                   borderRadius: BorderRadius.circular(20),
                                                                   borderSide: BorderSide.none)),
                                                         )
                                                       ),
                                                       IconButton( onPressed: () {
                                                             setState(() {
                                                               widget.color = !widget.color;
                                                               
                                                               });
                                                             }, icon: Icon(Icons.heart_broken),color:widget.color?Colors.red:Colors.black ,)
                                                     ],
                                                   ),
                                                 );
  }
}