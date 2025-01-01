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
    final double aspectRatio = imageSize.width / imageSize.height;
    double width = containerSize.width;
    double height = containerSize.height;

    if (containerSize.width <= 0 || containerSize.height <= 0) {
      return Size(300, 200);
    }

    if (width / height > aspectRatio) {
      width = height * aspectRatio;
    } else {
      height = width / aspectRatio;
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

    // Sürükleme başladığında
    void onDragStart() {
      isDragging.value = true;
      animationController.forward();
      HapticFeedback.mediumImpact();
    }

    // Sürükleme bittiğinde
    void onDragEnd() {
      isDragging.value = false;
      animationController.reverse();
      HapticFeedback.lightImpact();
    }

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
                    if (!imageSize.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final calculatedImageSize = _calculateImageDimensions(
                      imageSize.data!,
                      Size(constraints.maxWidth, constraints.maxHeight),
                    );

                    final textStyle = TextStyle(
                      color: Colors.white.withOpacity(
                          watermarkState.watermarkOpacity == 0
                              ? 0
                              : watermarkState.watermarkOpacity),
                      fontSize: 24 * watermarkState.watermarkScale,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 2,
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

                    final minX = 0.0;
                    final minY = 0.0;
                    final maxX = max(
                        0.0, calculatedImageSize.width - textSize.width - 20);
                    final maxY =
                        max(0.0, calculatedImageSize.height - textSize.height);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: imageLeft,
                          top: imageTop,
                          width: calculatedImageSize.width,
                          height: calculatedImageSize.height,
                          child: Image.file(
                            File(watermarkState.imagePath),
                            fit: BoxFit.fill,
                          ),
                        ),
                        if (watermarkState.watermarkText != null)
                          Positioned(
                            left:
                                imageLeft + watermarkState.watermarkPosition.dx,
                            top: imageTop + watermarkState.watermarkPosition.dy,
                            child: GestureDetector(
                              onPanStart: (details) {
                                onDragStart();
                              },
                              onPanUpdate: (details) {
                                if (!isDragging.value) return;

                                final RenderBox renderBox =
                                    context.findRenderObject() as RenderBox;
                                final localPosition = renderBox
                                    .globalToLocal(details.globalPosition);

                                // Doğrudan pozisyon hesaplama
                                final newPosition = Offset(
                                  (localPosition.dx -
                                          imageLeft -
                                          textSize.width / 2)
                                      .clamp(minX, maxX),
                                  (localPosition.dy -
                                          imageTop -
                                          textSize.height / 2)
                                      .clamp(minY, maxY),
                                );

                                // Pozisyonu güncelle
                                ref
                                    .read(watermarkNotifierProvider.notifier)
                                    .updateWatermarkPosition(newPosition);
                              },
                              onPanEnd: (_) {
                                onDragEnd();
                              },
                              onPanCancel: () {
                                onDragEnd();
                              },
                              child: Transform.scale(
                                scale: scaleAnimation,
                                child: Transform.rotate(
                                  angle: rotationAnimation,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            isDragging.value ? 0.3 : 0.0,
                                          ),
                                          blurRadius: isDragging.value ? 15 : 0,
                                          spreadRadius:
                                              isDragging.value ? 3 : 0,
                                        ),
                                      ],
                                    ),
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
                            left: imageLeft + watermarkState.logoPosition.dx,
                            top: imageTop + watermarkState.logoPosition.dy,
                            child: GestureDetector(
                              onPanStart: (details) {
                                isDragging.value = true;
                                HapticFeedback.mediumImpact();
                              },
                              onPanUpdate: (details) {
                                if (!isDragging.value) return;

                                final RenderBox renderBox =
                                    context.findRenderObject() as RenderBox;
                                final localPosition = renderBox
                                    .globalToLocal(details.globalPosition);

                                // Logo boyutlarını hesapla
                                final scaledLogoWidth =
                                    logoSize.data?.width ?? 100;
                                final scaledLogoHeight =
                                    logoSize.data?.height ?? 100;

                                // Sınırları hesapla
                                final maxX = calculatedImageSize.width -
                                    (scaledLogoWidth *
                                        watermarkState.logoScale);
                                final maxY = calculatedImageSize.height -
                                    (scaledLogoHeight *
                                        watermarkState.logoScale);

                                // Doğrudan pozisyon hesaplama
                                final newPosition = Offset(
                                  (localPosition.dx - imageLeft)
                                      .clamp(0.0, maxX),
                                  (localPosition.dy - imageTop)
                                      .clamp(0.0, maxY),
                                );

                                // Pozisyonu güncelle
                                ref
                                    .read(watermarkNotifierProvider.notifier)
                                    .updateLogoPosition(newPosition);
                              },
                              onPanEnd: (_) {
                                isDragging.value = false;
                                HapticFeedback.lightImpact();
                              },
                              onPanCancel: () {
                                isDragging.value = false;
                              },
                              child: Transform.scale(
                                scale: scaleAnimation,
                                child: Transform.rotate(
                                  angle: rotationAnimation,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            isDragging.value ? 0.3 : 0.0,
                                          ),
                                          blurRadius: isDragging.value ? 15 : 0,
                                          spreadRadius:
                                              isDragging.value ? 3 : 0,
                                        ),
                                      ],
                                    ),
                                    child: Opacity(
                                      opacity: watermarkState.logoOpacity,
                                      child: Image.file(
                                        File(watermarkState.logoPath!),
                                        scale: 1 / watermarkState.logoScale,
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
