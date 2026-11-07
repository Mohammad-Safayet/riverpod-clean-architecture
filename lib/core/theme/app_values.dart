/// Spacing, radii, durations and other numbers shared across screens.
abstract final class AppValues {
  static const double padding = 16;
  static const double paddingSmall = 8;
  static const double paddingLarge = 24;
  static const double radius = 12;
  static const double radiusSmall = 8;
  static const double iconSize = 24;
  static const double buttonHeight = 48;

  static const int firstPage = 1;
  static const int defaultPageSize = 20;

  /// Start loading the next page when this many pixels remain below the viewport.
  static const double loadMoreThreshold = 300;

  static const Duration animation = Duration(milliseconds: 250);
}
