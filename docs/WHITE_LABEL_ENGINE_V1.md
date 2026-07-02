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
