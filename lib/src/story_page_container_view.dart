 import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_instagram_storyboard/flutter_instagram_storyboard.dart';
import 'package:flutter_instagram_storyboard/src/first_build_mixin.dart';

import 'textfield_finder.dart';


class StoryPageContainerView extends StatefulWidget {
  final StoryButtonData buttonData;
  final VoidCallback onStoryComplete;
  final PageController? pageController;
  final VoidCallback? onClosePressed;

  const StoryPageContainerView({
    Key? key,
    required this.buttonData,
    required this.onStoryComplete,
    this.pageController,
    this.onClosePressed,
  }) : super(key: key);

  @override
  State<StoryPageContainerView> createState() => _StoryPageContainerViewState();
}

class _StoryPageContainerViewState extends State<StoryPageContainerView>
    with FirstBuildMixin {
  late StoryTimelineController _storyController;
  final Stopwatch _stopwatch = Stopwatch();
  Offset _pointerDownPosition = Offset.zero;
  int _pointerDownMillis = 0;
  double _pageValue = 0.0;
  bool _isInteracting = false; // Track if user is interacting
  FocusNode _focusNode = FocusNode(); 
  
  

  @override
  void initState() {
    _storyController =
        widget.buttonData.storyController ?? StoryTimelineController();
    _stopwatch.start();
    _storyController.addListener(_onTimelineEvent);
   
    super.initState();
  }

  @override
  void didFirstBuildFinish(BuildContext context) {
    widget.pageController?.addListener(_onPageControllerUpdate);
  }

  void _onPageControllerUpdate() {
    if (widget.pageController?.hasClients != true) {
      return;
    }
    _pageValue = widget.pageController?.page ?? 0.0;
    _storyController._setTimelineAvailable(_timelineAvailable);
  }

  bool get _timelineAvailable {
    return _pageValue % 1.0 == 0.0;
  }

  void _onTimelineEvent(StoryTimelineEvent event) {
    if (event == StoryTimelineEvent.storyComplete) {
      widget.onStoryComplete.call();
    }
    setState(() {});
  }

  Widget _buildCloseButton() {
    Widget closeButton;
    if (widget.buttonData.closeButton != null) {
      closeButton = widget.buttonData.closeButton!;
    } else {
      closeButton = SizedBox(
        height: 40.0,
        width: 40.0,
        child: MaterialButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (widget.onClosePressed != null) {
              widget.onClosePressed!.call();
            } else {
              Navigator.of(context).pop();
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              40.0,
            ),
          ),
          child: SizedBox(
            height: 40.0,
            width: 40.0,
            child: Icon(
              Icons.close,
              size: 28.0,
              color: widget.buttonData.defaultCloseButtonColor,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(
         right: 15.0,
        top: 10.0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          
          closeButton,
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Padding(
      padding: EdgeInsets.only(
        top: widget.buttonData.timlinePadding?.top ?? 15.0,
        left: widget.buttonData.timlinePadding?.left ?? 15.0,
        right: widget.buttonData.timlinePadding?.left ?? 15.0,
        bottom: widget.buttonData.timlinePadding?.bottom ?? 5.0,
      ),
      child: StoryTimeline(
        controller: _storyController,
        buttonData: widget.buttonData,
      ),
    );
  }

  int get _curSegmentIndex {
    return widget.buttonData.currentSegmentIndex;
  }

 Widget _buildPageContent() {
  if (widget.buttonData.storyPages.isEmpty) {
    return Container(
      color: Colors.orange,
      child: const Center(
        child: Text('No pages'),
      ),
    );
  }
  // Wrapping interactive widgets with GestureDetector to stop event propagation
  return GestureDetector(
    onTap: () {

      _focusNode.unfocus();
    },
    child: widget.buttonData.storyPages[_curSegmentIndex],
  );
}

  bool _isLeftPartOfStory(Offset position) {
    if (!mounted) {
      return false;
    }
    final storyWidth = context.size!.width;
    return position.dx <= (storyWidth * .499);
  }




  Widget _buildInteractiveWidget() {
    final interactiveWidget = widget.buttonData.interactiveWidgets?[_curSegmentIndex];
    if (interactiveWidget != null) {
      return Focus(
      focusNode:_focusNode,
      onFocusChange: (bool hasFocus) {
        setState(() {
          _isInteracting = hasFocus;
          if (hasFocus) {
            _storyController.pause();
          } else {
            _storyController.unpause();
          }
        });
      },
      child: TextFieldFinder(
        child: interactiveWidget,
        focusNode: _focusNode,
      )
    
  );
    }
    return SizedBox.shrink();
  }

  // Widget _buildTextField() {
  //   return Positioned(
  //     bottom: 10,
  //     left: 10,
  //     right: 10,
  //     child: TextField(
  //       focusNode: _textFieldFocusNodes[_curSegmentIndex],
  //       controller: _textControllers[_curSegmentIndex],
  //       decoration: InputDecoration(
  //         hintText: 'Type something...',
  //         border: OutlineInputBorder(),
  //       ),
  //     ),
  //   );
  // }
bool isKeyboardOpen() {
  
  return WidgetsBinding.instance.window.viewInsets.bottom > 0.0;
}


  Widget _buildPageStructure() {
  return Stack(
    children: [
      GestureDetector(
  onVerticalDragEnd: (details) {
    final primaryVelocity = details.primaryVelocity ?? 0;
    if (primaryVelocity < 0) {
      // Swiped up
      widget.buttonData.focusNode?.requestFocus();
      _storyController.pause();
      
      // Check if keyboard is open and close it
      if (isKeyboardOpen()) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    } else if (primaryVelocity > 0) {
      // Swiped down
      if (isKeyboardOpen()) {
        FocusManager.instance.primaryFocus?.unfocus();
        
      }else{
         // Close the story
      widget.onClosePressed?.call();
      }
      
     
    }
  },
        onTap: () {

          widget.buttonData.focusNode!.unfocus();
          _focusNode.unfocus();
          _storyController.unpause();
        },
        onLongPressStart: (details) {
          _storyController.pause();
        },
        onLongPressEnd: (details) {
          _storyController.unpause();
        },
        child: Listener(
          onPointerDown: (PointerDownEvent event) {
            _pointerDownMillis = _stopwatch.elapsedMilliseconds;
            _pointerDownPosition = event.position;
            if (_isInteracting) {
              _storyController.unpause();
              _isInteracting = false;

              widget.buttonData.focusNode?.unfocus();
              _focusNode.unfocus();
            }
          },
          onPointerUp: (PointerUpEvent event) {
            final pointerUpMillis = _stopwatch.elapsedMilliseconds;
            final maxPressMillis = 200;
            final diffMillis = pointerUpMillis - _pointerDownMillis;
            if (diffMillis <= maxPressMillis) {
              final position = event.position;
              final distance = (position - _pointerDownPosition).distance;
              if (distance < 5.0 && !_isInteracting) {
                final isLeft = _isLeftPartOfStory(position);
                _focusNode.unfocus();
                if (isLeft) {
                  _storyController.previousSegment();
                } else {
                  _storyController.nextSegment();
                }
              }
            }
            if (_isInteracting) {
              _storyController.unpause();
              _isInteracting = false;
              widget.buttonData.focusNode!.unfocus();
              _focusNode.unfocus();
            }
          },
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _buildPageContent(),
          ),
        ),
      ),
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTimeline(),
            Row(
              
              crossAxisAlignment: CrossAxisAlignment.end,
              // mainAxisSize: MainAxisSize.min,
              children: [
                
                // const Expanded(child: SizedBox()),
          widget.buttonData.optionButton!=null?Flexible(child:
          widget.buttonData.optionButton!.length > _curSegmentIndex
        ? widget.buttonData.optionButton![_curSegmentIndex]
        : widget.buttonData.optionButton![0],
           ):SizedBox.shrink(),
              
              _buildCloseButton(),
              
                ],
            ),
          ],
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        left: 0,
        child: _buildInteractiveWidget())
    ],
  );
}
    @override
  void dispose() {
    widget.pageController?.removeListener(_onPageControllerUpdate);
    _stopwatch.stop();
    _storyController.removeListener(_onTimelineEvent);
    
    _focusNode.dispose();
     
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildPageStructure(),
    );
  }
}

enum StoryTimelineEvent {
  storyComplete,
  segmentComplete,
}

typedef StoryTimelineCallback = Function(StoryTimelineEvent);

class StoryTimelineController {
  _StoryTimelineState? _state;


  final HashSet<StoryTimelineCallback> _listeners =
      HashSet<StoryTimelineCallback>();

  void addListener(StoryTimelineCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(StoryTimelineCallback callback) {
    _listeners.remove(callback);
  }

  void _onStoryComplete() {
    _notifyListeners(StoryTimelineEvent.storyComplete);
  }

  void _onSegmentComplete() {
    _notifyListeners(StoryTimelineEvent.segmentComplete);
  }

  void _notifyListeners(StoryTimelineEvent event) {
    for (var e in _listeners) {
      e.call(event);
    }
  }

  void nextSegment() {
    _state?.nextSegment();
  }

  void previousSegment() {
    _state?.previousSegment();
  }

  void pause() {
    _state?.pause();
  }

  void _setTimelineAvailable(bool value) {
    _state?._setTimelineAvailable(value);
  }

  void unpause() {
    _state?.unpause();
  }

  void dispose() {
    _listeners.clear();
  }

  int get currentSegmentIndex {
    return _state?._curSegmentIndex ?? 0;
  }
}

class StoryTimeline extends StatefulWidget {
  final StoryTimelineController controller;
  final StoryButtonData buttonData;

  const StoryTimeline({
    Key? key,
    required this.controller,
    required this.buttonData,
  }) : super(key: key);

  @override
  State<StoryTimeline> createState() => _StoryTimelineState();
}

class _StoryTimelineState extends State<StoryTimeline> {
  late Timer _timer;
  int _accumulatedTime = 0;
  int _maxAccumulator = 0;
  bool _isPaused = false;
  bool _isTimelineAvailable = true;

  @override
  void initState() {
    _setMaxAccumulator();
    _timer = Timer.periodic(
      const Duration(
        milliseconds: kStoryTimerTickMillis,
      ),
      _onTimer,
    );
    widget.controller._state = this;
    super.initState();
    if (widget.buttonData.storyWatchedContract ==
        StoryWatchedContract.onStoryStart) {
      widget.buttonData.markAsWatched();
    }
  }

 void _setMaxAccumulator() {
  if (widget.buttonData.segmentDurations.isNotEmpty && widget.buttonData.currentSegmentIndex < widget.buttonData.segmentDurations.length) {
    _maxAccumulator = widget.buttonData.segmentDurations[widget.buttonData.currentSegmentIndex].inMilliseconds;
  } else {
    _maxAccumulator = 5 ; // Default to 0 to handle edge cases
  }

  // print('widget.buttonData.currentSegmentIndex ${widget.buttonData.currentSegmentIndex }');
}

  void _setTimelineAvailable(bool value) {
    _isTimelineAvailable = value;
  }

  void _onTimer(timer) {
    if (_isPaused || !_isTimelineAvailable) {
      return;
    }
    if (_accumulatedTime + kStoryTimerTickMillis <= _maxAccumulator) {
      _accumulatedTime += kStoryTimerTickMillis;
      if (_accumulatedTime >= _maxAccumulator) {
        if (_isLastSegment) {
          _onStoryComplete();
        } else {
          _accumulatedTime = 0;
          _curSegmentIndex++;
          _setMaxAccumulator();

          _onSegmentComplete();
        }
      }
      setState(() {});
    }
  }

  void _onStoryComplete() {
    if (widget.buttonData.storyWatchedContract ==
        StoryWatchedContract.onStoryEnd) {
      widget.buttonData.markAsWatched();
    }
    widget.controller._onStoryComplete();
  }

  void _onSegmentComplete() {
    if (widget.buttonData.storyWatchedContract ==
        StoryWatchedContract.onSegmentEnd) {
      widget.buttonData.markAsWatched();
    }
    widget.controller._onSegmentComplete();
  }

  bool get _isLastSegment {
    return _curSegmentIndex == _numSegments - 1;
  }

  int get _numSegments {
    return widget.buttonData.storyPages.length;
  }

  set _curSegmentIndex(int value) {
    if(widget.buttonData.watchedState!=null) {widget.buttonData.watchedState!();}
    if (value >= _numSegments) {
      value = _numSegments - 1;
    } else if (value < 0) {
      value = 0;
    }
    widget.buttonData.currentSegmentIndex = value;
   _setMaxAccumulator();
  }

int get _curSegmentIndex {
  int index = widget.buttonData.currentSegmentIndex;
  if (index >= _numSegments) {
    index = _numSegments - 1;
  } else if (index < 0) {
    index = 0;
  }
  return index;
}

  void nextSegment() {
     
    if (_isLastSegment) {
      _accumulatedTime = _maxAccumulator;
      widget.controller._onStoryComplete();
    } else {
      _accumulatedTime = 0;
      _curSegmentIndex++;
      _setMaxAccumulator();
      _onSegmentComplete();
    }
  }

  void previousSegment() {
    if (_accumulatedTime == _maxAccumulator) {
      _accumulatedTime = 0;
    } else {
      _accumulatedTime = 0;
      _curSegmentIndex--;
      _setMaxAccumulator();
      _onSegmentComplete();
    }
  }

  void pause() {
    _isPaused = true;
  }

  void unpause() {
    _isPaused = false;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2.0,
      width: double.infinity,
      child: CustomPaint(
        painter: _TimelinePainter(
          fillColor: widget.buttonData.timelineFillColor,
          backgroundColor: widget.buttonData.timelineBackgroundColor,
          curSegmentIndex: _curSegmentIndex,
          numSegments: _numSegments,
          percent: _accumulatedTime / _maxAccumulator,
          spacing: widget.buttonData.timelineSpacing,
          thikness: widget.buttonData.timelineThikness,
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final Color fillColor;
  final Color backgroundColor;
  final int curSegmentIndex;
  final int numSegments;
  final double percent;
  final double spacing;
  final double thikness;

  _TimelinePainter({
    required this.fillColor,
    required this.backgroundColor,
    required this.curSegmentIndex,
    required this.numSegments,
    required this.percent,
    required this.spacing,
    required this.thikness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thikness
      ..color = backgroundColor
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thikness
      ..color = fillColor
      ..style = PaintingStyle.stroke;

    final maxSpacing = (numSegments - 1) * spacing;
    final maxSegmentLength = (size.width - maxSpacing) / numSegments;

    for (var i = 0; i < numSegments; i++) {
      final start = Offset(
        ((maxSegmentLength + spacing) * i),
        0.0,
      );
      final end = Offset(
        start.dx + maxSegmentLength,
        0.0,
      );

      canvas.drawLine(
        start,
        end,
        bgPaint,
      );
    }

    for (var i = 0; i < numSegments; i++) {
      final start = Offset(
        ((maxSegmentLength + spacing) * i),
        0.0,
      );
      var endValue = start.dx;
      if (curSegmentIndex > i) {
        endValue = start.dx + maxSegmentLength;
      } else if (curSegmentIndex == i) {
        endValue = start.dx + (maxSegmentLength * percent);
      }

      // Ensure endValue is a valid number
      if (endValue.isNaN) {
        endValue = start.dx;
      }

      final end = Offset(
        endValue,
        0.0,
      );
      if (endValue != start.dx) {
        canvas.drawLine(
          start,
          end,
          fillPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
