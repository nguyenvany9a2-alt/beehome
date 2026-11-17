import 'package:flutter/material.dart';

import '../../data/bee_store.dart';
import '../../data/order_actions.dart';

/// Nút thao tác trên từng đơn, tự hiện đúng nút theo vai trò và trạng thái:
/// - Khách: Hủy đơn (khi đơn còn chờ nhận)
/// - Người giúp việc: Nhận đơn -> Bắt đầu làm -> Hoàn thành
class OrderButtons extends StatefulWidget {
  const OrderButtons({super.key, required this.store, required this.order});
  final BeeStore store;
  final RecordData order;

  @override
  State<OrderButtons> createState() => _OrderButtonsState();
}

class _OrderButtonsState extends State<OrderButtons> {
  bool busy = false;

  /// Chạy một thao tác, báo kết quả bằng thanh thông báo dưới màn hình.
  Future<void> run(Future<void> Function() action, String done) async {
    if (busy) return;
    setState(() => busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirmCancel(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hủy đơn này?'),
        content: Text('Đơn $id sẽ bị hủy và không thể khôi phục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await run(() => widget.store.cancelOrder(id), 'Đã hủy đơn $id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final o = widget.order;
    final id = o['id'] as String;
    final status = o['status'];
    final isMine = o['workerId'] == s.uid;

    // Khách: hủy khi chưa ai nhận
    if (s.role == 'customer' &&
        o['customerId'] == s.uid &&
        status == 'pending') {
      return OutlinedButton(
        onPressed: busy ? null : () => confirmCancel(id),
        child: const Text('Hủy đơn'),
      );
    }

    // Người giúp việc: nhận đơn đang chờ
    if (s.role == 'worker' && status == 'pending') {
      return FilledButton(
        onPressed: busy
            ? null
            : () => run(() => s.acceptOrder(id), 'Đã nhận đơn $id'),
        child: const Text('Nhận đơn'),
      );
    }

    // Người giúp việc: bắt đầu làm
    if (s.role == 'worker' && isMine && status == 'accepted') {
      return FilledButton(
        onPressed: busy
            ? null
            : () => run(() => s.startOrder(id), 'Đã bắt đầu đơn $id'),
        child: const Text('Bắt đầu làm'),
      );
    }

    // Người giúp việc: hoàn thành
    if (s.role == 'worker' && isMine && status == 'working') {
      return FilledButton(
        onPressed: busy
            ? null
            : () => run(() => s.completeOrder(id), 'Đã hoàn thành đơn $id'),
        child: const Text('Hoàn thành'),
      );
    }

    // Không có thao tác nào thì không hiện gì
    return const SizedBox.shrink();
  }
}