class AppConstants {
  const AppConstants._();

  static const appName = 'Nobetci';
  static const defaultZoom = 13.8;
  static const focusZoom = 15.2;
  static const userLocationZoom = 16.2;
  static const minSheetSize = 0.22;
  static const initialSheetSize = 0.34;
  static const maxSheetSize = 0.88;

  // Gesture thresholds
  static const mapDragCollapseThreshold = 16.0;
  static const listDragCollapseThreshold = 22.0;

  // Animation durations
  static const animationFast = Duration(milliseconds: 180);
  static const animationNormal = Duration(milliseconds: 240);
  static const animationSlow = Duration(milliseconds: 280);
}
