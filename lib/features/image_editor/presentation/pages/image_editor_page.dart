import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/providers/watermark_provider.dart';
import '../widgets/image_preview.dart';

class ImageEditorPage extends HookConsumerWidget {
  const ImageEditorPage({super.key});

  Future<void> _saveAndShare(BuildContext context, String imagePath) async {
    try {
      final directory = await getTemporaryDirectory();
      final savedImage = File('${directory.path}/watermarked_image.jpg');
      await File(imagePath).copy(savedImage.path);

      if (context.mounted) {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: null,
              child: const Text(
                'Resim Kaydedildi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            message: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: null,
              child: const Text(
                'Resim başarıyla kaydedildi. Paylaşmak ister misiniz?',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  Share.shareXFiles([XFile(savedImage.path)]);
                },
                child: const Text('Paylaş'),
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
            title: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: null,
              child: const Text(
                'Hata',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            content: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: null,
              child: const Text(
                'Resim kaydedilirken bir hata oluştu.',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
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

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        middle: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: null,
          child: const Text(
            'Filigran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
              letterSpacing: -0.5,
            ),
          ),
        ),
        trailing: watermarkState != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    _saveAndShare(context, watermarkState.imagePath),
                child: const Icon(
                  CupertinoIcons.square_arrow_up,
                  size: 24,
                  color: CupertinoColors.activeBlue,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (watermarkState == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        CupertinoIcons.photo_on_rectangle,
                        size: 48,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: null,
                      child: const Text(
                        'Fotoğrafınıza Filigran Ekleyin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: null,
                      child: const Text(
                        'Fotoğraflarınızı kişiselleştirmek için metin veya logo ekleyin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(25),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          ref
                              .read(watermarkNotifierProvider.notifier)
                              .setImage(image.path);
                        }
                      },
                      child: const Text(
                        'Fotoğraf Seç',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Positioned.fill(
                child: ImagePreview(),
              ),
          ],
        ),
      ),
    );
  }
}
