import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:optilay_prototype_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // <-- Initialize local storage
  runApp(MyApp());
}
