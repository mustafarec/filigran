import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

class FontWeightConverter implements JsonConverter<FontWeight, int> {
  const FontWeightConverter();

  @override
  FontWeight fromJson(int json) => FontWeight.values.firstWhere(
        (weight) => weight.index == json,
        orElse: () => FontWeight.w400,
      );

  @override
  int toJson(FontWeight object) => object.index;
}

class ColorConverter implements JsonConverter<Color?, int?> {
  const ColorConverter();

  @override
  Color? fromJson(int? json) => json != null ? Color(json) : null;

  @override
  int? toJson(Color? object) => object?.value;
}

class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter();

  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Offset object) {
    return {
      'dx': object.dx,
      'dy': object.dy,
    };
  }
}

Map<String, dynamic> offsetToJson(Offset offset) => {
      'dx': offset.dx,
      'dy': offset.dy,
    };

Offset offsetFromJson(Map<String, dynamic> json) => Offset(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
