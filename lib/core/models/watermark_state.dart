import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'converters.dart';

part 'watermark_state.freezed.dart';
part 'watermark_state.g.dart';

@freezed
class WatermarkState with _$WatermarkState {
  const factory WatermarkState({
    required String imagePath,
    @JsonKey(toJson: offsetToJson, fromJson: offsetFromJson)
    @Default(Offset.zero)
    Offset watermarkPosition,
    String? watermarkText,
    @Default(1.0) double watermarkScale,
    @Default(1.0) double watermarkOpacity,
    String? logoPath,
    @JsonKey(toJson: offsetToJson, fromJson: offsetFromJson)
    @Default(Offset.zero)
    Offset logoPosition,
    @Default(1.0) double logoScale,
    @Default(1.0) double logoOpacity,
    @Default(false) bool isLogoVisible,
  }) = _WatermarkState;

  factory WatermarkState.fromJson(Map<String, dynamic> json) =>
      _$WatermarkStateFromJson(json);
}
