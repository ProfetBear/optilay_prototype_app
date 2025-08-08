import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optilay_prototype_app/general_bindings.dart';
import 'package:optilay_prototype_app/utils/helpers/helper_functions.dart';
import 'routes/app_routes.dart';
import 'routes/routes.dart';
import 'utils/constants/text_strings.dart';
import 'utils/theme/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: MyTexts.appName,
      themeMode:
          MyHelperFunctions.isDarkMode(context)
              ? ThemeMode.dark
              : ThemeMode.light,
      theme: MyAppTheme.lightTheme,
      darkTheme: MyAppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialBinding: GeneralBindings(),
      getPages: AppRoutes.pages,
      initialRoute: MyRoutes.home,
    );
  }
}
