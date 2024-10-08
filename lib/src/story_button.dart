import 'package:flutter/material.dart';
import 'package:flutter_instagram_storyboard/src/set_state_after_frame_mixin.dart';
import 'package:flutter_instagram_storyboard/src/story_page_transform.dart';

import 'first_build_mixin.dart';
import 'story_page_container_view.dart';

class StoryButton extends StatefulWidget {
  final StoryButtonData buttonData;
  final ValueChanged<StoryButtonData> onPressed;

  /// [allButtonDatas] required to be able to page through
  /// all stories
  final List<StoryButtonData> allButtonDatas;
  final IStoryPageTransform? pageTransform;
  final ScrollController storyListViewController;

  const StoryButton({
    Key? key,
    required this.onPressed,
    required this.buttonData,
    required this.allButtonDatas,
    required this.storyListViewController,
    this.pageTransform,
  }) : super(key: key);

  @override
  State<StoryButton> createState() => _StoryButtonState();
}

class _StoryButtonState extends State<StoryButton>
    with SetStateAfterFrame, FirstBuildMixin
    implements IButtonPositionable, IWatchMarkable {
  double? _buttonWidth;

  @override
  void initState() {
    _updateDependencies();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant StoryButton oldWidget) {
    _updateDependencies();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didFirstBuildFinish(BuildContext context) {
    setState(() {
      _buttonWidth = context.size?.width;
    });
  }

  void _updateDependencies() {
    widget.buttonData._buttonPositionable = this;
    widget.buttonData._iWatchMarkable = this;
      if (widget.buttonData.markAsWatchedOnCreate||widget.buttonData.currentIndex>=widget.buttonData.storyPages.length-2) {
      widget.buttonData.watchedState?.call();
    }
     else if (widget.buttonData.markAsWatchedOnCreate||widget.buttonData.currentIndex==widget.buttonData.storyPages.length-1) {
      widget.buttonData.markAsWatched();
    }
  }

  Widget _buildChild() {
    if (_buttonWidth == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _buttonWidth,
      child: widget.buttonData.child,
    );
  }

  @override
  Offset? get centerPosition {
    if (!mounted) {
      return null;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(
      Offset(
        renderBox.paintBounds.width * .5,
        renderBox.paintBounds.height * .5,
      ),
    );
  }

  @override
  Offset? get rightPosition {
    if (!mounted) {
      return null;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(
      Offset(
        renderBox.paintBounds.width,
        0.0,
      ),
    );
  }

  @override
  Offset? get leftPosition {
    if (!mounted) {
      return null;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(
      Offset.zero,
    );
  }

  void _onTap() {
    setState(() {
    
       if (widget.buttonData.markAsWatchedOnCreate||widget.buttonData.currentIndex>=widget.buttonData.storyPages.length-1) {
      widget.buttonData.markAsWatched();
    }
    });
    widget.onPressed.call(widget.buttonData);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: widget.buttonData.aspectRatio,
          child: Container(
            decoration: widget.buttonData._isWatched
                ? BoxDecoration(
      borderRadius: const BorderRadius.all(
        Radius.circular(100),
      ),
      border: Border.fromBorderSide(
        BorderSide(
          color: Colors .grey,
          width: 1.5,
        ),
      ),
    )
                : widget.buttonData.borderDecoration,
            child: Padding(
              padding: EdgeInsets.all(
                widget.buttonData.borderOffset,
              ),
              child: ClipRRect(
                borderRadius:
                    widget.buttonData.buttonDecoration.borderRadius?.resolve(
                          null,
                        ) ??
                        const BorderRadius.all(
                          Radius.circular(12.0),
                        ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: widget.buttonData.buttonDecoration,
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashFactory: widget.buttonData.inkFeatureFactory ??
                            InkRipple.splashFactory,
                        onTap: _onTap,
                        child: const SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildChild(),
      ],
    );
  }

  @override
  void markAsWatched() {
    safeSetState(() {
    print(widget.buttonData.storyPages.length);
    print(widget.buttonData.currentIndex);
      if(widget.buttonData.storyPages.length<=1){
        print("ffffffffff${widget.buttonData.storyPages.length}");
         if (widget.buttonData.markAsWatchedOnCreate&&widget.buttonData.currentIndex==widget.buttonData.storyPages.length) {
      widget.buttonData.watchedState?.call();
    }
      }
      else  if (widget.buttonData.markAsWatchedOnCreate||widget.buttonData.currentIndex>=widget.buttonData.storyPages.length-2) {
      widget.buttonData.watchedState?.call();
    }
      // 
    });
  }
}

const int kStoryTimerTickMillis = 50;

enum StoryWatchedContract {
  onStoryStart,
  onStoryEnd,
  onSegmentEnd,
}

typedef IsVisibleCallback = bool Function();

class StoryButtonData {
  static bool defaultIsVisibleCallback() {
    return true;
  }

  /// This affects a border around button
  /// after the story was watched
  /// the border will disappear
  bool _isWatched = false;
  void markAsWatched() {
  //  if(currentSegmentIndex>=storyPages.length-2){
  //   print('${currentSegmentIndex}========${storyPages.length-2}');
     _isWatched = true;
    _iWatchMarkable?.markAsWatched();
  //  }
  }

  int currentSegmentIndex = 0;

  IButtonPositionable? _buttonPositionable;
  IWatchMarkable? _iWatchMarkable;

  final StoryTimelineController? storyController;
  final StoryWatchedContract storyWatchedContract;
  final Curve? pageAnimationCurve;
  final Duration? pageAnimationDuration;
  final double aspectRatio;
  final BoxDecoration buttonDecoration;
  final BoxDecoration borderDecoration;
  final double borderOffset;
  final InteractiveInkFeatureFactory? inkFeatureFactory;
  final Widget child;
  final List<Widget> storyPages;

  final List<Widget>? interactiveWidgets;
  final FocusNode? focusNode;

  final Widget? closeButton;
  final List<Widget>? optionButton;
  final List <Duration> segmentDurations;
  final BoxDecoration containerBackgroundDecoration;
  final Color timelineFillColor;
  final Color timelineBackgroundColor;
  final Color defaultCloseButtonColor;
  final double timelineThikness;
  final double timelineSpacing;
  final EdgeInsets? timlinePadding;
  final IsVisibleCallback isVisibleCallback;
  final Function()? watchedState;
  final bool markAsWatchedOnCreate;
  bool isStoryWatched = false;
  bool areAllSegmentsWatched = false;

  /// Usualy this is required for the final story
  /// to pop it out to its button mosition
  Offset? get buttonCenterPosition {
    return _buttonPositionable?.centerPosition;
  }

  Offset? get buttonLeftPosition {
    return _buttonPositionable?.leftPosition;
  }

  Offset? get buttonRightPosition {
    return _buttonPositionable?.rightPosition;
  }
 int get currentIndex {
  return currentSegmentIndex;
}

  /// [storyWatchedContract] When you want the story to be marked as
  /// watch [StoryWatchedContract.onStoryEnd] means it will be marked only
  /// when you watched the last segment of the story
  /// [StoryWatchedContract.onSegmentEnd] the story will be marked as
  /// read after you have watched at least one segment
  /// [StoryWatchedContract.onStoryStart] the story will be marked as read
  /// right when you open it
  /// [segmentDuration] Duration of each segment in this story
  /// [isVisibleCallback] if this callback returns false
  /// the button will not appear in button list. It might be necessary
  /// if you need to hide it for some reason
  StoryButtonData({
    this.storyWatchedContract = StoryWatchedContract.onStoryEnd,
    this.storyController,
    this.aspectRatio = 1.0,
    this.timelineThikness = 2.0,
    this.timelineSpacing = 8.0,
    this.timlinePadding,
    this.inkFeatureFactory,
    this.pageAnimationCurve,
    this.isVisibleCallback = defaultIsVisibleCallback,
    this.pageAnimationDuration,
    this.timelineFillColor = Colors.white,
    this.defaultCloseButtonColor = Colors.white,
    this.timelineBackgroundColor = const Color.fromARGB(255, 200, 200, 200),
    this.closeButton,
    this.interactiveWidgets,
    this.optionButton,
    this.watchedState,

    this.focusNode,
    required this.storyPages,
    required this.child,
    required this.segmentDurations,
    this.markAsWatchedOnCreate = false,
    this.containerBackgroundDecoration = const BoxDecoration(
      color: Color.fromARGB(255, 0, 0, 0),
    ),
    this.buttonDecoration = const BoxDecoration(
      borderRadius: BorderRadius.all(
        Radius.circular(12.0),
      ),
      color: Color.fromARGB(255, 226, 226, 226),
    ),
    this.borderDecoration = const BoxDecoration(
      borderRadius: BorderRadius.all(
        Radius.circular(15.0),
      ),
      border: Border.fromBorderSide(
        BorderSide(
          color: Color.fromARGB(255, 176, 176, 176),
          width: 1.5,
        ),
      ),
    ),
    this.borderOffset = 1.0,
  }) : assert(
          segmentDurations.isNotEmpty && 
          segmentDurations.every((duration) =>
              duration.inMilliseconds % kStoryTimerTickMillis == 0 &&
              duration.inMilliseconds >= 1000),
          'Each segment duration in milliseconds must be a multiple of $kStoryTimerTickMillis and not less than 1000 milliseconds',
        ){
            if (markAsWatchedOnCreate) {
      markAsWatched();
    }
        }
        
}

abstract class IWatchMarkable {
  void markAsWatched();
}

abstract class IButtonPositionable {
  Offset? get centerPosition;
  Offset? get leftPosition;
  Offset? get rightPosition;
}
