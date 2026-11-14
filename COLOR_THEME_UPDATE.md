# Color theme — Electric Blue + Charcoal

Matches the blue launcher icon. Single source of truth:
`lib/utils/managers/color_manager.dart`. Dark mode is the default.

## Brand

| Token | Hex | Use |
|---|---|---|
| `primary` | `#2563EB` | Fills: buttons, progress, selected chips, FAB |
| `primaryDark` | `#1D4ED8` | Pressed state, gradient start |
| `primaryLight` | `#5B9BFF` | Bright blue on always-dark screens (splash) |
| `onMint` | `#FFFFFF` | Text/icons ON a blue fill (5.2:1). Legacy name |
| `primaryText` | `#5B9BFF` dark / `#1D4ED8` light | Blue text/icons on cards and pages |
| `primaryOnDark` | `#93C5FD` | Blue text/icons on dark art (video, blue hero) |
| `inkOnLight` | `#111827` | Text on light fills: white buttons, gold, amber |
| `accent` | `#FF6B4A` | PRs, streaks, calories |
| `premium` | `#F4B03E` | Pro, locks, stars (dark ink on it) |

## Surfaces and text

| Token | Dark | Light |
|---|---|---|
| `background` | `#121314` | `#F5F7FA` |
| `surface` (cards) | `#1C1D1F` | `#FFFFFF` |
| `surfaceDark` (chips) | `#161719` | `#EEF1F6` |
| `surfaceLight` | `#26282B` | `#F8FAFC` |
| `divider` | `#2E3034` | `#E3E7EE` |
| `textPrimary` | `#FFFFFF` | `#18181B` |
| `textSecondary` | `#A1A1AA` | `#52525B` |
| `textTertiary` | `#8E8E96` | `#66666E` |

## Status

| Meaning | Fill | Text (dark / light) |
|---|---|---|
| Success / done | `success #10B981`, `successDark #047857` (white text) | `#34D399` / `#047857` |
| Warning | `warning #F59E0B` (dark text) | `#F4B03E` / `#92400E` |
| Error | `error #EF4444` | `#F87171` / `#EF4444` |
| Info / rest | `info #0EA5E9` (sky, distinct from brand blue) | `#38BDF8` / `#0369A1` |

## Rules

1. `primary` is a fill. It is only 3.3:1 on dark cards, so blue text uses `primaryText`.
2. White text on blue; dark ink (`inkOnLight`) on white, gold, amber and light plates.
   `ColorManager.onColor(bg)` picks the right one automatically.
3. No raw `Color(0xFF…)` / `Colors.amber|red|green|blue|orange` in screens.
   Exceptions: plate colours, badge colours, hero gradient tones.
4. A "done" state is a calm neutral card with a small green pill, not an all-green card.
