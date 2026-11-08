/// Flutter's per-ABI split builds add an offset to the Android version code
/// (armeabi-v7a +1000, arm64-v8a +2000, x86_64 +4000), so build 1 installs as
/// 2001. Show the build number the way pubspec.yaml writes it. This assumes
/// pubspec build numbers stay below 1000.
String displayBuild(String versionCode) {
  final n = int.tryParse(versionCode);
  if (n == null || n < 1000) return versionCode;
  return '${n % 1000}';
}
