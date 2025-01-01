import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/watermark_provider.dart';
import '../widgets/image_preview.dart';
import '../widgets/watermark_controls.dart';

class ImageEditorPage extends HookConsumerWidget {
  const ImageEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filigran Ekle'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Expanded(
            flex: 3,
            child: ImagePreview(),
          ),
          const Expanded(
            flex: 2,
            child: WatermarkControls(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            ref.read(watermarkNotifierProvider.notifier).setImage(image.path);
          }
        },
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }
}
