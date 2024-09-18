import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

// Events
abstract class UUIDMinerEvent {}

class StartMining extends UUIDMinerEvent {
  final String pattern;
  StartMining(this.pattern);
}

class StopMining extends UUIDMinerEvent {}

class UpdateAttempts extends UUIDMinerEvent {
  final int attempts;
  UpdateAttempts(this.attempts);
}

// State
class UUIDMinerState {
  final int attempts;
  final String minedUUID;
  final bool isMining;
  final String currentUUID;  // Add this line

  UUIDMinerState({
    required this.attempts,
    required this.minedUUID,
    required this.isMining,
    required this.currentUUID,  // Add this line
  });

  UUIDMinerState copyWith({
    int? attempts,
    String? minedUUID,
    bool? isMining,
    String? currentUUID,  // Add this line
  }) {
    return UUIDMinerState(
      attempts: attempts ?? this.attempts,
      minedUUID: minedUUID ?? this.minedUUID,
      isMining: isMining ?? this.isMining,
      currentUUID: currentUUID ?? this.currentUUID,  // Add this line
    );
  }
}

// Bloc
class UUIDMinerBloc extends Bloc<UUIDMinerEvent, UUIDMinerState> {
  UUIDMinerBloc() : super(UUIDMinerState(attempts: 0, minedUUID: '', isMining: false, currentUUID: '')) {
    on<StartMining>(_onStartMining);
    on<StopMining>(_onStopMining);
    on<UpdateAttempts>(_onUpdateAttempts);
  }

  final _uuid = Uuid();
  StreamSubscription<void>? _miningSubscription;
  final _attemptsController = StreamController<int>();

  Future<void> _onStartMining(StartMining event, Emitter<UUIDMinerState> emit) async {
    if (state.isMining) return;

    emit(state.copyWith(isMining: true, attempts: 0, minedUUID: '', currentUUID: ''));

    String pattern = event.pattern.toLowerCase();
    
    _miningSubscription = _mineUUIDs(pattern).listen(
      (_) {},
      onDone: () {
        add(StopMining());
      },
    );

    await emit.forEach<int>(
      _attemptsController.stream,
      onData: (attempts) => state.copyWith(attempts: attempts),
    );
  }

  void _onStopMining(StopMining event, Emitter<UUIDMinerState> emit) {
    _miningSubscription?.cancel();
    emit(state.copyWith(isMining: false));
  }

  void _onUpdateAttempts(UpdateAttempts event, Emitter<UUIDMinerState> emit) {
    emit(state.copyWith(attempts: event.attempts));
  }

  Stream<void> _mineUUIDs(String pattern) async* {
    int attempts = 0;
    while (state.isMining) {
      String generatedUUID = _uuid.v4();
      attempts++;

      emit(state.copyWith(attempts: attempts, currentUUID: generatedUUID));  // Update this line

      if (generatedUUID.toLowerCase().contains(pattern)) {
        emit(state.copyWith(minedUUID: generatedUUID));
        break;
      }

      // Yield to the event loop to keep the UI responsive
      yield null;
      await Future.delayed(Duration.zero);
    }
  }

  @override
  Future<void> close() {
    _miningSubscription?.cancel();
    _attemptsController.close();
    return super.close();
  }
}
