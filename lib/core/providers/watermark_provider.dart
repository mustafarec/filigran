import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/watermark_state.dart';

final watermarkNotifierProvider =
    NotifierProvider<WatermarkNotifier, WatermarkState?>(WatermarkNotifier.new);

class WatermarkNotifier extends Notifier<WatermarkState?> {
  @override
  WatermarkState? build() => null;

  void setImage(String imagePath) {
    state = const WatermarkState(imagePath: '').copyWith(imagePath: imagePath);
  }

  void updateWatermarkText(String text) {
    if (state == null) return;
    state = state!.copyWith(watermarkText: text);
  }

  void updateWatermarkPosition(Offset position) {
    if (state == null) return;
    state = state!.copyWith(watermarkPosition: position);
  }

  void updateWatermarkScale(double scale) {
    if (state == null) return;
    state = state!.copyWith(watermarkScale: scale);
  }

  void updateWatermarkOpacity(double opacity) {
    if (state == null) return;
    state = state!.copyWith(watermarkOpacity: opacity);
  }

  // Logo işlemleri
  void setLogo(String logoPath) {
    if (state == null) return;
    state = state!.copyWith(
      logoPath: logoPath,
      isLogoVisible: true,
    );
  }

  void updateLogoPosition(Offset position) {
    if (state == null) return;
    state = state!.copyWith(logoPosition: position);
  }

  void updateLogoScale(double scale) {
    if (state == null) return;
    state = state!.copyWith(logoScale: scale);
  }

  void updateLogoOpacity(double opacity) {
    if (state == null) return;
    state = state!.copyWith(logoOpacity: opacity);
  }

  void toggleLogoVisibility() {
    if (state == null) return;
    state = state!.copyWith(isLogoVisible: !state!.isLogoVisible);
  }

  void removeLogo() {
    if (state == null) return;
    state = state!.copyWith(
      logoPath: null,
      isLogoVisible: false,
    );
  }
}
