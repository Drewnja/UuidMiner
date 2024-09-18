import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import 'logic_bloc.dart';
import 'dart:math' show cos, pi, sin;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UUID Miner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => UUIDMinerBloc(),
        child: const UUIDMinerPage(title: 'UUID Miner'),
      ),
    );
  }
}

class UUIDMinerPage extends StatefulWidget {
  const UUIDMinerPage({super.key, required this.title});

  final String title;

  @override
  State<UUIDMinerPage> createState() => _UUIDMinerPageState();
}

class _UUIDMinerPageState extends State<UUIDMinerPage> {
  final TextEditingController _patternController = TextEditingController();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.red[700]!, Colors.red[900]!],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _patternController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Enter UUID pattern',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'e.g., -b1ba- -b00b5-',
                            hintStyle: TextStyle(color: Colors.white30),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        BlocBuilder<UUIDMinerBloc, UUIDMinerState>(
                          builder: (context, state) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: UUIDSlotMachine(uuid: state.currentUUID),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: BlocBuilder<UUIDMinerBloc, UUIDMinerState>(
                      builder: (context, state) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          decoration: BoxDecoration(
                            color: state.isMining ? Colors.red : Colors.amber,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              if (state.isMining) {
                                context.read<UUIDMinerBloc>().add(StopMining());
                              } else {
                                context.read<UUIDMinerBloc>().add(StartMining(_patternController.text));
                              }
                            },
                            child: Text(
                              state.isMining ? 'STOP' : 'SPIN',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: state.isMining ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: BlocBuilder<UUIDMinerBloc, UUIDMinerState>(
                      builder: (context, state) {
                        return AnimatedOpacity(
                          opacity: state.attempts > 0 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            'Attempts: ${state.attempts}',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  BlocConsumer<UUIDMinerBloc, UUIDMinerState>(
                    listener: (context, state) {
                      if (state.minedUUID.isNotEmpty && !state.isMining) {
                        _confettiController.play();
                      }
                    },
                    builder: (context, state) {
                      return Column(
                        children: [
                          Text(
                            'Jackpot UUID:',
                            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            state.minedUUID,
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          if (state.minedUUID.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: state.minedUUID));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('UUID copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow],
              createParticlePath: drawStar,
              minBlastForce: 10,
              maxBlastForce: 100,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow],
              createParticlePath: drawStar,
              minBlastForce: 10,
              maxBlastForce: 100,
            ),
          ),
        ],
      ),
    );
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}

class UUIDSlotMachine extends StatelessWidget {
  final String uuid;

  const UUIDSlotMachine({Key? key, required this.uuid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber[300],
        border: Border.all(color: Colors.amber[700]!, width: 3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: uuid.split('').map((char) {
          return SlotMachineChar(char: char);
        }).toList(),
      ),
    );
  }
}

class SlotMachineChar extends StatelessWidget {
  final String char;

  const SlotMachineChar({Key? key, required this.char}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 50),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return Stack(
            children: [
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(0, -1),
                ).animate(animation),
                child: ValueKey<String>(char) != child.key
                    ? Text(
                        (child as Text).data!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
        child: Text(
          char,
          key: ValueKey<String>(char),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
