import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

enum ClusterRole {
  off,
  master,
  worker,
}

class ClusterState {
  final ClusterRole role;
  final bool isWorkerRunning;
  final String? localIp;
  final int workerPort;
  final List<ClusterWorker> connectedWorkers;
  final String? error;

  ClusterState({
    this.role = ClusterRole.off,
    this.isWorkerRunning = false,
    this.localIp,
    this.workerPort = 50052,
    this.connectedWorkers = const [],
    this.error,
  });

  ClusterState copyWith({
    ClusterRole? role,
    bool? isWorkerRunning,
    String? localIp,
    int? workerPort,
    List<ClusterWorker>? connectedWorkers,
    String? error,
    bool clearError = false,
  }) {
    return ClusterState(
      role: role ?? this.role,
      isWorkerRunning: isWorkerRunning ?? this.isWorkerRunning,
      localIp: localIp ?? this.localIp,
      workerPort: workerPort ?? this.workerPort,
      connectedWorkers: connectedWorkers ?? this.connectedWorkers,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PhoneClusterNotifier extends StateNotifier<ClusterState> {
  PhoneClusterNotifier() : super(ClusterState()) {
    _detectLocalIp();
  }

  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            state = state.copyWith(localIp: addr.address);
            return;
          }
        }
      }
    } catch (_) {}
  }

  void setRole(ClusterRole role) {
    state = state.copyWith(role: role);
  }

  /// Starts this phone as a worker node, lending RAM and CPU to a master phone.
  Future<void> startWorkerNode({int port = 50052}) async {
    try {
      await _detectLocalIp();
      await LlamaCluster.startWorker(port: port);

      state = state.copyWith(
        role: ClusterRole.worker,
        isWorkerRunning: true,
        workerPort: port,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to start worker service: $e');
    }
  }

  /// Stops this phone from serving as a worker node.
  Future<void> stopWorkerNode() async {
    try {
      await LlamaCluster.stopWorker();
      state = state.copyWith(
        role: ClusterRole.off,
        isWorkerRunning: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop worker: $e');
    }
  }

  /// Adds a worker phone to the master phone's pool.
  void addWorker(String host, int port) {
    final existing = state.connectedWorkers.any((w) => w.host == host && w.port == port);
    if (existing) return;

    final worker = ClusterWorker(name: host, host: host, port: port);
    state = state.copyWith(
      role: ClusterRole.master,
      connectedWorkers: [...state.connectedWorkers, worker],
    );
  }

  /// Removes a worker phone from the pool.
  void removeWorker(String host, int port) {
    state = state.copyWith(
      connectedWorkers: state.connectedWorkers
          .where((w) => !(w.host == host && w.port == port))
          .toList(),
    );
    if (state.connectedWorkers.isEmpty) {
      state = state.copyWith(role: ClusterRole.off);
    }
  }
}

final phoneClusterProvider =
    StateNotifierProvider<PhoneClusterNotifier, ClusterState>((ref) {
  return PhoneClusterNotifier();
});
