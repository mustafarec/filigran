import 'package:flutter/material.dart';

Map<String, dynamic> offsetToJson(Offset offset) {
  return {
    'dx': offset.dx,
    'dy': offset.dy,
  };
}

Offset offsetFromJson(Map<String, dynamic> json) {
  return Offset(
    json['dx'] as double,
    json['dy'] as double,
  );
}
