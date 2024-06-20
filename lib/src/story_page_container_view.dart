 import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_instagram_storyboard/flutter_instagram_storyboard.dart';
import 'package:flutter_instagram_storyboard/src/first_build_mixin.dart';

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
  List<FocusNode> _textFieldFocusNodes = [];

  @override
  void initState() {
    _storyController =
        widget.buttonData.storyController ?? StoryTimelineController();
    _stopwatch.start();
    _storyController.addListener(_onTimelineEvent);
     // Initialize focus nodes for each story page
    _textFieldFocusNodes = List.generate(
      widget.buttonData.storyPages.length,
      (index) => FocusNode(),
    );
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
      padding: const EdgeInsets.symmetric(
        horizontal: 15.0,
        vertical: 10.0,
      ),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
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
    onTap: () {},
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

Widget _buildInteractiveWidgets() {
  if (widget.buttonData.interactiveWidgets == null ||
      widget.buttonData.interactiveWidgets!.isEmpty) {
    return Container();
  }

  return GestureDetector(
    
    child: Focus(
      focusNode: _textFieldFocusNodes[_curSegmentIndex],
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
      child: widget.buttonData.interactiveWidgets![_curSegmentIndex],
    ),
  );
}


   Widget _buildPageStructure() {
    return Stack(
      children: [
        GestureDetector(

         onVerticalDragStart: (details) {
      final storyHeight = context.size!.height;
      final dragStartY = details.localPosition.dy;
      // Adjust the threshold as needed to determine when to open the keyboard
      final openKeyboardThreshold = storyHeight * 0.7;
      if (dragStartY >= openKeyboardThreshold) {
        // Focus the text field and open keyboard
        _textFieldFocusNodes[_curSegmentIndex].requestFocus();
        FocusScope.of(context).requestFocus(_textFieldFocusNodes[_curSegmentIndex]);
        // Ensure the keyboard is open by unfocusing immediately
        _textFieldFocusNodes[_curSegmentIndex].unfocus();
        // Delay refocus to ensure it happens after the keyboard is fully shown
        Future.delayed(Duration(milliseconds: 200), () {
          FocusScope.of(context).requestFocus(_textFieldFocusNodes[_curSegmentIndex]);
        });
      }
    },
          onTap: () {
            _textFieldFocusNodes[_curSegmentIndex].unfocus();
             // Unfocus the text field when tapping elsewhere
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
                _textFieldFocusNodes[_curSegmentIndex].unfocus(); // Unfocus the text field
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
                _textFieldFocusNodes[_curSegmentIndex].unfocus(); // Unfocus the text field
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
            children: [
              _buildTimeline(),
              _buildCloseButton(),
            ],
          ),
        ),
        Positioned(
          // bottom: 20.0,
          // left: 20.0,
          // right: 20.0,
          child: _buildInteractiveWidgets(),
        ),
      ],
    );
  }


    @override
  void dispose() {
    widget.pageController?.removeListener(_onPageControllerUpdate);
    _stopwatch.stop();
    _storyController.removeListener(_onTimelineEvent);
    // Dispose of all focus nodes
    for (var focusNode in _textFieldFocusNodes) {
      focusNode.dispose();
    }
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
    _maxAccumulator = widget.buttonData.segmentDuration.inMilliseconds;
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
    if (value >= _numSegments) {
      value = _numSegments - 1;
    } else if (value < 0) {
      value = 0;
    }
    widget.buttonData.currentSegmentIndex = value;
  }

  int get _curSegmentIndex {
    return widget.buttonData.currentSegmentIndex;
  }

  void nextSegment() {
    if (_isLastSegment) {
      _accumulatedTime = _maxAccumulator;
      widget.controller._onStoryComplete();
    } else {
      _accumulatedTime = 0;
      _curSegmentIndex++;
      _onSegmentComplete();
    }
  }

  void previousSegment() {
    if (_accumulatedTime == _maxAccumulator) {
      _accumulatedTime = 0;
    } else {
      _accumulatedTime = 0;
      _curSegmentIndex--;
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
      final end = Offset(
        endValue,
        0.0,
      );
      if (endValue == start.dx) {
        continue;
      }
      canvas.drawLine(
        start,
        end,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
