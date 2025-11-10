Place your launcher icon source here as `app_icon.png`.

Recommended size: 1024x1024 PNG.
After adding the file, generate platform launcher icons:

flutter pub get
flutter pub run flutter_launcher_icons

This will update Android and iOS icon assets.

Optional: Social login icons for the Login page
- google.png
- facebook.png
- apple.png
- faceid.png

Place them in this same folder. They are referenced as
`assets/icons/<name>.png` with graceful fallback if missing.
