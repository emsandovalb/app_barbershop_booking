# Barbershop Booking App

A white-label Flutter app for barbershops. Each build belongs to one business (tenant): customers browse services and professionals and book appointments, and staff manage the day's agenda. All data comes from the [booking_base_api](https://github.com/emsandovalb/booking_base_api) Laravel API.

The same codebase ships as an Android app per business (one Android flavor each), an iOS app, and a web PWA.

## Requirements

- Flutter with Dart `^3.8.0`
- A running instance of `booking_base_api` (local or hosted)

```bash
flutter pub get
flutter test
```

## Build-time configuration

A build is pointed at a business and an API with two `--dart-define` values.

| Define | Required | What it does |
| --- | --- | --- |
| `BUSINESS_SLUG` | Yes, for release builds | The business this build belongs to, e.g. `barberia-tres-amigos`. Sent on every API request as the `X-Business-Slug` header and used to load the business's branding. |
| `API_BASE_URL` | No | Base URL of the API including `/api/v1`, e.g. `https://api.example.com/api/v1`. Trailing slashes are stripped. `API_BASE` is still read as a legacy alias. |

If `API_BASE_URL` is not set, the app falls back to:

- web: `<current origin>/api/v1` (PWA and API served from the same origin)
- Android emulator: `http://10.0.2.2:8000/api/v1`
- everything else: `http://127.0.0.1:8000/api/v1`

If `BUSINESS_SLUG` is missing, a **release** build refuses to start and shows an error screen instead of booting under another business's brand. A debug build falls back to `jc-studio` and logs a warning, so plain `flutter run` keeps working locally.

```bash
# Local development against a local API
flutter run --dart-define=BUSINESS_SLUG=jc-studio

# Against the hosted API
flutter run \
  --dart-define=BUSINESS_SLUG=barberia-tres-amigos \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

## Android flavors

Android has one product flavor per business, in the `business` dimension (`android/app/build.gradle.kts`). A flavor sets the application ID suffix, the launcher name and the launcher icons (`android/app/src/<flavor>/res`). It does **not** set the slug, so always pass the matching `BUSINESS_SLUG`.

| Flavor | Application ID suffix | App name | `BUSINESS_SLUG` |
| --- | --- | --- | --- |
| `barberia` | `.barberia` | Barbería Tres Amigos | `barberia-tres-amigos` |
| `jcstudio` | `.jcstudio` | JC Studio | `jc-studio` |

```bash
flutter run --flavor jcstudio --dart-define=BUSINESS_SLUG=jc-studio

flutter build appbundle --release --flavor barberia \
  --dart-define=BUSINESS_SLUG=barberia-tres-amigos \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Per-flavor icons are generated from `flutter_launcher_icons-<flavor>.yaml`:

```bash
dart run flutter_launcher_icons
```

To add a business as a new flavor, add a `create("<flavor>")` block to `productFlavors`, a `flutter_launcher_icons-<flavor>.yaml`, and regenerate the icons. Release builds are currently signed with the debug key; set up a real signing config before publishing to Play.

## Web (PWA)

Use the build script rather than calling `flutter build web` directly. It refuses to build without a slug and refuses if a `KAPSO_API_KEY` is in the environment, since anything passed through `--dart-define` ends up readable in `main.dart.js`.

```powershell
./scripts/build_production.ps1 -BusinessSlug barberia-tres-amigos
./scripts/build_production.ps1 -BusinessSlug barberia-tres-amigos -ApiBaseUrl https://api.example.com/api/v1
```

Output goes to `build/web`. Omit `-ApiBaseUrl` when the PWA is served from the same origin as the API.

## How branding is loaded

The app's name, colors, logo, contact details, hours and copy come from the API, so a business can change them without a new build.

1. On startup the app renders immediately with a built-in preset for the slug (`WhiteLabelConfig` in `lib/src/config/white_label_config.dart`): `barberia-tres-amigos` and `jc-studio` have their own presets, any other slug gets a generic one. The first frame never shows another business's brand.
2. In the background `WhiteLabelConfigService` (`lib/src/services/white_label_config_service.dart`) fetches the business's config from the API and re-themes the app with it (`BrandTheme`).
3. A successful response is cached in `SharedPreferences` per slug. If the API can't be reached, the last cached config is used instead.

The API exposes the business config at two routes:

- `GET /api/v1/businesses/{slug}/app-config`: the full app config for a business.
- `GET /api/v1/public/businesses/{slug}/config`: the public, sanitized branding payload. This is the one the app currently calls at startup.

When no slug is set at all, the service reads `GET /api/v1/app-config` (the platform default). See [docs/WHITE_LABEL_ENGINE_V1.md](docs/WHITE_LABEL_ENGINE_V1.md) for how `AppConfig` (technical behavior) and `WhiteLabelConfig` (brand) are split.

## Launching a new barbershop

Creating the business, its owner, services, professionals and branding happens on the API side through the Super Admin wizard. Follow the API's runbook: [FIRST_BARBERSHOP_ONBOARDING.md](https://github.com/emsandovalb/booking_base_api/blob/main/docs/FIRST_BARBERSHOP_ONBOARDING.md).

Once the business exists, a build for it only needs its slug:

1. Web: run `build_production.ps1` with the new slug.
2. Android: add a flavor (see above) and build with `--flavor <flavor> --dart-define=BUSINESS_SLUG=<slug>`.

## Project layout

```
lib/
  main.dart                 Reads BUSINESS_SLUG, picks the initial preset, starts the app
  src/app.dart              API base URL resolution, providers, theming
  src/config/               AppConfig and WhiteLabelConfig presets
  src/services/             API client and white-label config service
  src/theme/                BrandTheme (dynamic theme from the API payload)
android/app/src/<flavor>/   Per-business launcher icons
scripts/                    Production web build
docs/                       Design notes
```

Some code from the app's earlier life as a sports-court booking app (grounds, tournaments, teams) is still present behind feature flags.
