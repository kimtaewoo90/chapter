import 'package:flutter/material.dart';

Route<T> analyticsPageRoute<T>({
  required String name,
  required WidgetBuilder builder,
  bool fullscreenDialog = false,
}) {
  return MaterialPageRoute<T>(
    settings: RouteSettings(name: name),
    fullscreenDialog: fullscreenDialog,
    builder: builder,
  );
}
