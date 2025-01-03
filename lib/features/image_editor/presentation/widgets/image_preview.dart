import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/watermark_provider.dart';
import '../../../../core/models/watermark_state.dart';

class ImagePreview extends HookConsumerWidget {
  const ImagePreview({super.key});

  Size _getTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  Future<Size> _getImageSize(String imagePath) async {
    final File imageFile = File(imagePath);
    final Uint8List bytes = await imageFile.readAsBytes();
    final ui.Image image = await decodeImageFromList(bytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  Size _calculateImageDimensions(Size imageSize, Size containerSize) {
    if (imageSize.width <= 0 ||
        imageSize.height <= 0 ||
        containerSize.width <= 0 ||
        containerSize.height <= 0) {
      return containerSize;
    }

    final double aspectRatio = imageSize.width / imageSize.height;
    double width = containerSize.width;
    double height = containerSize.height;

    if (width / height > aspectRatio) {
      width = height * aspectRatio;
    } else {
      height = width / aspectRatio;
    }

    if (width.isNaN || height.isNaN) {
      return containerSize;
    }

    return Size(width, height);
  }

  double _clamp(double value, double min, double max) {
    if (min > max) return min;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watermarkState = ref.watch(watermarkNotifierProvider);
    final imageSizeFuture = useMemoized(
      () => watermarkState != null
          ? _getImageSize(watermarkState.imagePath)
          : Future.value(Size.zero),
      [watermarkState?.imagePath],
    );
    final imageSize = useFuture(imageSizeFuture);

    final logoSizeFuture = useMemoized(
      () => watermarkState?.logoPath != null
          ? _getImageSize(watermarkState!.logoPath!)
          : Future.value(Size.zero),
      [watermarkState?.logoPath],
    );
    final logoSize = useFuture(logoSizeFuture);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final scaleAnimation = useAnimation(
      Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      ),
    );

    final rotationAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 0.02).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      ),
    );

    final isDragging = useState(false);
    final dragStartOffset = useState<Offset>(Offset.zero);
    final elementStartOffset = useState<Offset>(Offset.zero);
    final isDraggingLogo = useState(false);
    final logoStartOffset = useState<Offset>(Offset.zero);

    // Metin merkez pozisyonu
    useEffect(() {
      if (watermarkState?.watermarkText != null &&
          watermarkState!.watermarkPosition == Offset.zero &&
          imageSize.hasData &&
          imageSize.data != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = watermarkState.watermarkText;
          if (context != null) {
            final textStyle = TextStyle(
              fontSize: 24 * watermarkState.watermarkScale,
            );
            final textSize = _getTextSize(context, textStyle);

            // Resmin görüntülenen boyutlarını hesapla
            final calculatedImageSize = _calculateImageDimensions(
              imageSize.data!,
              Size(800, 600), // Varsayılan container boyutu
            );

            // Merkez pozisyonunu hesapla
            final center = Offset(
              (calculatedImageSize.width - textSize.width) / 2,
              (calculatedImageSize.height - textSize.height) / 2,
            );

            ref
                .read(watermarkNotifierProvider.notifier)
                .updateWatermarkPosition(center);
          }
        });
      }
      return null;
    }, [watermarkState?.watermarkText, imageSize.data]);

    // Logo merkez pozisyonu
    useEffect(() {
      if (watermarkState?.logoPath != null &&
          watermarkState!.logoPosition == Offset.zero &&
          imageSize.hasData &&
          imageSize.data != null &&
          logoSize.hasData &&
          logoSize.data != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Resmin görüntülenen boyutlarını hesapla
          final calculatedImageSize = _calculateImageDimensions(
            imageSize.data!,
            Size(800, 600), // Varsayılan container boyutu
          );

          // Logo boyutlarını hesapla
          final scaledLogoWidth =
              logoSize.data!.width * watermarkState.logoScale;
          final scaledLogoHeight =
              logoSize.data!.height * watermarkState.logoScale;

          // Merkez pozisyonunu hesapla
          final center = Offset(
            (calculatedImageSize.width - scaledLogoWidth) / 2,
            (calculatedImageSize.height - scaledLogoHeight) / 2,
          );

          ref
              .read(watermarkNotifierProvider.notifier)
              .updateLogoPosition(center);
        });
      }
      return null;
    }, [watermarkState?.logoPath, imageSize.data, logoSize.data]);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (watermarkState == null) {
          return const Center(
            child: Text(
              'Resim seçmek için + butonuna tıklayın',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 16,
              ),
            ),
          );
        }

        if (!imageSize.hasData || imageSize.data == null) {
          return const Center(
            child: CupertinoActivityIndicator(),
          );
        }

        final calculatedImageSize = _calculateImageDimensions(
          imageSize.data!,
          Size(constraints.maxWidth, constraints.maxHeight),
        );

        if (calculatedImageSize.width <= 0 || calculatedImageSize.height <= 0) {
          return const Center(
            child: Text(
              'Resim boyutları geçersiz',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 16,
              ),
            ),
          );
        }

        // Metin boyutunu resmin boyutuna göre sınırla
        final maxTextScale = (calculatedImageSize.width * 0.8) / 24;
        final clampedTextScale =
            _clamp(watermarkState.watermarkScale, 0.5, maxTextScale);

        final textStyle = TextStyle(
          color: CupertinoColors.white.withOpacity(
              watermarkState.watermarkOpacity == 0
                  ? 0
                  : watermarkState.watermarkOpacity),
          fontSize: 24 * clampedTextScale,
          height: 1.0,
          shadows: [
            Shadow(
              color: CupertinoColors.black.withOpacity(0.5),
              offset: const Offset(0.5, 0.5),
              blurRadius: 1,
            ),
          ],
        );

        final textSize = watermarkState.watermarkText != null
            ? _getTextSize(watermarkState.watermarkText!, textStyle)
            : Size.zero;

        // Resmin ekrandaki konumunu hesapla
        final imageLeft =
            (constraints.maxWidth - calculatedImageSize.width) / 2;
        final imageTop = 0.0;

        // Metin için sınırları hesapla
        final minTextX = 0.0;
        final minTextY = 0.0;
        final maxTextX = calculatedImageSize.width - textSize.width - 15;
        final maxTextY = calculatedImageSize.height - textSize.height;

        // Eğer metin pozisyonu henüz ayarlanmamışsa, merkeze yerleştir
        if (watermarkState.watermarkPosition == Offset.zero &&
            watermarkState.watermarkText != null) {
          Future.microtask(() {
            final center = Offset(
              (calculatedImageSize.width - textSize.width) / 2,
              (calculatedImageSize.height - textSize.height) / 2,
            );
            ref
                .read(watermarkNotifierProvider.notifier)
                .updateWatermarkPosition(center);
          });
        }

        // Logo için boyutları hesapla ve sınırla
        final maxLogoScale =
            (calculatedImageSize.width * 0.5) / (logoSize.data?.width ?? 100);
        final clampedLogoScale =
            _clamp(watermarkState.logoScale, 0.1, maxLogoScale);

        final scaledLogoWidth =
            (logoSize.data?.width ?? 100) * clampedLogoScale;
        final scaledLogoHeight =
            (logoSize.data?.height ?? 100) * clampedLogoScale;
        final minLogoX = 0.0;
        final minLogoY = 0.0;
        final maxLogoX = calculatedImageSize.width - scaledLogoWidth - 15;
        final maxLogoY = calculatedImageSize.height - scaledLogoHeight;

        // Eğer logo pozisyonu henüz ayarlanmamışsa, merkeze yerleştir
        if (watermarkState.logoPosition == Offset.zero &&
            watermarkState.logoPath != null) {
          Future.microtask(() {
            final center = Offset(
              (calculatedImageSize.width - scaledLogoWidth) / 2,
              (calculatedImageSize.height - scaledLogoHeight) / 2,
            );
            ref
                .read(watermarkNotifierProvider.notifier)
                .updateLogoPosition(center);
          });
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Ana resim
            Positioned(
              left: imageLeft,
              top: imageTop,
              width: calculatedImageSize.width,
              height: calculatedImageSize.height,
              child: Image.file(
                File(watermarkState.imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Resim yüklenemedi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Alt düzenleme menüsü
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Metin Düğmesi
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) =>
                              _buildTextControls(context, ref, watermarkState),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: watermarkState.watermarkText != null
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemBackground,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              CupertinoIcons.textformat,
                              color: watermarkState.watermarkText != null
                                  ? CupertinoColors.white
                                  : CupertinoColors.activeBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Metin',
                            style: TextStyle(
                              fontSize: 12,
                              color: watermarkState.watermarkText != null
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Logo Düğmesi
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) =>
                              _buildLogoControls(context, ref, watermarkState),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: watermarkState.logoPath != null
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemBackground,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              CupertinoIcons.photo,
                              color: watermarkState.logoPath != null
                                  ? CupertinoColors.white
                                  : CupertinoColors.activeBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Logo',
                            style: TextStyle(
                              fontSize: 12,
                              color: watermarkState.logoPath != null
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filigran metni
            if (watermarkState.watermarkText != null &&
                textSize.width > 0 &&
                textSize.height > 0)
              Positioned(
                left: imageLeft +
                    _clamp(watermarkState.watermarkPosition.dx, minTextX,
                        maxTextX),
                top: imageTop +
                    _clamp(watermarkState.watermarkPosition.dy, minTextY,
                        maxTextY),
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: Listener(
                    onPointerDown: (event) {
                      isDragging.value = true;
                      dragStartOffset.value = event.position;
                      elementStartOffset.value =
                          watermarkState.watermarkPosition;
                      animationController.forward();
                      HapticFeedback.mediumImpact();
                    },
                    onPointerMove: (event) {
                      if (!isDragging.value) return;
                      final delta = event.position - dragStartOffset.value;
                      final newPosition = Offset(
                        _clamp(elementStartOffset.value.dx + delta.dx, minTextX,
                            maxTextX),
                        _clamp(elementStartOffset.value.dy + delta.dy, minTextY,
                            maxTextY),
                      );
                      ref
                          .read(watermarkNotifierProvider.notifier)
                          .updateWatermarkPosition(newPosition);
                    },
                    onPointerUp: (event) {
                      isDragging.value = false;
                      dragStartOffset.value = Offset.zero;
                      elementStartOffset.value = Offset.zero;
                      animationController.reverse();
                      HapticFeedback.lightImpact();
                    },
                    child: Transform.scale(
                      scale: isDragging.value ? scaleAnimation : 1.0,
                      child: Transform.rotate(
                        angle: isDragging.value ? rotationAnimation : 0,
                        child: Text(
                          watermarkState.watermarkText!,
                          style: textStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Logo
            if (watermarkState.logoPath != null && watermarkState.isLogoVisible)
              Positioned(
                left: imageLeft +
                    _clamp(watermarkState.logoPosition.dx, minLogoX, maxLogoX),
                top: imageTop +
                    _clamp(watermarkState.logoPosition.dy, minLogoY, maxLogoY),
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: Listener(
                    onPointerDown: (event) {
                      isDraggingLogo.value = true;
                      dragStartOffset.value = event.position;
                      logoStartOffset.value = watermarkState.logoPosition;
                      animationController.forward();
                      HapticFeedback.mediumImpact();
                    },
                    onPointerMove: (event) {
                      if (!isDraggingLogo.value) return;
                      final delta = event.position - dragStartOffset.value;
                      final newPosition = Offset(
                        _clamp(logoStartOffset.value.dx + delta.dx, minLogoX,
                            maxLogoX),
                        _clamp(logoStartOffset.value.dy + delta.dy, minLogoY,
                            maxLogoY),
                      );
                      ref
                          .read(watermarkNotifierProvider.notifier)
                          .updateLogoPosition(newPosition);
                    },
                    onPointerUp: (event) {
                      isDraggingLogo.value = false;
                      dragStartOffset.value = Offset.zero;
                      logoStartOffset.value = Offset.zero;
                      animationController.reverse();
                      HapticFeedback.lightImpact();
                    },
                    child: Transform.scale(
                      scale: isDraggingLogo.value ? scaleAnimation : 1.0,
                      child: Transform.rotate(
                        angle: isDraggingLogo.value ? rotationAnimation : 0,
                        child: Opacity(
                          opacity: watermarkState.logoOpacity,
                          child: Image.file(
                            File(watermarkState.logoPath!),
                            width: scaledLogoWidth,
                            height: scaledLogoHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTextControls(
      BuildContext context, WidgetRef ref, WatermarkState state) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            placeholder: 'Filigran metni girin',
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
              border: null,
            ),
            style: const TextStyle(
              color: CupertinoColors.black,
              fontSize: 16,
            ),
            placeholderStyle: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 16,
            ),
            onChanged: (value) {
              ref
                  .read(watermarkNotifierProvider.notifier)
                  .updateWatermarkText(value);
            },
            cursorColor: CupertinoColors.activeBlue,
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            icon: CupertinoIcons.textformat_size,
            value: state.watermarkScale,
            onChanged: (value) {
              ref
                  .read(watermarkNotifierProvider.notifier)
                  .updateWatermarkScale(value);
            },
            min: 0.5,
            max: 3.0,
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            icon: CupertinoIcons.circle_lefthalf_fill,
            value: state.watermarkOpacity,
            onChanged: (value) {
              ref
                  .read(watermarkNotifierProvider.notifier)
                  .updateWatermarkOpacity(value);
            },
            min: 0.0,
            max: 1.0,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoControls(
      BuildContext context, WidgetRef ref, WatermarkState state) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  final picker = ImagePicker();
                  final image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    ref
                        .read(watermarkNotifierProvider.notifier)
                        .setLogo(image.path);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.logoPath != null
                            ? CupertinoIcons.photo_fill
                            : CupertinoIcons.photo,
                        size: 18,
                        color: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.logoPath != null ? 'Değiştir' : 'Logo Ekle',
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.logoPath != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ref
                        .read(watermarkNotifierProvider.notifier)
                        .toggleLogoVisibility();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      state.isLogoVisible
                          ? CupertinoIcons.eye_fill
                          : CupertinoIcons.eye_slash_fill,
                      size: 18,
                      color: state.isLogoVisible
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                ),
            ],
          ),
          if (state.logoPath != null) ...[
            const SizedBox(height: 16),
            _buildSliderRow(
              icon: CupertinoIcons.resize,
              value: state.logoScale,
              onChanged: (value) {
                ref
                    .read(watermarkNotifierProvider.notifier)
                    .updateLogoScale(value);
              },
              min: 0.1,
              max: 2.0,
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              icon: CupertinoIcons.circle_lefthalf_fill,
              value: state.logoOpacity,
              onChanged: (value) {
                ref
                    .read(watermarkNotifierProvider.notifier)
                    .updateLogoOpacity(value);
              },
              min: 0.0,
              max: 1.0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: CupertinoColors.systemGrey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CupertinoSlider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
          ),
        ),
      ],
    );
  }
}
