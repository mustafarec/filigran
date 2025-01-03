import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/providers/watermark_provider.dart';

class SaveShareButton extends HookConsumerWidget {
  const SaveShareButton({
    super.key,
    required this.screenshotKey,
  });

  final GlobalKey screenshotKey;

  Future<void> _saveAndShare(BuildContext context) async {
    try {
      // Yükleme göstergesi
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CupertinoActivityIndicator(radius: 15),
        ),
      );

      // Ekran görüntüsü alma
      final boundary = screenshotKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      // Yükleme göstergesini kapat
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Dosya kaydetme izni kontrolü
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('İzin Gerekli'),
              content:
                  const Text('Resmi kaydetmek için dosya erişim izni gerekli.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Tamam'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Dosyayı kaydetme
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/filigran_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        // Paylaşma seçenekleri
        showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);

                  // Yükleme göstergesi
                  showCupertinoDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CupertinoActivityIndicator(radius: 15),
                    ),
                  );

                  try {
                    final pictures = await getExternalStorageDirectory();
                    if (pictures == null)
                      throw Exception('Galeri dizini bulunamadı');

                    final savedFile = File(
                        '${pictures.path}/filigran_${DateTime.now().millisecondsSinceEpoch}.png');
                    await savedFile.writeAsBytes(bytes);

                    if (context.mounted) {
                      Navigator.pop(context); // Yükleme göstergesini kapat

                      // Başarı mesajı
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Başarılı'),
                          content: const Text('Resim galeriye kaydedildi.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Tamam'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Yükleme göstergesini kapat

                      // Hata mesajı
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Hata'),
                          content: Text('Resim kaydedilemedi: $e'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Tamam'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.photo,
                        color: CupertinoColors.activeBlue),
                    SizedBox(width: 8),
                    Text('Galeriye Kaydet'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: 'Filigran eklenmiş resim',
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.share,
                        color: CupertinoColors.activeBlue),
                    SizedBox(width: 8),
                    Text('Paylaş'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDestructiveAction: true,
              child: const Text('İptal'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Hata'),
            content: Text('Bir hata oluştu: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Tamam'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watermarkState = ref.watch(watermarkNotifierProvider);
    final isEnabled = watermarkState != null &&
        (watermarkState.watermarkText.isNotEmpty ||
            (watermarkState.logoPath != null && watermarkState.isLogoVisible));

    if (!isEnabled) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        borderRadius: BorderRadius.circular(22),
        onPressed: () => _saveAndShare(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.floppy_disk, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Kaydet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
