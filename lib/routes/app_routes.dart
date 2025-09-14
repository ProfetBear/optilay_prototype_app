import 'package:get/get.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/screens/layout_editor_page.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/screens/new_canva_page.dart';
import 'package:optilay_prototype_app/features/2D_layout_builder/screens/project_selector_page.dart';
import 'package:optilay_prototype_app/features/3D_model_viewer/3D_model_selector.dart';
import 'package:optilay_prototype_app/features/3D_model_viewer/3D_model_viewer.dart';
import 'package:optilay_prototype_app/features/AR_model_viewer/ar_model_selector.dart';
import 'package:optilay_prototype_app/features/AR_model_viewer/ar_model_viewer.dart';
import 'package:optilay_prototype_app/home.dart';
import 'package:optilay_prototype_app/utils/constants/text_strings.dart';
import 'routes.dart';

class AppRoutes {
  static final pages = [
    // TODO on boarding per Ficep Demo
    /*
    GetPage(
      name: MyRoutes.onBoarding,
      page: () => const OnBoardingScreen(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    */
    GetPage(
      name: MyRoutes.home,
      page: () => MyHomePage(title: MyTexts.homeTitle),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),

    // -- Layout Builder Feature
    GetPage(
      name: MyRoutes.layoutProjectSelector,
      page: () => ProjectSelectorPage(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    // todo
    GetPage(
      name: MyRoutes.layoutEditor2D,
      page: () => LayoutEditorPage(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
      name: MyRoutes.newCanva,
      page: () => NewCanvaPage(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),

    GetPage(
      name: MyRoutes.modelSelector3D,
      page: () => ModelSelectorPage(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
    name: MyRoutes.modelSelectorAR,
    page: () => const ARModelSelectorPage(),
    transition: Transition.fadeIn,
    transitionDuration: Duration(milliseconds: 50),
  ),
    GetPage(
  name: MyRoutes.modelViewerAR,
  page: () => ManipulationPage(
    assetPath: Get.arguments?['assetPath'] ?? '',
  ),
  transition: Transition.fadeIn,
  transitionDuration: Duration(milliseconds: 50),
),
    // -- TODO Authentication
    /*
    GetPage(
      name: MyRoutes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
      name: MyRoutes.userProfile,
      page: () => const ProfileScreen(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
      name: MyRoutes.userDetails,
      page: () => const UserDetailsScreen(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
      name: MyRoutes.changeName,
      page: () => const ChangeName(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
      name: MyRoutes.signUp,
      page: () => const SignupScreen(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
      name: MyRoutes.verifyEmail,
      page: () => const VerifyEmailScreen(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
      name: MyRoutes.signIn,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
      name: MyRoutes.forgetPassword,
      page: () => const ForgetPasswordScreen(),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    GetPage(
      name: MyRoutes.resetPassword,
      page: () => ResetPasswordScreen(email: Get.arguments['email']),
      transition: Transition.fadeIn,
      transitionDuration: Duration(milliseconds: 50),
    ),
    */
  ];
}
