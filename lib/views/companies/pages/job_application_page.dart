import 'package:flutter/material.dart';
import 'package:seaofsea/services/v1/recruitment_service.dart';

class JobApplicationPage extends StatefulWidget {
  final int companyId;
  final int?
      jobPostId; // pozisyona başvuru opsiyonel (null => genel şirkete başvuru)

  const JobApplicationPage({
    super.key,
    required this.companyId,
    this.jobPostId,
  });

  @override
  State<JobApplicationPage> createState() => _JobApplicationPageState();
}

class _JobApplicationPageState extends State<JobApplicationPage> {
  final TextEditingController _coverCtrl = TextEditingController();
  bool _busy = false;
  int?
      _createdApplicationId; // submit sonrası doldurulur; withdraw için kullanırız

  @override
  void dispose() {
    _coverCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final res = await RecruitmentServiceV1.appSubmit(
        companyId: widget.companyId,
        jobPostId: widget.jobPostId,
        coverLetter:
            _coverCtrl.text.trim().isEmpty ? null : _coverCtrl.text.trim(),
        // cvSnapshot / attachments istersen buraya map/list geçebilirsin
      );

      // normalize
      int? id;
      if (res is Map) {
        id = res['data']?['id'] as int?;
      }
      setState(() => _createdApplicationId = id);
      _snack(id != null ? 'Başvuru gönderildi (#$id)' : 'Başvuru gönderildi');
    } catch (e) {
      _snack('Başvuru hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    final id = _createdApplicationId;
    if (id == null) {
      _snack('You need to create an application first.');
      return;
    }

    setState(() => _busy = true);
    try {
      // Use the "mine" endpoint (candidate self-withdraw)
      await RecruitmentServiceV1.appWithdrawMine(applicationId: id);

      _snack('Application withdrawn (#$id).');

      // (Opsiyonel) UI’yi temizle ya da listeye yönlendir:
      // setState(() => _createdApplicationId = null);
      // Navigator.pushNamed(context, '/my_applications', arguments: {'highlight_id': id});
    } catch (e) {
      _snack('Withdraw failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final jobLabel =
        widget.jobPostId == null ? 'Genel Başvuru' : 'Job #${widget.jobPostId}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Başvuru • $jobLabel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // (İstersen CV snapshot, dosya ekleri için ayrı alanlar ekleyebilirsin)
            TextField(
              controller: _coverCtrl,
              decoration: const InputDecoration(
                labelText: 'Önyazı (opsiyonel)',
                hintText: 'Kısa bir önyazı yazabilirsiniz...',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: const Icon(Icons.send),
                    label: const Text('Başvur'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_busy || _createdApplicationId == null)
                        ? null
                        : _withdraw,
                    icon: const Icon(Icons.undo),
                    label: const Text('Geri Çek'),
                  ),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: CircularProgressIndicator(),
              ),
            if (_createdApplicationId != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Oluşan başvuru ID: $_createdApplicationId'),
              ),
          ],
        ),
      ),
    );
  }
}
