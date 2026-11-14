# Local upstream integration and review — November 14, 2026

The integration branch combines fork commit `8948317` (1.1.5) with upstream
`9047697343b25254179cb8d8d1677268856cdc7c` (tag `v1.2.0`, October 20, 2026).
The fresh upstream fetch still has that commit at `master`. Its separate
`fix/issues-23-24` branch remains at `2bf757e` (October 22, 2026).
Package and settings bundle versions are now 1.2.0; both package variants require iOS 15+.

## Integration

- Adopted upstream's page contexts, page/transition coordinators, optimized Lua bridge,
  Lua 5.5.1 submodule, revised effects, and icon row/column/center API.
- Ported the fork's rotation and icon-editing suspension to the new hooks. Suspension
  restores active contexts and does not remove scripts or disable the Lua engine.
- Retained CFPreferences settings access, preference bundle metadata fixes,
  PreferenceLoader staging/layout fallback, and separate native package schemes.
- Kept script/error log paths inside each package's jailbreak root. Native roothide
  uses its supported jbroot APIs, because its Theos explicitly rejects `<libroot.h>`.
- Adopted the property-ownership restoration fix from upstream's experimental branch.
  The rest of that branch (debug logging, simulation harness, stacking/antialiasing work)
  is not integrated.

## Review findings fixed

| Problem | Result |
| --- | --- |
| Cleanup could restore an old transform, position, or alpha over a newer SpringBoard write. | Preserve properties changed externally; use tolerance for Core Animation float rounding. |
| A global pending idle-check flag could prevent a new scrolling session from scheduling cleanup while an old callback was still pending. | Each session schedules its own check; existing session generations reject stale callbacks. |
| Retained Lua handles could dereference released icons after context restore, hierarchy replacement, or entry-buffer growth. | Clear retired/detached entries before releasing views and reject inactive handles. Free retired icon-order arrays, which Lua does not reference. |
| Upstream logs/error notifications still wrote to `/var/mobile`. | Resolve both producer and settings reader under the jailbreak root. Install a mobile-owned log directory with mode 0755. |
| Lua error text was used as a printf format string. | Use a constant `%s` format and handle non-string Lua errors. |
| `dirname` could modify NSString-owned UTF-8 storage. | Derive the directory using NSString instead. |
| Chunks without global references have no `_ENV` upvalue. | Skip environment replacement when the upvalue is absent. |
| Empty effect selection could leave the old Lua state allocated. | Close the previous state before handling an empty list. |
| Malformed effect entries could receive dictionary selectors and crash. | Validate dictionaries and effect-name/directory types before loading. |
| Non-finite Lua transform inputs could reach Core Animation; rotation angle was unchecked. | Reject infinities as well as NaNs and validate the rotation angle. |
| Subtracting one from the minimum Lua integer could overflow during page indexing. | Validate the positive index before converting it to zero-based form. |
| Preference/error notification callbacks could update UIKit or Lua outside the main queue. | Dispatch callbacks onto the main queue with correct CF callback signatures. |
| Formula rows used unspecified dictionary order, and a deleted selected formula could yield an invalid index path. | Sort keys consistently and check NSNotFound. |
| Recycled effect cells could retain an error icon after recovery. | Clear icons for healthy effects and refresh on both error and recovery. |

## Validation

- Rootless build with standard Theos, SDK 15.6, minimum iOS 15.0, arm64 and arm64e.
- Native roothide build with roothide Theos, SDK 16.5, minimum iOS 15.0, arm64 and arm64e.
- `ruby tests/core-regressions.rb`: compiles the production restoration helpers on macOS;
  checks original-value restoration, preservation of external writes, and opacity rounding.
- Lua 5.5.1 host smoke test: 62 bundled effects, five grids/page populations and nine offsets
  = 2,790 scenarios, including portrait/landscape, a partial page, one icon and no icons.
  It models the Lua API and checks script errors/numeric inputs, not Core Animation rendering.
- Package metadata, Mach-O slices/dependencies, PreferenceLoader entries, bundle versions,
  and native roothide binary strings checked after packaging.

Reproduce the effect test on macOS from this directory:

```sh
clang -O2 -DLUA_USE_MACOSX lua/onelua.c -lreadline -o /private/tmp/cylinder-lua55
ruby -e 'files = Dir.glob("scripts/**/*.lua").map { |p| p.delete_prefix("scripts/") }; exec("/private/tmp/cylinder-lua55", "tests/effects-smoke.lua", "scripts", *files)'
```

## Remaining verification and enhancement opportunities

- Device testing is required for portrait/landscape changes during an active swipe,
  repeated multi-icon dragging across pages, folders, widgets, unlock fly-in, app-close
  transitions, respring, and preferences persistence in both jailbreak environments.
- CFPreferences redirection depends on the jailbreak's hooks. Static path scanning and
  packaging checks cannot prove where cfprefsd writes at runtime; verify actual disk
  writes on a roothide device before publishing a release.
- Upstream still uses pooled light-userdata handles. Inactive handles now fail safely,
  but a context slot can be reused later: a custom script caching a handle across
  sessions can observe a different icon. Generation-tagged full userdata would make
  that contract stricter and permit reclaiming retired entry storage.
- The upstream transition coordinator uses private SpringBoard/Core Animation APIs;
  screen-space alignment and stacking must be tested with widgets and other layout tweaks.
  Upstream's unfinished issue #24 work should be evaluated separately after testing.
- Profile frame time on an iPad before further optimization. The upstream bridge already
  batches property writes, caches geometry and metrics, uses registry-reference arrays,
  and enables Lua generational collection; avoid adding per-frame allocations or I/O.
- Error logs are append-only. Bounded log rotation is a useful future change for repeatedly
  failing custom effects, but requires a separate behavior/retention decision.

No remote branch, tag, release or PR is published by this local integration.
