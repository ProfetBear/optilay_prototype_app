class MyRoutes {
  //--------- LEVEL 0 ---------
  static const home = '/';
  static const layoutProjectSelector = '/layout_project_selector';
  static const layoutEditor2D = '/layout_editor/:id';
  static const newCanva = '/new_canva';
  static const loadCanva = '/load_canva';

  static const modelSelector3D = '/model_selector';
  static const modelViewer3D = '/model_viewer';

  // Unity routes
  static const simpleUnity = '/simple';
  //--------- SETTINGS ---------
  static const settings = '/settings';
  //--------- PROFILE ---------
  static const userProfile = '/profile';
  static const userDetails = '/profile/details';

  static const changeName = '/profile/profile/change-name';
  //static const userAddress = '/user-address';
  //--------- SIGNUP ---------
  static const signUp = '/sign-up';
  static const verifyEmail = '/sign-up/verify-email';
  //--------- SIGNIN ---------
  static const signIn = '/sign-in';
  static const forgetPassword = '/sign-in/forget-password';
  static const resetPassword = '/sign-in/forget-password/reset';
  //--------- ONBOARDING ---------
  static const onBoarding = '/on-boarding';
  //--------- RANDOM ---------
  static const random = '/random';
}
