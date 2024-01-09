import 'dart:async';
import 'dart:math' as math;


import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/components.dart';
import 'config.dart';

enum PlayState { welcome, playing, gameOver, won }

class BrickBreaker extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector {
  BrickBreaker()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: gameWidth,
            height: gameHeight,
          ),
        );

  final ValueNotifier<int> score = ValueNotifier(0);            // Add this line
  final rand = math.Random();
  double get width => size.x;
  double get height => size.y;
  static const duration = Duration(seconds: 1);
  late PlayState _playState;
  PlayState get playState => _playState;
  set playState(PlayState playState) {
    _playState = playState;
    switch (playState) {
      case PlayState.welcome:
      case PlayState.gameOver:
      case PlayState.won:
        overlays.add(playState.name);
      case PlayState.playing:
        overlays.remove(PlayState.welcome.name);
        overlays.remove(PlayState.gameOver.name);
        overlays.remove(PlayState.won.name);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (playState != PlayState.playing) {
      return;
    }

    // Spawn a new brick at random intervals
    if (math.Random().nextDouble() < 0.01) {
      spawnBrick();
    }

    // Move existing bricks downward
    for (final brick in world.children.whereType<Brick>()) {
      brick.position.y += 500 * dt;
    }
  }

  void spawnBrick() {
    final variable = math.Random().nextDouble();
    final position = Vector2(variable * (1080 - brickWidth), 2.0 * brickHeight);

    final newBrick = Brick(position);
    world.add(newBrick);
  }

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(PlayArea());

    playState = PlayState.welcome;
  }

  void startGame() async{
    if (playState == PlayState.playing) return;

    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Bat>());
    world.removeAll(world.children.query<Brick>());

    playState = PlayState.playing;
    score.value = 0;                                            // Add this line

    // world.add(Ball(
    //     difficultyModifier: difficultyModifier,
    //     radius: ballRadius,
    //     position: size / 2,
    //     velocity: Vector2((rand.nextDouble() - 0.5) * width, height * 0.2)
    //         .normalized()
    //       ..scale(height / 4)));

    Bat rocket = Bat(size: Vector2(batWidth, batHeight),
        position: Vector2(width / 2, height * 0.95));

    rocket
      ..sprite = await loadSprite('game/rocket.png')
      ..size = Vector2(300, 450);
    world.add(rocket);

    // world.add(Bat(
    //     size: Vector2(batWidth, batHeight),
    //     cornerRadius: const Radius.circular(ballRadius / 2),
    //     position: Vector2(width / 2, height * 0.95)));

    // world.addAll([
    //   for (var i = 0; i < brickColors.length; i++)
    //     for (var j = 1; j <= 5; j++)
    //       Brick(
    //         Vector2(
    //           (i + 0.5) * brickWidth + (i + 1) * brickGutter,
    //           (j + 2.0) * brickHeight + j * brickGutter,
    //         ),
    //         brickColors[i],
    //       ),
    // ]);
  }

  @override
  void onTap() {
    super.onTap();
    startGame();
  }

  void moveBatBasedOnAccelerometer(int accelerometerX) {
    final bat = world.children.query<Bat>().first;
    // Adjust the sensitivity based on your requirements
    double sensitivity = 0.2;

    if (accelerometerX > sensitivity) {
      bat.moveBy(-batStep);
    } else if (accelerometerX < -sensitivity) {
      bat.moveBy(batStep);
    }
  }

  void handleButtonPress() {
    Future.delayed(duration, () {
      world.add(Ball(
        difficultyModifier: difficultyModifier,
        radius: ballRadius,
        position: world.children.query<Bat>().first.position,
      ));
    });
  }

  // @override
  // KeyEventResult onKeyEvent(
  //     RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
  //   super.onKeyEvent(event, keysPressed);
  //   switch (event.logicalKey) {
  //     case LogicalKeyboardKey.arrowLeft:
  //       world.children.query<Bat>().first.moveBy(-batStep);
  //     case LogicalKeyboardKey.arrowRight:
  //       world.children.query<Bat>().first.moveBy(batStep);
  //     case LogicalKeyboardKey.space:
  //       world.add(Ball(
  //         difficultyModifier: difficultyModifier,
  //         radius: ballRadius,
  //         position: world.children.query<Bat>().first.position,
  //       ));
  //     case LogicalKeyboardKey.enter:
  //       startGame();
  //   }
  //   return KeyEventResult.handled;
  // }

  @override
  Color backgroundColor() => const Color(0xff8091a2);
}