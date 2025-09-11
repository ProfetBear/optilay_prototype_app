/// This class contains all the App Text in String formats.
class MyTexts {
  // -- GLOBAL Texts
  static const String and = "e";
  static const String skip = "Salta";
  static const String done = "Ok";
  static const String submit = "Conferma";
  static const String restore = "Ripristina";
  static const String cancel = "Annulla";
  static const String appName = "O'Clock";
  static const String tContinue = "Continua";

  // -- OnBoarding Texts
  static const String onBoardingTitle1 = "Choose your product";
  static const String onBoardingTitle2 = "Select Payment Method";
  static const String onBoardingTitle3 = "Deliver at your door step";

  static const String onBoardingSubTitle1 =
      "Welcome to a World of Limitless Choices - Your Perfect Product Awaits!";
  static const String onBoardingSubTitle2 =
      "For Seamless Transactions, Choose Your Payment Path - Your Convenience, Our Priority!";
  static const String onBoardingSubTitle3 =
      "From Our Doorstep to Yours - Swift, Secure, and Contactless Delivery!";

  // -- Authentication Forms
  static const String firstName = "Nome";
  static const String lastName = "Cognome";
  static const String email = "Email";
  static const String password = "Password";
  static const String newPassword = "Nuova Password";
  static const String username = "Username";
  static const String phoneNo = "Numero di Telefono";
  static const String rememberMe = "Ricordami";
  static const String forgetPassword = "Password dimenticata?";
  static const String signIn = "Accedi";
  static const String createAccount = "Crea Account";
  static const String orSignInWith = "Accedi tramite Google";
  static const String iAgreeTo = "Accetto l'";
  static const String privacyPolicy = "Informativa sulla Privacy";
  static const String termsOfUse = "Termini di Utilizzo";
  static const String resendEmail = "Rinvia Email";

  // -- Authentication Headings
  static const String loginTitle = "O'Clock";
  static const String loginSubTitle = "Own your time";
  static const String loginCallToAction = "Effettua il login";

  static const String signupTitle = "Crea un account";
  static const String forgetPasswordTitle = "Ripristino Password";
  static const String forgetPasswordSubTitle =
      "Inserisci la tua email e ti invieremo un link sicuro per cambiare la password";
  static const String changeYourPasswordTitle =
      "Email con link di reset inviata";
  static const String changeYourPasswordSubTitle =
      "Ti abbiamo inviato un link sicuro per cambiare la password, controlla la tua posta elettronica";
  static const String confirmEmail = "Verifica il tuo indirizzo email!";
  static const String confirmEmailSubTitle =
      "Il tuo account è stato creato! Verifica il tuo indirizzo email per accedere";
  static const String emailNotReceivedMessage =
      "Non hai ricevuto la mail? Controlla la sezione Spam o richiedi un altro invio";
  static const String yourAccountCreatedTitle = "Benvenuto in O'Clock!";
  static const String yourAccountCreatedSubTitle =
      "Il tuo account è stato creato con successo.";

  // -- Home
  static const String homeTitle = "OptiLay Prototype";
  static const String homeAppbarTitle = "OptiLay Prototype";
  static const String homeWelcome = "Benvenuto in OptiLay";
  static const String homeDescription = "Questa è un'applicazione demo";
  static const String home3DViewerButtonTitle = "Catalogo 3D AR";
  static const String home3DViewerButtonDesc =
      "Visualizza parco macchine in 3D e realtà aumentata.";
  static const String homeCanvaManagerButtonTitle = "Layout Builder";
  static const String homeCanvaManagerButtonDesc =
      "Accelera le tue opportunità con layout preliminari.";

  // -- Project Selector
  static const String projectSelectorTitle = "Layout Builder";
  static const String projectSelectorHeader = "Cosa vuoi fare?";
  static const String projectSelectorNewCanvaDesc =
      "Inizia un nuovo progetto da zero.";
  static const String newProjectHeader = "Nome del Progetto";
  static const String newProjectHint =
      "Es. Nome del Cliente - Modello Macchina";

  static const String newProjectConfirm = "Crea Progetto";

  static const String projectSelectorRestoreCanvaTitle = "Archivio Layout";
  static const String projectSelectorRestoreCanvaDesc =
      "Carica un layout da revisionare.";

  // -- Route Titles (optional)
  static const String newCanvaTitle = "Nuovo Layout";
  static const String loadCanvaTitle = "Ripristina Canva";

  // Layout Editor 2D

  static const String layoutViewerTitle = "Layout Viewer";
  static const String layoutEditorTitle = "Layout Editor";
  static const String addMachinery = "Add Machinery";

  // Model Viewer 3D

  static const String modelEditorrTitle = "Layout Editor";
  static const String saw = "Segatrice";
  static const String standardModel = "Modello Standard";
  // Profile
  static const String settingScreenTitle = "Impostazioni";
  static const String profileSettings = "Profilo";
  static const String profileHeader = "I tuoi dati";
  static const String appSettings = "App";
  static const String favouriteActivities = "Attività Preferite";
  static const String favouriteActivitiesSubTitle =
      "Gestisci le tue preferenze";
  static const String notification = "Notifiche";
  static const String notificationSubTitle = "Visualizza i tuoi messaggi";
  static const String privacy = "Privacy";
  static const String privacySubTitle =
      "Gestisci i tuoi dati e account connessi";
  static const String logoutButton = "Logout";

  // Messaggi di Errore

  static const String valuesNotSet =
      "Non hai impostato tutti i valori necessari per filtrare.";
  static String suppliersNotFound(String notFound) {
    return 'Non abbiamo trovato nessuna attività per "$notFound"...';
  }
}
