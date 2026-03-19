// lib/core/widgets/block_report_sheet.dart
import 'package:flutter/material.dart';
import 'package:evcilhayvan_mobil2/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.blockUserTitle),
        content: Text(l10n.blockUserContent(widget.userName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.blockUserAction)),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _repo.blockUser(widget.userId);
      if (mounted) Navigator.pop(context);
      _snack(AppLocalizations.of(context)!.blockUserSuccess(widget.userName));
    } catch (e) {
      _snack(AppLocalizations.of(context)!.blockUserError(e.toString()));
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
    final l10n = AppLocalizations.of(context)!;
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
                title: Text(l10n.blockUserTitle),
                subtitle: Text(l10n.blockUserSubtitle),
                onTap: _block,
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: Text(l10n.reportUserTitle),
                subtitle: Text(l10n.reportUserSubtitle),
                onTap: _report,
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(l10n.cancel),
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

  static const _reasonKeys = [
    'spam',
    'harassment',
    'inappropriate_content',
    'fake_profile',
    'other',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  String _reasonLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'spam':
        return l10n.reportReasonSpam;
      case 'harassment':
        return l10n.reportReasonHarassment;
      case 'inappropriate_content':
        return l10n.reportReasonInappropriate;
      case 'fake_profile':
        return l10n.reportReasonFakeProfile;
      case 'other':
        return l10n.reportReasonOther;
      default:
        return key;
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.reportErrNoReason)));
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.reportUser(widget.userId, _selectedReason!,
          description: _descCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.reportSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.reportDialogTitle(widget.userName)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reportReasonLabel,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._reasonKeys.map(
              (key) => RadioListTile<String>(
                title: Text(_reasonLabel(key, l10n)),
                value: key,
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
              decoration: InputDecoration(
                hintText: l10n.reportDescHint,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(l10n.reportAction),
        ),
      ],
    );
  }
}
