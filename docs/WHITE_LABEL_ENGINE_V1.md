# White Label Engine v1

This app now has a local white-label configuration layer in `lib/src/config/white_label_config.dart`.

## What is configurable

- Business identity: app name, display name, short name, tagline, subtitle, location, rating, review count
- Brand assets: logo, app icon, hero background, service placeholders, staff placeholder, profile placeholder
- Brand colors: primary gold palette, background, surface, card, border, text colors
- Contact: phone, WhatsApp, email, Instagram, Facebook, website, address
- Hours and policies: label, weekly summary, detailed hours, cancellation policy text, cancellation window
- Terminology: service, appointment, staff, manager, business profile, gallery, reviews
- Feature flags: staff visibility, staff selection, admin staff management, gallery, reviews, business profile, admin dashboard

## Where the config lives

- Main config: `lib/src/config/white_label_config.dart`
- App entry point: `lib/main.dart`
- Provider wiring: `lib/src/app.dart`

## Current brand

- `WhiteLabelConfig.tresAmigos`

## How to create a new brand later

1. Add a new `WhiteLabelConfig` constant in `white_label_config.dart`.
2. Swap the entry-point assignment in `lib/main.dart`.
3. Replace assets in `assets/branding/`.
4. Update any app-specific copy that is still intentionally hardcoded.

## What should not change yet

- Auth flow
- Reservation flow
- Staff assignment logic
- Admin CRUD behavior
- API payload shapes
- Database schema
- Route structure unless a screen strictly needs it

## Future v2 path

- Move the config source to the backend.
- Expose a small app-config endpoint.
- Load the config at startup and cache it locally.
- Add tenant scoping only after the app can switch brands safely from config.
