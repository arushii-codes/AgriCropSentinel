import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @homeAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Drop'**
  String get homeAppTitle;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Drop Market'**
  String get appTitle;

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get homeWelcomeBack;

  /// No description provided for @homeNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavHome;

  /// No description provided for @homeNavMyCrops.
  ///
  /// In en, this message translates to:
  /// **'My Crops'**
  String get homeNavMyCrops;

  /// No description provided for @homeNavMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get homeNavMarket;

  /// No description provided for @homeNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeNavProfile;

  /// No description provided for @homeWeatherCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get homeWeatherCardTitle;

  /// No description provided for @homeWeatherCardStatus.
  ///
  /// In en, this message translates to:
  /// **'Partly Cloudy'**
  String get homeWeatherCardStatus;

  /// No description provided for @homeMarketCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Price'**
  String get homeMarketCardTitle;

  /// No description provided for @homeMarketCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wheat (ton)'**
  String get homeMarketCardSubtitle;

  /// No description provided for @homeInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights & Predictions'**
  String get homeInsightsTitle;

  /// No description provided for @homeSoybeanPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Soybean Price'**
  String get homeSoybeanPriceTitle;

  /// No description provided for @homeSoybeanPriceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Predicted to increase by 5%'**
  String get homeSoybeanPriceSubtitle;

  /// No description provided for @homeBlightAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Early Blight Alert'**
  String get homeBlightAlertTitle;

  /// No description provided for @homeBlightAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'High risk in your area for tomatoes.'**
  String get homeBlightAlertSubtitle;

  /// No description provided for @homeChatbotFloatingMessage.
  ///
  /// In en, this message translates to:
  /// **'Get Instant Agriculture Advice'**
  String get homeChatbotFloatingMessage;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find products, farms, and categories'**
  String get homeSearchHint;

  /// No description provided for @homeDeliveriesFree.
  ///
  /// In en, this message translates to:
  /// **'Deliveries 100% Free'**
  String get homeDeliveriesFree;

  /// No description provided for @homePromoDescription.
  ///
  /// In en, this message translates to:
  /// **'Order now and enjoy free delivery on all farming products'**
  String get homePromoDescription;

  /// No description provided for @homeOrderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get homeOrderNow;

  /// No description provided for @homeFreshlyStocked.
  ///
  /// In en, this message translates to:
  /// **'Freshly Stocked'**
  String get homeFreshlyStocked;

  /// No description provided for @homeClearanceProducts.
  ///
  /// In en, this message translates to:
  /// **'Clearance Products'**
  String get homeClearanceProducts;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// No description provided for @homeLocationFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get homeLocationFetching;

  /// No description provided for @homeLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get homeLocationDenied;

  /// No description provided for @homeLocationError.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch location'**
  String get homeLocationError;

  /// No description provided for @productDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetailsTitle;

  /// No description provided for @productDetailsQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity:'**
  String get productDetailsQuantity;

  /// No description provided for @productDetailsBenefitsUsage.
  ///
  /// In en, this message translates to:
  /// **'Benefits & Usage'**
  String get productDetailsBenefitsUsage;

  /// No description provided for @productDetailsUsageInstructions.
  ///
  /// In en, this message translates to:
  /// **'Usage Instructions'**
  String get productDetailsUsageInstructions;

  /// No description provided for @productDetailsKeyBenefits.
  ///
  /// In en, this message translates to:
  /// **'Key Benefits'**
  String get productDetailsKeyBenefits;

  /// No description provided for @productDetailsIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get productDetailsIngredients;

  /// No description provided for @productDetailsCustomerReviews.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get productDetailsCustomerReviews;

  /// No description provided for @productDetailsAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get productDetailsAddToCart;

  /// No description provided for @productDetailsBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get productDetailsBuyNow;

  /// No description provided for @productDetailsPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productDetailsPriceLabel;

  /// No description provided for @productDetailsRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get productDetailsRatingLabel;

  /// No description provided for @productDetailsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get productDetailsBack;

  /// No description provided for @pesticide.
  ///
  /// In en, this message translates to:
  /// **'Pesticides'**
  String get pesticide;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
