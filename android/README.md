# hg-engine for Android

An Android app that plays hg-engine. It embeds the [melonDS](https://melonds.kuribo64.net/) emulator core and adds a touch-first frontend: both screens, on-screen controls, gamepad and keyboard support, battery-backed saves and savestates.

The app **doesn't include any Nintendo data**. You can ship hg-engine in one of two ways:

| Mode | What goes in the APK | What the player does |
| --- | --- | --- |
| **Patch** (recommended for releases) | `hg-engine.bps`, a patch from a clean HeartGold ROM to your build | Picks their own English (USA) HeartGold ROM once. The app patches it on the device. |
| **Prebuilt** | Nothing | Picks an hg-engine `test.nds` they built themselves |

In patch mode the app keeps a copy of the clean ROM. When you ship an APK with a new patch, the game is re-patched automatically on first launch and the player's save is kept.

## Building

You need: Android Studio, or the Android SDK + NDK 27 + JDK 17.

```sh
# 1. (Optional) bundle your hack as a patch. Run from the repository root after `make`.
make android_patch          # writes android/app/src/main/assets/hg-engine.bps

# 2. Build the APK.
cd android
./gradlew assembleRelease   # app/build/outputs/apk/release/app-release.apk
```

melonDS is downloaded at a pinned commit when the native code is configured. To use a local checkout instead, pass `-PmelonDSDir=/path/to/melonDS`.

Release builds are signed with the debug key unless you set `HGE_KEYSTORE`, `HGE_KEYSTORE_PASSWORD`, `HGE_KEY_ALIAS` and `HGE_KEY_PASSWORD`.

The `android` GitHub Actions workflow runs the native tests and uploads an APK as a build artifact on every change under `android/`. That APK has no patch bundled, so it runs in prebuilt mode.

## Controls

| DS | Touch | Gamepad | Keyboard |
| --- | --- | --- | --- |
| D-pad | Left pad (supports diagonals and sliding) | D-pad / left stick | Arrow keys |
| A / B / X / Y | Right cluster | A / B / X / Y | X / Z / S / A |
| L / R | Shoulder pills | L1 / R1 | Q / W |
| Start / Select | Bottom pills | Start / Select | Enter / Right Shift |
| Stylus | Touch the bottom screen | – | – |
| Menu | `MENU` pill or Back | Home/Mode | Esc |

The touch controls hide automatically once a gamepad is used. You can toggle them from the menu, which also has savestates (3 slots), fast forward and quit.

Saves can be imported from or exported to `.sav` files on the setup screen. They're compatible with melonDS and DeSmuME on desktop.

## Layout

```
android/
├── app/src/main/cpp/        native layer (C++17)
│   ├── emulator.{h,cpp}     owns the melonDS NDS instance, frames, audio, saves, savestates
│   ├── platform_android.cpp melonDS Platform:: hooks (files, threads, logging, save callbacks)
│   ├── bps.{h,cpp}          BPS patch applier with CRC verification
│   ├── jni_bridge.cpp       JNI surface for NativeBridge.kt
│   └── tests/host_tests.cpp host smoke tests (boots a generated test ROM)
├── app/src/main/java/...    Kotlin frontend (no AndroidX dependencies)
└── tools/make_bps.py        patch creator (also applies, for verification)
```

Running the native tests on a desktop:

```sh
cmake -S android/app/src/main/cpp -B build-host -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-host && ./build-host/hge_tests /tmp
```

## Limitations

- Local wireless, Wi-Fi, the microphone and the Pokéwalker IR aren't emulated.
- Rendering uses melonDS's software renderer at native resolution. Upscaling would need a GLES port of melonDS's OpenGL renderer.
- melonDS's JIT is used on arm64 and x86_64. Turn it off on the setup screen if a device has trouble with it.

## License

melonDS is GPL-3.0, and so is any APK that links it. Keep the source of what you distribute available, which this repository does. As with the rest of hg-engine, nothing built from this may be sold or put behind a paywall (see the main README).
