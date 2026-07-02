# White Label Engine v1.1

This app has two configuration layers:

## Responsibilities

### `AppConfig`

Use `AppConfig` for technical app behavior:

- API base behavior
- endpoint names
- feature-flag compatibility
- operational app settings

### `WhiteLabelConfig`

Use `WhiteLabelConfig` for business-facing brand concerns:

- identity and naming
- visual identity
- assets
- contact details
- business hours
- policies
- terminology
- niche-facing copy
- brand feature toggles

Do not merge these layers yet. They solve different problems and are intentionally kept separate.

## Current brand presets

- `WhiteLabelConfig.tresAmigos`
- `WhiteLabelConfig.demoSalon`

`tresAmigos` remains the default active config.

## How to create a new brand

1. Add a new `WhiteLabelConfig` constant in `lib/src/config/white_label_config.dart`.
2. Reuse existing assets first, then replace them only if the new brand needs them.
3. Keep the new preset aligned with the existing feature flags unless a change is explicitly needed.
4. Switch the active config in `lib/main.dart` for local validation.

## How to test `demoSalon` locally

In `lib/main.dart`:

```dart
final whiteLabelConfig = WhiteLabelConfig.tresAmigos;
// To test another white-label brand locally:
// final whiteLabelConfig = WhiteLabelConfig.demoSalon;
```

Uncomment the `demoSalon` line to validate the alternate brand locally.

## Screens already config-driven

- splash
- onboarding
- login
- home hero and key promo cards
- business profile hero and business info
- gallery hero and gallery labels
- reviews summary and labels
- admin dashboard hero
- profile business-profile entry

## Screens with remaining demo content

These screens still contain intentional demo/fallback content that was left in place to avoid changing behavior:

- `gallery_page.dart` demo gallery cards
- `reviews_page.dart` demo review list
- `business_profile_page.dart` fallback staff and service lists
- `admin_dashboard_page.dart` fallback reservations, staff, services, and performance data
- `home_tab.dart` fallback service card titles and prices

## v2 plan

- Move white-label source data behind a backend endpoint.
- Load the active brand at startup and cache it locally.
- Add tenant selection only after config switching is stable.
- Gradually reduce screen-local demo copy once all brand presets are proven.

## White Label Engine v2

Version 2 keeps the same single-brand runtime model, but moves the active brand
config behind a public backend endpoint.

### Backend config endpoint

- `GET /api/v1/app-config`
- Returns static Tres Amigos config from `config/white_label.php`
- Includes identity, assets, colors, contact, hours, policies, terminology, and features
- Is public for now and does not require auth

### Flutter startup loading

- App startup still begins with `WhiteLabelConfig.tresAmigos`
- The app then tries to load remote config from `/app-config`
- If the backend responds with valid JSON, the app swaps to that config
- The loaded config is exposed through `Provider<WhiteLabelConfig>`

### Cache behavior

- Raw JSON is cached in `SharedPreferences`
- Cache key: `white_label_config_cache`
- On startup, cached config is loaded before the remote request finishes
- If the network request fails, the cached config stays active

### Fallback behavior

- If remote config is missing, invalid, or unavailable, the app falls back to cache
- If cache is missing or corrupt, the app falls back to `WhiteLabelConfig.tresAmigos`
- Startup does not block on the network
- The app still launches when the backend is offline

### What is still not multi-tenant

- No `tenant_id` has been added to requests
- No tenant switching UI exists
- No per-user brand selection exists
- Reservation, booking, staff, and admin flows remain unchanged

### Future tenant_id plan

- Add `tenant_id` only after config loading is stable in production
- Resolve brand config server-side from tenant metadata
- Keep local presets as offline/bootstrap fallbacks
- Introduce tenant switching only if the product explicitly needs brand-level isolation
