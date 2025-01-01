import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../core/providers/watermark_provider.dart';
import 'package:image_picker/image_picker.dart';

class WatermarkControls extends HookConsumerWidget {
  const WatermarkControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watermarkState = ref.watch(watermarkNotifierProvider);
    final textController = useTextEditingController(
      text: watermarkState?.watermarkText ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: textController,
              onChanged: (value) {
                ref
                    .read(watermarkNotifierProvider.notifier)
                    .updateWatermarkText(value);
              },
              decoration: InputDecoration(
                labelText: 'Filigran Metni',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (watermarkState != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Boyut'),
                        SizedBox(
                          height: 40,
                          child: Slider(
                            value: watermarkState.watermarkScale,
                            min: 0.5,
                            max: 3.0,
                            onChanged: (value) {
                              ref
                                  .read(watermarkNotifierProvider.notifier)
                                  .updateWatermarkScale(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saydamlık'),
                        SizedBox(
                          height: 40,
                          child: Slider(
                            value: watermarkState.watermarkOpacity,
                            min: 0.1,
                            max: 1.0,
                            onChanged: (value) {
                              ref
                                  .read(watermarkNotifierProvider.notifier)
                                  .updateWatermarkOpacity(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: watermarkState == null
                    ? null
                    : () {
                        // TODO: Resmi kaydet
                      },
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Logo Kontrolleri
            if (watermarkState != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          ref
                              .read(watermarkNotifierProvider.notifier)
                              .setLogo(image.path);
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Logo Seç'),
                    ),
                  ),
                  if (watermarkState.logoPath != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        ref
                            .read(watermarkNotifierProvider.notifier)
                            .toggleLogoVisibility();
                      },
                      icon: Icon(
                        watermarkState.isLogoVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref
                            .read(watermarkNotifierProvider.notifier)
                            .removeLogo();
                      },
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ],
              ),
              if (watermarkState.logoPath != null &&
                  watermarkState.isLogoVisible) ...[
                const SizedBox(height: 16),
                Text(
                  'Logo Boyutu: ${(watermarkState.logoScale * 100).toStringAsFixed(0)}%',
                ),
                Slider(
                  value: watermarkState.logoScale,
                  min: 0.1,
                  max: 2.0,
                  onChanged: (value) {
                    ref
                        .read(watermarkNotifierProvider.notifier)
                        .updateLogoScale(value);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Logo Saydamlığı: ${(watermarkState.logoOpacity * 100).toStringAsFixed(0)}%',
                ),
                Slider(
                  value: watermarkState.logoOpacity,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (value) {
                    ref
                        .read(watermarkNotifierProvider.notifier)
                        .updateLogoOpacity(value);
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
