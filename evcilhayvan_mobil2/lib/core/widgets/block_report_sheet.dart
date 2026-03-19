// lib/core/widgets/block_report_sheet.dart
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/features/social/data/block_report_repository.dart';

/// Call this to show block/report options for a given user.
///
/// [userId]   – Target user's ID
/// [userName] – Used in dialog titles for clarity
Future<void> showBlockReportSheet(
  BuildContext context, {
  required String userId,
  required String userName,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _BlockReportSheet(userId: userId, userName: userName),
  );
}

class _BlockReportSheet extends StatefulWidget {
  final String userId;
  final String userName;

  const _BlockReportSheet({required this.userId, required this.userName});

  @override
  State<_BlockReportSheet> createState() => _BlockReportSheetState();
}

class _BlockReportSheetState extends State<_BlockReportSheet> {
  final _repo = BlockReportRepository();
  bool _loading = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _block() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kullanıcıyı Engelle'),
        content: Text(
            '${widget.userName} adlı kullanıcıyı engellemek istediğinize emin misiniz? Bu kullanıcının ilanlarını artık görmeyeceksiniz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Engelle')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _repo.blockUser(widget.userId);
      if (mounted) Navigator.pop(context);
      _snack('${widget.userName} engellendi.');
    } catch (e) {
      _snack('Engelleme başarısız: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _report() async {
    if (!mounted) return;
    Navigator.pop(context); // close bottom sheet first
    await showDialog(
      context: context,
      builder: (_) => _ReportDialog(userId: widget.userId, userName: widget.userName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.userName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.block, color: Colors.orange),
                title: const Text('Kullanıcıyı Engelle'),
                subtitle: const Text('Bu kullanıcının ilanlarını görmek istemiyorum'),
                onTap: _block,
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: const Text('Şikayet Et'),
                subtitle: const Text('Uygunsuz davranış veya içerik bildir'),
                onTap: _report,
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Vazgeç'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final String userId;
  final String userName;

  const _ReportDialog({required this.userId, required this.userName});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _repo = BlockReportRepository();
  final _descCtrl = TextEditingController();
  String? _selectedReason;
  bool _loading = false;

  static const _reasons = [
    ('spam', 'Spam'),
    ('harassment', 'Taciz veya zorbalık'),
    ('inappropriate_content', 'Uygunsuz içerik'),
    ('fake_profile', 'Sahte profil'),
    ('other', 'Diğer'),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lütfen bir neden seçin.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.reportUser(widget.userId, _selectedReason!,
          description: _descCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şikayetiniz alındı, teşekkürler.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.userName} Şikayet Et'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Şikayet nedeni:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._reasons.map(
              (r) => RadioListTile<String>(
                title: Text(r.$2),
                value: r.$1,
                groupValue: _selectedReason,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _selectedReason = v),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Ek açıklama (isteğe bağlı)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Şikayet Et'),
        ),
      ],
    );
  }
}
