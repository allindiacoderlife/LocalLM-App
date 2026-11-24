import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/ui.dart';
import '../services/phone_cluster_service.dart';

class ClusterView extends ConsumerStatefulWidget {
  const ClusterView({super.key});

  @override
  ConsumerState<ClusterView> createState() => _ClusterViewState();
}

class _ClusterViewState extends ConsumerState<ClusterView> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '50052');

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _scanQrCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) {
        return SizedBox(
          height: 450,
          child: Column(
            children: [
              AppBar(
                title: const Text('Scan Worker QR Code'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final raw = barcode.rawValue;
                      if (raw != null && (raw.startsWith('locallm://worker') || raw.startsWith('privatelm://worker'))) {
                        final uri = Uri.tryParse(raw);
                        final host = uri?.queryParameters['host'];
                        final port = int.tryParse(uri?.queryParameters['port'] ?? '50052') ?? 50052;
                        if (host != null) {
                          ref.read(phoneClusterProvider.notifier).addWorker(host, port);
                          Navigator.of(ctx).pop();
                          showToast(context, 'Connected', 'Connected to worker node: $host:$port', tone: ToastTone.success);
                          break;
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEnterIpDialog() {
    showAppSheet<void>(
      context,
      title: 'Enter Worker IP',
      subtitle: 'Connect to a worker phone on your local Wi-Fi.',
      builder: (ctx) => Column(
        children: [
          AppField(
            label: 'Worker IP Address',
            child: TextField(
              controller: _ipController,
              decoration: appInputDecoration(ctx, hint: '192.168.1.100'),
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Port',
            child: TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: appInputDecoration(ctx, hint: '50052'),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Connect',
            onPressed: () {
              final ip = _ipController.text.trim();
              final port = int.tryParse(_portController.text.trim()) ?? 50052;
              if (ip.isNotEmpty) {
                ref.read(phoneClusterProvider.notifier).addWorker(ip, port);
                Navigator.pop(ctx);
                showToast(context, 'Connected', 'Connected to worker: $ip:$port', tone: ToastTone.success);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final clusterState = ref.watch(phoneClusterProvider);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: appScreenBar(context, title: 'Phone cluster', showBack: true),
      body: ListView(
        padding: kPagePadding,
        children: [
          // ── Segmented Control: [ Off | Master | Worker ] (Screenshots 7 & 8) ──
          AppSegmented<ClusterRole>(
            items: const [
              (ClusterRole.off, 'Off'),
              (ClusterRole.master, 'Master'),
              (ClusterRole.worker, 'Worker'),
            ],
            selected: clusterState.role,
            onChanged: (role) async {
              if (role == clusterState.role) return;
              if (role == ClusterRole.worker) {
                await ref.read(phoneClusterProvider.notifier).startWorkerNode();
              } else if (clusterState.role == ClusterRole.worker) {
                await ref.read(phoneClusterProvider.notifier).stopWorkerNode();
              }

              if (role == ClusterRole.master) {
                ref.read(phoneClusterProvider.notifier).setRole(ClusterRole.master);
              } else if (role == ClusterRole.off) {
                ref.read(phoneClusterProvider.notifier).setRole(ClusterRole.off);
              }
            },
          ),
          const SizedBox(height: 16),

          // ── ROLE: OFF (Screenshot 8) ──
          if (clusterState.role == ClusterRole.off) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.hub_outlined, size: 20, color: t.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Run models too big for one phone by sharing the work across phones on the same Wi-Fi.',
                          style: t.caption.copyWith(color: t.text.withValues(alpha: 0.9)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Master: the phone you chat on. It runs the model.',
                          style: t.caption,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Worker: a phone that lends its memory to the master.',
                          style: t.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── ROLE: MASTER (Screenshot 7) ──
          if (clusterState.role == ClusterRole.master) ...[
            PrimaryButton(
              label: "Scan a worker's QR code",
              icon: Icons.qr_code_scanner_rounded,
              onPressed: _scanQrCode,
            ),
            const SizedBox(height: 20),

            SectionHeader('Workers (${clusterState.connectedWorkers.length})'),
            if (clusterState.connectedWorkers.isEmpty) ...[
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: t.fill),
                        child: Icon(Icons.devices_other_rounded, size: 26, color: t.muted),
                      ),
                      const SizedBox(height: 14),
                      Text('No workers yet', style: t.bodyStrong),
                      const SizedBox(height: 4),
                      Text(
                        'On each other phone, open Phone cluster, choose Worker, then scan the QR code it shows.',
                        textAlign: TextAlign.center,
                        style: t.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              AppGroup(
                dividerIndent: 60,
                children: [
                  for (final w in clusterState.connectedWorkers)
                    AppRow(
                      icon: Icons.smartphone_rounded,
                      title: '${w.host}:${w.port}',
                      subtitle: 'Connected worker node',
                      trailing: IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: t.muted),
                        onPressed: () => ref.read(phoneClusterProvider.notifier).removeWorker(w.host, w.port),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const SectionFootnote(
              'Used the next time you load a GGUF model. If the model fits on this phone you can keep it here, which is faster. If it doesn\'t, the fastest phones get the biggest share and phones that aren\'t needed are left out.',
            ),
            const SizedBox(height: 18),

            const SectionHeader('Other ways to add'),
            Row(
              children: [
                PillButton(
                  label: 'Find nearby',
                  icon: Icons.wifi_tethering_rounded,
                  onTap: () {
                    showToast(context, 'Scanning', 'Looking for nearby LocalLM worker nodes on Wi-Fi...');
                  },
                ),
                const SizedBox(width: 8),
                PillButton(
                  label: 'Enter IP',
                  icon: Icons.payment_rounded,
                  onTap: _showEnterIpDialog,
                ),
              ],
            ),
          ],

          // ── ROLE: WORKER ──
          if (clusterState.role == ClusterRole.worker) ...[
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Worker Active on Port ${clusterState.workerPort}',
                    style: t.bodyStrong,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Local IP: ${clusterState.localIp ?? "Detecting..."}',
                    style: t.caption,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: 'locallm://worker?host=${clusterState.localIp ?? "127.0.0.1"}&port=${clusterState.workerPort}',
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Scan this QR code from your Master phone.',
                    style: t.caption,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
