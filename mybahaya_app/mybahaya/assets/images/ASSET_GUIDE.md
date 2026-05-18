# MyBahaya App — Asset Image Guide

Place your images in these exact folders under `assets/images/`:

```
assets/images/
├── logos/                  ← Brand identity
│   ├── logo_primary.svg    ← Main MyBahaya logo (used in splash, nav bar)
│   ├── logo_white.svg      ← White variant for dark backgrounds
│   ├── icon_512.png        ← App icon (Play Store / App Store)
│   ├── icon_192.png        ← Adaptive icon (Android)
│   └── icon_1024.png       ← App Store icon (iOS)
│
├── onboarding/             ← Onboarding carousel illustrations
│   ├── onb_fire.png        ← Fire/emergency illustration (page 1)
│   ├── onb_accident.png    ← Accident illustration (page 2)
│   ├── onb_danger.png      ← Danger/help illustration (page 3)
│   └── onb_community.png   ← Community safety illustration (optional page 4)
│
├── auth/                   ← Authentication screens
│   ├── auth_hero.png       ← Hero illustration on login/signup
│   ├── auth_bg_pattern.png ← Subtle background pattern
│   └── google_logo.svg     ← Google OAuth button icon
│
├── home/                   ← Home dashboard
│   ├── hero_illustration.png   ← Main hero graphic
│   └── status_icons/          ← Status severity icons
│       ├── icon_critical.svg
│       ├── icon_warning.svg
│       └── icon_resolved.svg
│
├── map/                    ← Map screen
│   ├── map_pin_active.svg      ← Active incident pin
│   ├── map_pin_resolved.svg    ← Resolved pin
│   ├── map_pin_user.svg        ← User location pin
│   └── map_placeholder.png     ← Map loading placeholder
│
├── reports/                ← Report submission
│   ├── report_hero.png         ← Report flow illustration
│   ├── camera_placeholder.svg  ← Camera/gallery upload placeholder
│   └── category_icons/
│       ├── icon_theft.svg
│       ├── icon_accident.svg
│       ├── icon_fire.svg
│       └── icon_other.svg
│
├── alerts/                 ← Live alerts
│   ├── alert_placeholder.png   ← Empty state illustration
│   └── severity_icons/
│       ├── sev_critical.svg
│       ├── sev_high.svg
│       ├── sev_moderate.svg
│       └── sev_cleared.svg
│
├── settings/               ← Settings screen
│   ├── settings_hero.png       ← Settings hero illustration
│   ├── profile_placeholder.svg ← Default avatar
│   └── about_bg.png            ← About section background
│
└── common/                 ← Shared UI elements
    ├── pattern_noise.png       ← Subtle noise texture
    ├── bg_wave.svg             ← Wave decoration
    ├── empty_state.svg         ← Global empty state illustration
    └── shimmer_placeholder.svg ← Loading shimmer placeholder
```

**File format guidelines:**
- **Icons/simple graphics** → `.svg` (scalable, tiny file size)
- **Illustrations/photos** → `.png` (raster, high quality)
- **App icons** → `.png` at multiple sizes (512, 192, 1024)
- **Keep each file under 200KB** for performance
- **Name files lowercase with underscores** (e.g. `onb_fire.png`)

**Design spec for images you create/export:**
- Primary brand color: `#B22222` (FireBrick Red)
- Accent glow: `#FF3333` (Red Glow)
- Background: `#1A0A0A` → `#2D1010` (Deep Maroon gradient)
- Card glass effect: `rgba(255,255,255,0.08)` with `blur(20px)`
- Border subtle: `rgba(255,255,255,0.15-0.25)`
- Text: White `#FFFFFF` with opacity levels (100%, 70%, 50%, 35%, 15%)