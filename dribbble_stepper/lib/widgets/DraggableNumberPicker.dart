import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as Math;
import 'dart:async';

class DraggableNumberPicker extends StatefulWidget {
  DraggableNumberPicker({Key key,
    this.indicatorColor = const Color(0xff8666fe),
    this.arrowColor = const Color(0xffe0d6ff),
    this.textColor = Colors.white,
    this.min = 0,
    this.max = 50,
    this.defaultValue,
    this.width = 130.0}
  ) : super(key: key);

  final Color indicatorColor;
  final Color arrowColor;
  final Color textColor;
  final int min;
  final int max;
  final int defaultValue;
  final double width;

  @override
  DraggableNumberPickerState createState() => DraggableNumberPickerState();
}

class DraggableNumberPickerState extends State<DraggableNumberPicker> with TickerProviderStateMixin {
  double rawOffset = 0.0;
  double curvedOffset = 0.0;
  Curve curve = Curves.easeOut;
  AnimationController controller;
  Animation<double> animation;
  Animation curvedAnimation;
  Tween<double> returnAnimation = new Tween();
  int currentNumber;
  bool locked;
  PageController pageController;

  @override
  void initState() {
    currentNumber = widget.defaultValue == null ? widget.min : widget.defaultValue;
    pageController = new PageController(initialPage: currentNumber);
    controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    curvedAnimation = CurvedAnimation(parent: controller, curve: new ElasticOutCurve(0.7));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      width: widget.width,
      height: 100.0,
      child: new GestureDetector(
        onHorizontalDragEnd: (details){
          _backToCenter();
        },
        onHorizontalDragStart: (details){
          _interruptAnimation();
        },
        onHorizontalDragUpdate: (details){
          _updatePosition(details.delta.dx);
        },
        child: new Stack(
          fit: StackFit.expand,
          children: [
            new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 6.0, right: 6.0),
                    child: new Icon(Icons.navigate_before, color: widget.arrowColor, size: 38.0),
                  ),
                  onTap: (){
                    _previous();
                  },
                ),
                new GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 6.0, left: 6.0),
                    child: new Icon(Icons.navigate_next, color: widget.arrowColor, size: 38.0),
                  ),
                  onTap: (){
                    _next();
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: new Align(
                alignment: new Alignment(curvedOffset, 0.0),
                child: new Container(
                  width: 50.0,
                  height: 50.0,
                  child: new Material(
                    color: widget.indicatorColor,
                    type: MaterialType.card,
                    borderRadius: BorderRadius.circular(12.0),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overScroll) {
                        overScroll.disallowGlow();
                      },
                      child: new PageView.builder(
                        //Add 1 to make the range all-inclusive
                        itemCount: widget.max-widget.min+1,
                        itemBuilder: (context, i){
                          return Center(child: new Text(i.toString(), style: new TextStyle(color: Colors.white, fontSize: 26.0, fontWeight: FontWeight.w700)));
                        },
                        controller: pageController,
                        physics: new NeverScrollableScrollPhysics()
                      ),
                    )
                  ),
                  decoration: new BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        new BoxShadow(
                          color: new Color.fromARGB(100, widget.indicatorColor.red, widget.indicatorColor.green, widget.indicatorColor.blue),
                          blurRadius: 16.0,
                          offset: new Offset(0.0, 12.0),
                        ),
                      ]
                  ),
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }

  void _backToCenter(){
    setState(() {
      //Assign a new Tween object otherwise the square would jump to the maximum distance
      //before returning to the center
      returnAnimation = new Tween(begin: curvedOffset, end: 0.0);

      //Initialize the animation with the new tween start point
      animation = returnAnimation.animate(curvedAnimation)..addListener((){
        setState(() {
          //Update the offsets
          locked = false;
          rawOffset = animation.value;
          curvedOffset = animation.value;
        });
      });

      //Clear any previous animation values
      controller.reset();

      //Begin the animation
      controller.forward();
    });
  }

  void _interruptAnimation(){
    //Stop the returning animation so we don't have conflicting values
    controller.stop();
  }

  void _updatePosition(double deltaX){
    setState(() {
      //Decrease the delta by 20%
      rawOffset += deltaX/1.8;

      //Pass the raw offset data through a curve object to apply the curve to our values
      var transformed = curve.transform(Math.min(1.0, rawOffset.abs()/(widget.width/2-25)));

      //The two offset variables needed to be separated because the GestureDetector only provides us
      //with delta values. We have to store the current total offset ourselves.
      curvedOffset = (rawOffset > 0 ? transformed : -transformed);

      //If the curved offset is close to the maximum offset (1.0) call the next or previous function
      if(curvedOffset >= 0.99 && !locked){
        _next();
      }else if(curvedOffset <= -0.99 && !locked) {
        _previous();
      }else if(curvedOffset < 0.99 && curvedOffset > -0.99){
        locked = false;

        if(delayTimer != null)
          delayTimer.cancel();
      }
    });
  }

  void _next(){
    if(currentNumber >= widget.max)
      return;

    HapticFeedback.lightImpact();
    _startSpeedTimer();
    currentNumber++;
    pageController.animateToPage(currentNumber, duration: new Duration(milliseconds: 350), curve: Curves.decelerate);
    locked = true;
  }

  void _previous(){
    if(currentNumber <= widget.min)
      return;

    HapticFeedback.lightImpact();
    _startSpeedTimer();
    currentNumber--;
    pageController.animateToPage(currentNumber, duration: new Duration(milliseconds: 350), curve: Curves.decelerate);
    locked = true;
  }

  Timer delayTimer;

  void _startSpeedTimer(){
    if(delayTimer != null)
      delayTimer.cancel();

    delayTimer = new Timer(new Duration(milliseconds: 450), (){
      new Timer.periodic(const Duration(milliseconds: 75), (Timer t){
        if(locked){
          if(curvedOffset > 0.0){
            if(currentNumber >= widget.max)
              return;
            currentNumber++;
            pageController.animateToPage(currentNumber, duration: new Duration(milliseconds: 350), curve: Curves.decelerate);
            HapticFeedback.lightImpact();
          }else if(curvedOffset < 0.0){
            if(currentNumber <= widget.min)
              return;
            currentNumber--;
            pageController.animateToPage(currentNumber, duration: new Duration(milliseconds: 350), curve: Curves.decelerate);
            HapticFeedback.lightImpact();
          }
        }else{
          t.cancel();
        }
      });
    });
  }
}