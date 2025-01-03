import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'watermark_state.freezed.dart';

@freezed
class WatermarkState with _$WatermarkState {
  const factory WatermarkState({
    required String imagePath,
    String? watermarkText,
    @Default(Offset.zero) Offset watermarkPosition,
    @Default(1.0) double watermarkScale,
    @Default(1.0) double watermarkOpacity,
    String? logoPath,
    @Default(Offset.zero) Offset logoPosition,
    @Default(1.0) double logoScale,
    @Default(1.0) double logoOpacity,
    @Default(true) bool isLogoVisible,
  }) = _WatermarkState;
}
