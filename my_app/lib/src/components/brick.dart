import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:my_app/src/components/components.dart';

import '../brick_breaker.dart';
import '../config.dart';
import 'ball.dart';
import 'bat.dart';

class Brick extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Brick(Vector2 position)
      : super(
            position: position,
            radius: gameWidth * (0.025 + math.Random().nextDouble() * (0.075 - 0.025)),
            anchor: Anchor.center,
            paint: Paint()
              ..color = Color(0xFF343541)
              ..style = PaintingStyle.fill,
            children: [CircleHitbox()]);
  bool touch = false;

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);  
    
    print(other);                                  // Add this line

    if (!touch) {
    if (other is Brick) {
      removeFromParent();
      touch = true;
    } else if (other is Bat) {
      removeFromParent();
      game.playState = PlayState.gameOver;
      touch = true;
    } else if (other is Ball) {
      removeFromParent();
      print("SCORED POINTS");
      game.score.value++;  
      touch = true; 
    } else if (other is PlayArea) {
      print("PLAY AREA TOUCHED NOT EXPECTED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      removeFromParent();
      game.playState = PlayState.gameOver;
      touch = true;
    }
    }
  }
}