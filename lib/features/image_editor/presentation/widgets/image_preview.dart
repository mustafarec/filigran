import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../core/providers/watermark_provider.dart';

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
      return const Size(300, 200);
    }

    final double aspectRatio = imageSize.width / imageSize.height;
    double width = containerSize.width;
    double height = containerSize.height;

    if (width / height > aspectRatio) {
      width = height * aspectRatio;
    } else {
      height = width / aspectRatio;
    }

    // NaN kontrolü
    if (width.isNaN || height.isNaN) {
      return const Size(300, 200);
    }

    return Size(width, height);
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

    // Logo boyutları için state
    final logoSizeFuture = useMemoized(
      () => watermarkState?.logoPath != null
          ? _getImageSize(watermarkState!.logoPath!)
          : Future.value(Size.zero),
      [watermarkState?.logoPath],
    );
    final logoSize = useFuture(logoSizeFuture);

    // Animasyon kontrolcüleri
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

    // Pan hareketi için değişkenler
    final isDragging = useState(false);
    final dragStartOffset = useState<Offset>(Offset.zero);
    final elementStartOffset = useState<Offset>(Offset.zero);

    return Center(
      child: ClipRect(
        child: SizedBox(
          width: 800,
          height: 600,
          child: watermarkState == null
              ? const Center(
                  child: Text(
                    'Resim seçmek için + butonuna tıklayın',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (!imageSize.hasData || imageSize.data == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final calculatedImageSize = _calculateImageDimensions(
                      imageSize.data!,
                      Size(constraints.maxWidth, constraints.maxHeight),
                    );

                    // Boyut kontrolü
                    if (calculatedImageSize.width <= 0 ||
                        calculatedImageSize.height <= 0) {
                      return const Center(
                        child: Text('Resim boyutları geçersiz'),
                      );
                    }

                    final textStyle = TextStyle(
                      color: Colors.white.withOpacity(
                          watermarkState.watermarkOpacity == 0
                              ? 0
                              : watermarkState.watermarkOpacity),
                      fontSize: 24 * watermarkState.watermarkScale,
                      height: 1.0,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0.5, 0.5),
                          blurRadius: 1,
                        ),
                      ],
                    );

                    final textSize = watermarkState.watermarkText != null
                        ? _getTextSize(watermarkState.watermarkText!, textStyle)
                        : Size.zero;

                    final imageLeft =
                        (constraints.maxWidth - calculatedImageSize.width) / 2;
                    final imageTop =
                        (constraints.maxHeight - calculatedImageSize.height) /
                            2;

                    // Metin için sınırlar
                    final minTextX = 0.0;
                    final minTextY = 0.0;
                    final maxTextX =
                        calculatedImageSize.width - textSize.width - 15;
                    final maxTextY =
                        calculatedImageSize.height - textSize.height;

                    // Logo için sınırlar
                    final scaledLogoWidth = (logoSize.data?.width ?? 100) *
                        watermarkState.logoScale;
                    final scaledLogoHeight = (logoSize.data?.height ?? 100) *
                        watermarkState.logoScale;
                    final minLogoX = 0.0;
                    final minLogoY = 0.0;
                    final maxLogoX =
                        calculatedImageSize.width - scaledLogoWidth - 15;
                    final maxLogoY =
                        calculatedImageSize.height - scaledLogoHeight;

                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left: imageLeft.isFinite ? imageLeft : 0,
                          top: imageTop.isFinite ? imageTop : 0,
                          width: calculatedImageSize.width,
                          height: calculatedImageSize.height,
                          child: ClipRect(
                            child: Image.file(
                              File(watermarkState.imagePath),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text('Resim yüklenemedi'),
                                );
                              },
                            ),
                          ),
                        ),
                        if (watermarkState.watermarkText != null &&
                            textSize.width > 0 &&
                            textSize.height > 0)
                          Positioned(
                            left: imageLeft +
                                watermarkState.watermarkPosition.dx
                                    .clamp(minTextX, maxTextX),
                            top: imageTop +
                                watermarkState.watermarkPosition.dy
                                    .clamp(minTextY, maxTextY),
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

                                  final delta =
                                      event.position - dragStartOffset.value;
                                  final newPosition = Offset(
                                    (elementStartOffset.value.dx + delta.dx)
                                        .clamp(minTextX, maxTextX),
                                    (elementStartOffset.value.dy + delta.dy)
                                        .clamp(minTextY, maxTextY),
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
                                onPointerCancel: (event) {
                                  isDragging.value = false;
                                  dragStartOffset.value = Offset.zero;
                                  elementStartOffset.value = Offset.zero;
                                  animationController.reverse();
                                  HapticFeedback.lightImpact();
                                },
                                child: Transform.scale(
                                  scale: scaleAnimation,
                                  child: Transform.rotate(
                                    angle: rotationAnimation,
                                    child: Text(
                                      watermarkState.watermarkText!,
                                      style: textStyle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (watermarkState.logoPath != null &&
                            watermarkState.isLogoVisible)
                          Positioned(
                            left: imageLeft +
                                watermarkState.logoPosition.dx
                                    .clamp(minLogoX, maxLogoX),
                            top: imageTop +
                                watermarkState.logoPosition.dy
                                    .clamp(minLogoY, maxLogoY),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.move,
                              child: Listener(
                                onPointerDown: (event) {
                                  isDragging.value = true;
                                  dragStartOffset.value = event.position;
                                  elementStartOffset.value =
                                      watermarkState.logoPosition;
                                  animationController.forward();
                                  HapticFeedback.mediumImpact();
                                },
                                onPointerMove: (event) {
                                  if (!isDragging.value) return;

                                  final delta =
                                      event.position - dragStartOffset.value;
                                  final newPosition = Offset(
                                    (elementStartOffset.value.dx + delta.dx)
                                        .clamp(minLogoX, maxLogoX),
                                    (elementStartOffset.value.dy + delta.dy)
                                        .clamp(minLogoY, maxLogoY),
                                  );

                                  ref
                                      .read(watermarkNotifierProvider.notifier)
                                      .updateLogoPosition(newPosition);
                                },
                                onPointerUp: (event) {
                                  isDragging.value = false;
                                  dragStartOffset.value = Offset.zero;
                                  elementStartOffset.value = Offset.zero;
                                  animationController.reverse();
                                  HapticFeedback.lightImpact();
                                },
                                onPointerCancel: (event) {
                                  isDragging.value = false;
                                  dragStartOffset.value = Offset.zero;
                                  elementStartOffset.value = Offset.zero;
                                  animationController.reverse();
                                  HapticFeedback.lightImpact();
                                },
                                child: Transform.scale(
                                  scale: scaleAnimation,
                                  child: Transform.rotate(
                                    angle: rotationAnimation,
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
                ),
        ),
      ),
    );
  }
}
