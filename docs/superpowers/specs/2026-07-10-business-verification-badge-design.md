# Business verification badge

## Behavior

The profile header badge reflects verification without adding new UI:

- `APPROVED`: show `BUSINESS` with the existing green verified colors.
- `REJECTED`: show `Rechazado` with the existing red error colors.
- `NONE`, `PENDING`, and unknown values: keep the current status label with amber colors.

The existing Role and Status rows remain unchanged.

## Scope

Change only `_StatusBadge` in `profile_screen.dart` and its widget test. No new component, dependency, or backend change.

## Verification

The widget test must cover approved, rejected, and pending profiles. Run the full Flutter test suite, focused analysis, and a debug APK build.
