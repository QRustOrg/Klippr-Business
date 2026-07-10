# Business Verification Badge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show `BUSINESS` in a green profile badge for approved businesses and `Rechazado` in red for rejected businesses without hiding other verification states.

**Architecture:** Keep verification interpretation in the existing `BusinessProfile` getters and change only the private `_StatusBadge` presentation logic. Extend the existing profile widget test with real `ProfileBloc` state and no new dependencies.

**Tech Stack:** Flutter, Dart, flutter_bloc, flutter_test

## Global Constraints

- `APPROVED`: show `BUSINESS` with existing green verified colors.
- `REJECTED`: show `Rechazado` with existing red error colors.
- `NONE`, `PENDING`, and unknown values: retain the current status label with amber colors.
- Keep the existing Role and Status rows unchanged.
- Add no component, dependency, or backend change.

---

### Task 1: Render the verification badge by status

**Files:**
- Modify: `test/profile_business_test.dart`
- Modify: `lib/klippr/profile/presentation/views/profile_screen.dart:381`

**Interfaces:**
- Consumes: `BusinessProfile.isVerified`, `BusinessProfile.statusLabel`, and existing `PromoColors` constants.
- Produces: `_StatusBadge` text and colors; no public API changes.

- [ ] **Step 1: Write failing widget coverage**

Allow `_profile` to receive a status and add widget cases that assert `APPROVED` renders `BUSINESS`, `REJECTED` renders `Rechazado`, and `PENDING` remains `Pendiente`. Inspect the badge container decoration to require green, red, and amber backgrounds respectively.

```dart
import 'package:klippr/klippr/promotions/presentation/views/promo_colors.dart';

BusinessProfile _profile({
  String businessName = 'Klippr Cafe',
  String verificationStatus = 'Pending',
}) {
  return BusinessProfile(
    id: const Id('profile-1'),
    userId: const Id('user-1'),
    businessName: businessName,
    taxId: '20123456789',
    email: 'biz@test.com',
    role: 'BUSINESS',
    verificationStatus: verificationStatus,
    isActive: true,
    createdAt: DateTime.utc(2026, 1),
  );
}

testWidgets('profile badge reflects verification state', (tester) async {
  for (final (status, label, background, foreground) in [
    (
      'Approved',
      'BUSINESS',
      PromoColors.statGreenBg,
      PromoColors.statGreenIcon,
    ),
    ('Rejected', 'Rechazado', const Color(0xFFFFD6D2), PromoColors.errorRed),
    (
      'Pending',
      'Pendiente',
      PromoColors.statAmberBg,
      PromoColors.statAmberIcon,
    ),
  ]) {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ProfileBloc(
              _FakeProfileStore(_profile(verificationStatus: status)),
            ),
          ),
          BlocProvider(create: (_) => PromotionsBloc(_FakePromotionsStore())),
          BlocProvider(create: (_) => AuthBloc(_FakeAuthStore())),
        ],
        child: MaterialApp(
          home: ProfileScreen(analyticsStore: _FakeAnalyticsStore()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final badgeText = find.text(label).first;
    final badge = tester.widget<Container>(
      find.ancestor(of: badgeText, matching: find.byType(Container)).first,
    );
    final decoration = badge.decoration! as BoxDecoration;
    expect(decoration.color, background);
    expect(tester.widget<Text>(badgeText).style?.color, foreground);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }
});
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```powershell
& 'D:\flutterSDK\flutter\bin\flutter.bat' test test/profile_business_test.dart
```

Expected: approved case fails because the badge currently renders `Verificado`; rejected color case fails because the badge currently uses amber.

- [ ] **Step 3: Implement the minimal badge mapping**

In `_StatusBadge.build`, derive rejected from the normalized raw verification value and select label/background/foreground directly:

```dart
final verified = profile.isVerified;
final rejected = profile.verificationStatus?.trim().toLowerCase() == 'rejected';
final label = verified ? 'BUSINESS' : profile.statusLabel;
final background = verified
    ? PromoColors.statGreenBg
    : rejected
    ? const Color(0xFFFFD6D2)
    : PromoColors.statAmberBg;
final foreground = verified
    ? PromoColors.statGreenIcon
    : rejected
    ? PromoColors.errorRed
    : PromoColors.statAmberIcon;
```

Use `label`, `background`, and `foreground` in the existing container and text. Do not change any other widget.

- [ ] **Step 4: Verify GREEN and regression suite**

Run:

```powershell
& 'D:\flutterSDK\flutter\bin\flutter.bat' test test/profile_business_test.dart
& 'D:\flutterSDK\flutter\bin\flutter.bat' test
& 'D:\flutterSDK\flutter\bin\flutter.bat' analyze lib/klippr/profile/presentation/views/profile_screen.dart test/profile_business_test.dart
& 'D:\flutterSDK\flutter\bin\flutter.bat' build apk --debug
```

Expected: all tests pass, focused analysis reports no issues, and the APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/klippr/profile/presentation/views/profile_screen.dart test/profile_business_test.dart docs/superpowers/plans/2026-07-10-business-verification-badge.md
git commit -m "feat(profile): clarify verification badge"
```
