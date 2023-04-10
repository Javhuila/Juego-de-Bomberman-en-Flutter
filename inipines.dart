import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';
import 'package:image/image.dart' as uimage;

enum CubeType { Wall, Path, Brick, Bom }

enum PowerUp { FastMove, EnterBrick, BoomArea, Door }

class CubeClass {
  Size? size;
  Offset? pos;
  Color? color;
  CubeType type;
  bool canOverlap;
  PowerUp? powerUp;

  CubeClass({
    this.pos,
    this.size,
    this.color,
    this.type = CubeType.Path,
    this.canOverlap = true,
    this.powerUp,
  });
}

class ControllerJoy {
  bool up;
  bool down;
  bool left;
  bool right;

  ControllerJoy({
    this.up = false,
    this.down = false,
    this.left = false,
    this.right = false,
  });

  void updateValue({
    bool up = false,
    bool down = false,
    bool left = false,
    bool right = false,
  }) {
    this.up = up;
    this.down = down;
    this.left = left;
    this.right = right;
  }

  void clearMove() {
    this.up = false;
    this.down = false;
    this.left = false;
    this.right = false;
  }

  bool isMove() => up || down || left || right;
}

class BomObject {
  Offset? pos;
  Size? size;
  int? opacity;
  List<Offset>? boomAreas;
  bool explode;
  double scale;
  List<int>? bricksDestroy = [];

  BomObject({
    this.pos,
    this.size,
    this.opacity,
    this.boomAreas,
    this.scale = 1,
    this.explode = false,
    this.bricksDestroy,
  });
}

class MoveEnable {
  bool horizontal;
  bool vertical;
  Axis? axis;
  double? sizeRange;

  MoveEnable({
    this.axis,
    this.sizeRange,
    this.horizontal = false,
    this.vertical = false,
  });

  bool canMove() =>
      (this.horizontal && this.axis == Axis.horizontal) ||
      (this.vertical && this.axis == Axis.vertical);

  Offset move(Offset currentTarget, Offset posTarget, Offset minOffset,
      Offset maxOffset) {
    if (horizontal && axis == Axis.horizontal) {
      if (minOffset.dx <= posTarget.dx && posTarget.dx <= maxOffset.dx) {
        return posTarget;
      } else {
        return Offset(
          posTarget.dx > currentTarget.dx ? maxOffset.dx : minOffset.dx,
          currentTarget.dy,
        );
      }
    } else if (vertical && axis == Axis.vertical) {
      if (minOffset.dy <= posTarget.dy && posTarget.dy <= maxOffset.dy) {
        return posTarget;
      } else {
        return Offset(
          currentTarget.dx,
          posTarget.dy > currentTarget.dy ? maxOffset.dy : minOffset.dy,
        );
      }
    }
    return currentTarget;
  }
}

class IniPines extends StatefulWidget {
  const IniPines({Key? key}) : super(key: key);

  @override
  _IniPinesState createState() => _IniPinesState();
}

class _IniPinesState extends State<IniPines> {
  final GlobalKey<_BomberGameBoxState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        actions: [
          InkWell(
            onTap: () => _key.currentState!.refreshGame(),
            child: const Icon(Icons.refresh_outlined),
          )
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                Size size = constraints.biggest;
                return Container(
                  color: Colors.green,
                  child: BomberGameBox(
                    size: size,
                    key: _key,
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(width: 0, color: Colors.transparent),
              color: Colors.yellow[200],
            ),
            height: 150,
            padding: EdgeInsets.all(10),
            width: double.maxFinite,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: constraints.biggest.height,
                        height: constraints.biggest.height,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            childAspectRatio: 1,
                            crossAxisCount: 3,
                            crossAxisSpacing: 3,
                            mainAxisSpacing: 3,
                          ),
                          shrinkWrap: true,
                          itemCount: 9,
                          physics: ScrollPhysics(),
                          itemBuilder: (context, index) {
                            bool enable = index % 2 == 1;
                            IconData icon = Icons.keyboard_arrow_up;

                            if (index == 3) icon = Icons.keyboard_arrow_left;
                            if (index == 5) icon = Icons.keyboard_arrow_right;
                            if (index == 7) icon = Icons.keyboard_arrow_down;

                            return Offstage(
                              offstage: !enable,
                              child: Container(
                                alignment: Alignment.center,
                                child: SizedBox.expand(
                                  child: Listener(
                                    onPointerDown: (event) =>
                                        _key.currentState?.controllerDown(
                                      up: index == 1,
                                      left: index == 3,
                                      right: index == 5,
                                      down: index == 7,
                                    ),
                                    onPointerUp: (event) =>
                                        _key.currentState?.controllerUp(),
                                    child: Container(
                                      alignment: Alignment.center,
                                      color: Colors.blue,
                                      child: Icon(icon),
                                      // child: Text(
                                      //   "X",
                                      //   textAlign: TextAlign.center,
                                      // ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: constraints.biggest.height * .8,
                        height: constraints.biggest.height * .8,
                        child: ElevatedButton(
                          onPressed: () => _key.currentState?.triggerBom(),
                          child: Text(
                            "Boom",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}

class BomberGameBox extends StatefulWidget {
  Size? size;
  BomberGameBox({Key? key, this.size}) : super(key: key);

  @override
  _BomberGameBoxState createState() => _BomberGameBoxState();
}

class _BomberGameBoxState extends State<BomberGameBox>
    with TickerProviderStateMixin {
  Animation? animation;
  AnimationController? animationController;

  ValueNotifier<ControllerJoy>? controllerJoyValue;
  ValueNotifier<Offset>? posBoxValue;
  ValueNotifier<Offset>? posPlayerValue;
  ValueNotifier<List<CubeClass>>? cubesValue;
  ValueNotifier<List<PowerUp>>? powerUps;
  ValueNotifier<List<BomObject>>? bomObjectsValue;
  ValueNotifier<List<int>>? bricksDestroyValue;

  BgGroundEffect? bgGroundEffect;

  double border = 20;
  Size? size;
  Size? sizeBox = Size(50, 50);
  int? row;
  int? col;
  double stepMove = 10;
  int? stepMoveInMili;
  ui.Image? image;
  bool? gameEnd;

  refreshGame() async {
    row = 13;
    col = 9;
    stepMoveInMili = 70;
    gameEnd = false;
    animationController?.dispose();
    controllerJoyValue = ValueNotifier<ControllerJoy>(ControllerJoy());
    posBoxValue = ValueNotifier<Offset>(Offset.zero);
    posPlayerValue = ValueNotifier<Offset>(Offset.zero);
    cubesValue = ValueNotifier<List<CubeClass>>([]);
    powerUps = ValueNotifier<List<PowerUp>>([]);
    bomObjectsValue = ValueNotifier<List<BomObject>>([]);
    bricksDestroyValue = ValueNotifier<List<int>>([]);

    bgGroundEffect = BgGroundEffect();

    animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: stepMoveInMili!));
    animation = Tween(begin: 0, end: 1).animate(animationController!)
      ..addListener(
        () async {
          if (animation!.status == AnimationStatus.completed) {
            if (controllerJoyValue!.value.isMove()) {
              // print("move aaa 2");
              await moveUpdate();
            }

            animationController?.stop();
            animationController?.reset();
            animationController?.forward();
          }
        },
      );

    animationController?.forward();

    powerUps?.value.add(PowerUp.BoomArea);
    powerUps?.notifyListeners();

    bgGroundEffect =
        BgGroundEffect(blocks: this.cubesValue!.value, image: this.image);

    await loadBrickImageUi();

    generateBlockCube();
    setState(() {});
  }

  @override
  void dispose() {
    animation!.removeListener(() {});
    animationController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    size = widget.size;
    super.initState();

    refreshGame();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          ValueListenableBuilder(
              valueListenable: posBoxValue!,
              builder: (context, Offset posBox, child) {
                return AnimatedPositioned(
                  duration: Duration(milliseconds: stepMoveInMili! * 2),
                  left: posBox.dx,
                  top: posBox.dy,
                  child: child!,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green[200],
                  border: Border.all(width: border, color: Colors.grey),
                ),
                width: sizeBox!.width * col! + border * 2,
                height: sizeBox!.height * row! + border * 2,
                child: ValueListenableBuilder(
                    valueListenable: cubesValue!,
                    builder: (context, List<CubeClass> cubes, child) {
                      return ValueListenableBuilder(
                        valueListenable: bomObjectsValue!,
                        builder:
                            (context, List<BomObject> bomObjects, bomChild) {
                          return CustomPaint(
                            painter: bgGroundEffect,
                            child: Stack(
                              children: [
                                if (cubes != null)
                                  ...cubes.map((cube) {
                                    return Positioned(
                                      left: cube.pos?.dx,
                                      top: cube.pos?.dy,
                                      child: Container(
                                        width: cube.size?.width,
                                        height: cube.size?.height,
                                        padding: EdgeInsets.all(2),
                                        // child: Container(
                                        //   color: Colors.white,
                                        //   alignment: Alignment.center,
                                        //   child: Text("${cube.pos}"),
                                        // ),
                                      ),
                                    );
                                  }),
                                if (cubes != null)
                                  ...cubes
                                      .where(
                                          (element) => element.powerUp != null)
                                      .map((cube) {
                                    Color color = Colors.yellow;

                                    IconData icon = Icons.send;

                                    if (cube.powerUp == PowerUp.BoomArea)
                                      icon = Icons.open_with_outlined;
                                    else if (cube.powerUp == PowerUp.EnterBrick)
                                      icon = FontAwesomeIcons.personSkating;
                                    else if (cube.powerUp == PowerUp.Door)
                                      icon = Icons.sensor_door;

                                    return Positioned(
                                      left: cube.pos?.dx,
                                      top: cube.pos?.dy,
                                      child: Container(
                                        width: cube.size?.width,
                                        height: cube.size?.height,
                                        padding: EdgeInsets.all(2),
                                        child: Offstage(
                                          offstage: cube.type == CubeType.Brick,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 3,
                                                color: color,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              icon,
                                              color: color,
                                              size: sizeBox!.width * .6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                if (bomObjects != null)
                                  ...bomObjects
                                      .map(
                                        (bomObject) => Positioned(
                                          left: bomObject.pos?.dx,
                                          top: bomObject.pos?.dy,
                                          child: SizedBox(
                                            width: bomObject.size?.width,
                                            height: bomObject.size?.height,
                                            child: Transform.scale(
                                              scale: bomObject.scale,
                                              child: Container(
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.all(3),
                                                // color: Colors.red,
                                                child: Stack(
                                                  clipBehavior: Clip.antiAlias,
                                                  fit: StackFit.passthrough,
                                                  children: [
                                                    Image(
                                                      image: AssetImage(
                                                          "assets/images/bom.png"),
                                                      fit: BoxFit.contain,
                                                    ),
                                                    Positioned(
                                                      top: -bomObject
                                                              .size!.height /
                                                          2,
                                                      right: -1,
                                                      child: Image(
                                                        image: AssetImage(
                                                            "assets/images/fire.png"),
                                                        fit: BoxFit.contain,
                                                        width: bomObject
                                                                .size!.width /
                                                            2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                child!,
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: ValueListenableBuilder(
                        valueListenable: posPlayerValue!,
                        builder: (context, Offset posPlayer, child) {
                          return AnimatedPositioned(
                            duration:
                                Duration(milliseconds: stepMoveInMili! * 2),
                            left: posPlayer.dx,
                            top: posPlayer.dy,
                            child: Container(
                              width: sizeBox?.width,
                              height: sizeBox?.height,
                              child: Image(
                                image: AssetImage("assets/images/player.png"),
                              ),
                            ),
                          );
                        })),
              )),
        ],
      ),
    );
  }

  triggerBom() {
    int indexPlayer = getIndexFromPlayerPos();

    calculateBomFromPlayerPos(indexPlayer);
  }

  int getIndexFromPlayerPos() {
    int crow =
        (posPlayerValue!.value.dy + sizeBox!.height / 2) ~/ sizeBox!.height;
    int ccol =
        (posPlayerValue!.value.dx + sizeBox!.width / 2) ~/ sizeBox!.width;

    return crow * col! + ccol;
  }

  calculateBomFromPlayerPos(int indexPlayer) {
    CubeClass playerBlok = cubesValue!.value[indexPlayer];
    BomObject temp = new BomObject(
      opacity: 1,
      pos: playerBlok.pos,
      size: playerBlok.size,
    );

    List<int> listLineEffectRow =
        calculateLineBom(temp, playerBlok, indexPlayer);

    // print("efect a");
    temp.boomAreas =
        listLineEffectRow.map((e) => cubesValue!.value[e].pos!).toList();
    // print("efect b");
    bgGroundEffect?.update(
        bomObjects: bomObjectsValue?.value, powerUps: powerUps?.value);
    bomObjectsValue?.value.add(temp);
    playerBlok.canOverlap = false;
    cubesValue?.notifyListeners();

    Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (timer.tick > 20) {
        temp.explode = true;
        timer.cancel();

        bgGroundEffect?.updateEffect(temp);
        Future.delayed(Duration(milliseconds: 500)).then((value) {
          temp.bricksDestroy?.forEach((element) {
            cubesValue?.value[element].type = CubeType.Path;
          });

          playerBlok.canOverlap = true;
          bomObjectsValue?.value.remove(temp);
          bomObjectsValue?.notifyListeners();
          cubesValue?.notifyListeners();
        });
      } else {
        temp.scale = timer.tick % 3 == 2 ? 0.8 : 1.1;
        bomObjectsValue?.notifyListeners();
      }
    });
  }

  calculateLineBom(BomObject temp, CubeClass playerBlok, int playerIndex) {
    int sizeBomEffect =
        powerUps!.value.where((element) => element == PowerUp.BoomArea).length;

    int minIndexRow = playerIndex ~/ col! * col!;
    int maxIndexRow = playerIndex ~/ col! * col! + col! - 1;
    int minIndexCol = playerIndex % col!;
    int maxIndexCol = (row! - 1) * col! + playerIndex % col!;

    List<int> keys = [];
    bricksDestroyValue?.value = [];

    int left = 1, right = 1, top = 1, bottom = 1;

    keys.add(playerIndex);

    if (playerBlok.type == CubeType.Brick)
      bricksDestroyValue?.value.add(playerIndex);

    for (var i = 0; i < sizeBomEffect; i++) {
      if (playerIndex - (i + 1) >= minIndexRow && left != 0) {
        if (cubesValue?.value[playerIndex - (i + 1)].type == CubeType.Brick) {
          bricksDestroyValue?.value.add(playerIndex - (i + 1));
          keys.add(playerIndex - (i + 1));
          left = 0;
        } else if (cubesValue?.value[playerIndex - (i + 1)].type ==
            CubeType.Wall) {
          left = 0;
        } else {
          keys.add(playerIndex - (i + 1));
        }
      }

      if (playerIndex + (i + 1) <= maxIndexRow && right != 0) {
        if (cubesValue?.value[playerIndex + (i + 1)].type == CubeType.Brick) {
          bricksDestroyValue?.value.add(playerIndex + (i + 1));
          keys.add(playerIndex + (i + 1));
          right = 0;
        } else if (cubesValue?.value[playerIndex + (i + 1)].type ==
            CubeType.Wall) {
          right = 0;
        } else {
          keys.add(playerIndex + (i + 1));
        }
      }

      if (playerIndex - (col! * (i + 1)) >= minIndexCol && top != 0) {
        // print("minIndexCol $minIndexCol - ${playerIndex - (col! * (i + 1))}");
        if (cubesValue?.value[playerIndex - (col! * (i + 1))].type ==
            CubeType.Brick) {
          bricksDestroyValue?.value.add(playerIndex - (col! * (i + 1)));
          keys.add(playerIndex - (col! * (i + 1)));
          top = 0;
        } else if (cubesValue?.value[playerIndex - (col! * (i + 1))].type ==
            CubeType.Wall) {
          top = 0;
        } else {
          keys.add(playerIndex - (col! * (i + 1)));
        }
      }

      if (playerIndex + (col! * (i + 1)) <= maxIndexCol && bottom != 0) {
        if (cubesValue?.value[playerIndex + (col! * (i + 1))].type ==
            CubeType.Brick) {
          bricksDestroyValue?.value.add(playerIndex + (col! * (i + 1)));
          keys.add(playerIndex + (col! * (i + 1)));
          bottom = 0;
        } else if (cubesValue?.value[playerIndex + (col! * (i + 1))].type ==
            CubeType.Wall) {
          bottom = 0;
        } else {
          keys.add(playerIndex + (col! * (i + 1)));
        }
      }
    }

    bricksDestroyValue?.notifyListeners();
    temp.bricksDestroy = bricksDestroyValue?.value;

    return keys.toSet().toList();
  }

  moveUpdate() async {
    if (gameEnd!) return;

    bool isPlayerMove = await movePlayer();
    // bool isPlayerMove = true;

    moveBox(isPlayerMove: isPlayerMove);
    this.controllerJoyValue?.notifyListeners();

    // print("move");
  }

  void generateBlockCube() {
    cubesValue?.value = [];

    for (var i = 0; i < row!; i++) {
      for (var j = 0; j < col!; j++) {
        CubeType type = CubeType.Path;

        if (i % 2 == 1) if (j % 2 == 1) type = CubeType.Wall;

        if (type == CubeType.Path) {
          int random = Random().nextInt(2);
          if (random != 0) type = CubeType.Brick;
        }

        Offset pos = Offset(j + sizeBox!.width, i * sizeBox!.height);

        cubesValue?.value.add(CubeClass(
          color: Colors.white,
          size: sizeBox!,
          type: type,
          pos: pos,
        ));
      }
    }

    List<PowerUp> powersUp =
        PowerUp.values.where((element) => element != PowerUp.FastMove).toList();

    List<CubeClass> bricks = cubesValue!.value
        .where((element) => element.type == CubeType.Brick)
        .toList();

    // Borrar las siguientes 4 lineas por si falla.
    // bricks.first.powerUp = PowerUp.Door;
    // bricks.shuffle(new Random(20));
    // cubesValue.notifyListeners();
    // powersUp.removeWhere((element) => element == PowerUp.Door);

    for (var i = 0; i < bricks.length; i++) {
      if (bricks
              .where((element) => element.powerUp == PowerUp.FastMove)
              .length >
          0) powersUp.removeWhere((element) => (element) == PowerUp.FastMove);
      if (bricks.where((element) => element.powerUp == PowerUp.Door).length > 0)
        powersUp.removeWhere((element) => (element) == PowerUp.Door);

      bricks.shuffle(new Random(20));
      bricks.last.powerUp = powersUp[new Random().nextInt(powersUp.length)];
      bricks.shuffle(new Random(20));
    }

    bgGroundEffect?.update(blocks: cubesValue?.value, image: image);
    setState(() {});
  }

  controllerUp() {
    this.controllerJoyValue?.value.clearMove();
    this.controllerJoyValue?.notifyListeners();
  }

  controllerDown({
    required bool up,
    required bool down,
    required bool left,
    required bool right,
  }) {
    this.controllerJoyValue?.value.updateValue(
          up: up,
          down: down,
          left: left,
          right: right,
        );
    this.controllerJoyValue?.notifyListeners();

    // Prueba para la función del movimiento establecido
    // Up = up / Up != down
    print(
      "up: $up, right: $right, left: $left, down: $down",
    );
  }

  Future<void> loadBrickImageUi() async {
    final ByteData data = await rootBundle.load("assets/images/brick.png");
    image = await loadImage(Uint8List.view(data.buffer));
  }

  loadImage(Uint8List img) async {
    uimage.Image? baseSizeImage = uimage.decodeImage(img);
    uimage.Image resizeImage = uimage.copyResize(
      baseSizeImage!,
      height: sizeBox?.height.floor(),
      width: sizeBox?.width.floor(),
    );

    ui.Codec codec =
        await ui.instantiateImageCodec(uimage.encodePng(resizeImage));
    ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  void moveBox({bool isPlayerMove = true}) {
    // print("move aaa 3");
    Size defaultSizeBlok = Size(col! * sizeBox!.width + border * 2,
        row! * sizeBox!.height + border * 2);

    ControllerJoy controllerJoy = this.controllerJoyValue!.value;
    Offset tempBgPos = posBoxValue!.value;

    MoveEnable moveEnableBox = MoveEnable(
      axis: (controllerJoy.up || controllerJoy.down)
          ? Axis.vertical
          : Axis.horizontal,
    );

    double widthBox = defaultSizeBlok.width;
    double heightBox = defaultSizeBlok.height;

    moveEnableBox.horizontal = size!.width < widthBox;
    moveEnableBox.vertical = size!.width < heightBox;

    Size minSize =
        Size(min(widthBox, size!.width), min(heightBox, size!.height));

    Offset centerPlayerPos = posPlayerValue!.value;

    Offset centerPlayerBoxPoint = Offset(
      minSize.width / 2 + tempBgPos.dx.abs(),
      minSize.height / 2 + tempBgPos.dy.abs(),
    );

    bool boxCanMove = false;
    // bool boxCanMove = true;
    print("as ${moveEnableBox.canMove()} $boxCanMove $isPlayerMove");

    double distDx = (centerPlayerBoxPoint.dx - centerPlayerPos.dx).abs();
    double distDy = (centerPlayerBoxPoint.dy - centerPlayerPos.dy).abs();

    if (controllerJoy.up || controllerJoy.down) {
      if (posPlayerValue!.value.dy > minSize.height / 2 && controllerJoy.down) {
        boxCanMove = true;
      } else if (posPlayerValue!.value.dy - (sizeBox!.height) <
              (defaultSizeBlok.height - sizeBox!.height - minSize.height / 2) &&
          controllerJoy.up) {
        boxCanMove = true;
      } else if (distDy < 30) boxCanMove = true;
    } else {
      if (posPlayerValue!.value.dx > minSize.width / 2 && controllerJoy.right) {
        boxCanMove = true;
      } else if (posPlayerValue!.value.dx - (sizeBox!.width) <
              (defaultSizeBlok.width - sizeBox!.width - minSize.width / 2) &&
          controllerJoy.left) {
        boxCanMove = true;
      } else if (distDx < 30) boxCanMove = true;
    }

    if (!(moveEnableBox.canMove() && boxCanMove && isPlayerMove)) return;

    if (controllerJoy.up) tempBgPos = tempBgPos.translate(0, stepMove);
    if (controllerJoy.down) tempBgPos = tempBgPos.translate(0, -stepMove);
    if (controllerJoy.left) tempBgPos = tempBgPos.translate(stepMove, 0);
    if (controllerJoy.right) tempBgPos = tempBgPos.translate(-stepMove, 0);

    Offset minOffset = Offset(
      -((widthBox - size!.width).abs()),
      -((heightBox - size!.height).abs()),
    );

    Offset maxOffset = Offset(0, 0);
    // print("as ${moveEnableBox.canMove()} $boxCanMove $isPlayerMove");
    this.posBoxValue?.value =
        moveEnableBox.move(posBoxValue!.value, tempBgPos, minOffset, maxOffset);
    this.posBoxValue?.notifyListeners();
  }

  movePlayer() async {
    Size defaultSizeBlok = Size(col! * sizeBox!.width + border * 2,
        row! * sizeBox!.height + border * 2);

    ControllerJoy controllerJoy = this.controllerJoyValue!.value;
    Offset tempPlayerPos = posPlayerValue!.value;

    double widthBox = defaultSizeBlok.width;
    double heightBox = defaultSizeBlok.height;

    MoveEnable moveEnablePlayer = MoveEnable(
      axis: (controllerJoy.up || controllerJoy.down)
          ? Axis.vertical
          : Axis.horizontal,
    );
    moveEnablePlayer.horizontal = true;
    moveEnablePlayer.vertical = true;

    if (!moveEnablePlayer.canMove()) return false;

    if (controllerJoy.up) tempPlayerPos = tempPlayerPos.translate(0, -stepMove);
    if (controllerJoy.down)
      tempPlayerPos = tempPlayerPos.translate(0, stepMove);
    if (controllerJoy.left)
      tempPlayerPos = tempPlayerPos.translate(-stepMove, 0);
    if (controllerJoy.right)
      tempPlayerPos = tempPlayerPos.translate(stepMove, 0);
    // Este funciona ----___
    //     if (controllerJoy.right)
    // tempPlayerPos = tempPlayerPos.translate(-stepMove, 0);

    int status = calculatePlayerPos(tempPlayerPos, controllerJoy, stepMove);
    if (status < 0) return false;

    Offset minOffset = Offset(0, 0);
    Offset maxOffset = Offset(
      ((widthBox - sizeBox!.width).abs()),
      ((heightBox - sizeBox!.height).abs()),
    );
    // print("movimiento jugador");
    // print("m-jugardor ${this.posPlayerValue!.value} $tempPlayerPos");
    this.posPlayerValue!.value = moveEnablePlayer.move(
        this.posPlayerValue!.value, tempPlayerPos, minOffset, maxOffset);

    // this.posPlayerValue.notifyListeners();
    int indexPlayer = getIndexFromPlayerPos();
    CubeClass cubeCurrent = cubesValue!.value[indexPlayer];

    if (cubeCurrent.powerUp != null && cubeCurrent.type == CubeType.Path) {
      if (cubeCurrent.powerUp == PowerUp.Door) {
        gameEnd = true;

        bool status = await showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              insetPadding: EdgeInsets.all(5),
              title: Text("Juego Terminado"),
              children: [
                Text(" Fin de la partida."),
                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text("Cerrar"))
              ],
            );
          },
        );

        if (status) refreshGame();
      } else {
        powerUps?.value.add(cubeCurrent.powerUp!);
        cubeCurrent.powerUp = null;
      }

      powerUps?.notifyListeners();
      cubesValue?.notifyListeners();
    }

    return true;
  }

  int calculatePlayerPos(
      Offset tempPos, ControllerJoy direction, double stepMove) {
    Offset centerPlayer =
        tempPos.translate(sizeBox!.width / 2, sizeBox!.height / 2);

    try {
      int crow = 0, ccol = 0;

      Offset target = (direction.up || direction.down)
          ? centerPlayer.translate(
              0,
              (direction.up
                      ? -(sizeBox!.height / 2 - stepMove)
                      : sizeBox!.height / 2) -
                  stepMove,
            )
          : centerPlayer.translate(
              (direction.left
                  ? -(sizeBox!.width / 2)
                  : (sizeBox!.width / 2) - stepMove),
              0,
            );

      crow = target.dy ~/ sizeBox!.height;
      ccol = target.dx ~/ sizeBox!.width;

      int index = crow * col! + ccol;

      CubeClass targetC = cubesValue!.value[index];
      bool status = false;

      if (targetC.type == CubeType.Wall || targetC.canOverlap == false)
        return -2;

      if (targetC.type == CubeType.Brick &&
          powerUps?.value
                  .where((element) => element == PowerUp.EnterBrick)
                  .length ==
              0) return -2;

      Offset playerCenter = posPlayerValue!.value
          .translate(sizeBox!.width / 2, sizeBox!.height / 2);

      Offset boxCenter =
          targetC.pos!.translate(sizeBox!.width / 2, sizeBox!.height / 2);

      if (direction.up || direction.down) {
        status = tempPos.dx == targetC.pos?.dx;

        if (!status) {
          if (playerCenter.dx < boxCenter.dx &&
              (playerCenter.dx - boxCenter.dx).abs() < 30) {
            this.posPlayerValue!.value =
                this.posPlayerValue!.value.translate(stepMove, 0);
          } else if (playerCenter.dx > boxCenter.dx &&
              (playerCenter.dx - boxCenter.dx).abs() < 30) {
            this.posPlayerValue!.value =
                this.posPlayerValue!.value.translate(-stepMove, 0);
          }
          this.posPlayerValue!.notifyListeners();
        }
      } else {
        status = tempPos.dy == targetC.pos?.dy;

        if (!status) {
          if (playerCenter.dy < boxCenter.dy &&
              (playerCenter.dy - boxCenter.dy).abs() < 30) {
            this.posPlayerValue!.value =
                this.posPlayerValue!.value.translate(0, stepMove);
          } else if (playerCenter.dy > boxCenter.dy &&
              (playerCenter.dy - boxCenter.dy).abs() < 30) {
            this.posPlayerValue!.value =
                this.posPlayerValue!.value.translate(0, -stepMove);
          }
          this.posPlayerValue!.notifyListeners();
        }
      }
      // print(status);
      return status ? 1 : -1;
    } catch (e) {
      return -1;
    }
  }
}

class BgGroundEffect extends CustomPainter with ChangeNotifier {
  List<CubeClass> blocks = [];
  ui.Image? image;
  List<BomObject>? bomObjects;
  List<PowerUp>? powerUps;

  BgGroundEffect({
    blocks,
    this.bomObjects,
    this.image,
    this.powerUps,
  });

  void update({
    blocks,
    bomObjects,
    image,
    powerUps,
  }) {
    if (blocks != null) this.blocks = blocks;
    if (bomObjects != null) this.bomObjects = bomObjects;
    if (image != null) this.image = image;
    if (powerUps != null) this.powerUps = powerUps;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (this.image != null && this.blocks.length > 0) {
      Paint paint = new Paint()
        ..strokeWidth = 1
        ..color = Colors.green
        ..blendMode = BlendMode.darken;

      Paint paintWallStroke = new Paint()
        ..strokeWidth = 1
        ..color = Colors.black
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.dst;

      Paint paintWall = new Paint()
        ..strokeWidth = 1
        ..color = Colors.black87
        ..style = PaintingStyle.fill;

      Paint paintPath = new Paint()
        ..color = Colors.brown
        ..style = PaintingStyle.fill;

      Path pathWall = new Path();
      Path pathRoad = new Path();

      this.blocks.forEach((element) {
        if (element.type == CubeType.Brick)
          canvas.drawImage(this.image!, element.pos!, paintPath);
        else if (element.type == CubeType.Wall) {
          Path pathWallTemp = new Path();
          pathWallTemp.addPolygon([
            element.pos!,
            element.pos!.translate(element.size!.width, 0),
            element.pos!.translate(element.size!.width, element.size!.height),
            element.pos!.translate(0, element.size!.height),
          ], true);

          pathWall.addPath(pathWallTemp, Offset.zero);
        } else if (element.type == CubeType.Wall) {
          Path pathWallRoute = new Path();
          pathWallRoute.addPolygon([
            element.pos!,
            element.pos!.translate(element.size!.width, 0),
            element.pos!.translate(element.size!.width, element.size!.height),
            element.pos!.translate(0, element.size!.height),
          ], true);

          pathRoad.addPath(pathWallRoute, Offset.zero);
        }
      });

      if (!(this.powerUps == null || this.bomObjects == null)) {
        int boomPower = this
            .powerUps!
            .where((element) => element == PowerUp.BoomArea)
            .length;

        if (bomObjects != null && boomPower > 0) makeBoomEffect(canvas);
      }

      canvas.drawPath(pathWall, paintWall);
      canvas.drawPath(pathWall, paintWallStroke);
      canvas.drawPath(pathRoad, paintWallStroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void makeBoomEffect(Canvas canvas) {
    Paint paintBoom = new Paint()
      ..strokeWidth = 20
      ..blendMode = BlendMode.hardLight
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    Path path = new Path();

    this.bomObjects?.where((element) => element.explode == true).forEach(
      (bomObject) {
        bomObject.boomAreas?.forEach((element) {
          path.addPolygon([
            element,
            element.translate(bomObject.size!.width, 0),
            element.translate(bomObject.size!.width, bomObject.size!.height),
            element.translate(0, bomObject.size!.height),
          ], true);
        });
      },
    );
    canvas.drawPath(path, paintBoom);
  }

  void updateEffect(BomObject temp) {
    this.bomObjects?.where((element) => element == temp).toList()[0] = temp;
    notifyListeners();
  }
}
