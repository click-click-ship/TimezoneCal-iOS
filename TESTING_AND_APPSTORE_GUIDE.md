# TimezoneCal iOS — Free iPhone Testing & App Store Review Guide

Because you are developing on **Windows** and building a **100% Native Swift / SwiftUI + WidgetKit** iOS app, this guide walks you through **3 zero-cost ways** to test **TimezoneCal** before paying for or submitting to Apple App Store Review.

---

## Step 1: Instant Interactive Testing on Windows (or iPhone Safari)

Before running a cloud Xcode compile, you can immediately test the complete UX, Apple Calendar week/month scrubbing, Auto Day/Night mode, Golden Hours overlap detector, Smart DST alerts, and all 4 WidgetKit layouts using the included simulator:

1. Open [`PreviewSimulator/index.html`](./PreviewSimulator/index.html) in Chrome, Edge, or Safari.
2. **Try these flows:**
   - **Tap any city card** (e.g., London or Tokyo) to make it the active **Reference Timezone**, then drag the bottom slider or click any hour cell on the 24-hour World Time Buddy band.
   - Click **✨ Golden Hours — Jump** above the slider to snap to the best meeting window where all cities in your group are awake.
   - Click **📅 November 2026 ▾** in the header and click **⚡ Test Jul 15 / Mar 18 DST Shift** to see the **Smart Daylight Saving Shift** warning banner appear automatically.
   - Switch to the **Widgets (4)** tab at the bottom to test all 4 iOS widgets (including the interactive `-1h` / `Now` / `+1h` buttons on the 6-Hour Timeline Strip).

> [!TIP]
> **Quick Free iPhone Web-App Test:**
> If you host `PreviewSimulator/index.html` or open it over your local Wi-Fi on your iPhone in Safari and tap **Share → Add to Home Screen**, it launches full-screen like a native iOS app!

---

## Step 2: Free Native `.ipa` Build + Free iPhone Testing App (No Mac & No $99 Fee Required)

To install the compiled **SwiftUI + WidgetKit** native app (`TimezoneCal.ipa`) onto your physical iPhone for **$0** from Windows:

### Part A — Compile the Native `.ipa` Automatically on GitHub's Free macOS Cloud
We have already configured [`project.yml`](./project.yml) (`XcodeGen`) and [`.github/workflows/ios-build.yml`](./.github/workflows/ios-build.yml).

1. Create a free repository on [GitHub](https://github.com) and push this `TimezoneCal iOS` folder to it.
2. Click the **Actions** tab in your GitHub repository.
3. GitHub's free `macos-14` runner will automatically:
   - Run `xcodegen generate` to create `TimezoneCal.xcodeproj` (wiring both `TimezoneCal` and `TimezoneCalWidgets`).
   - Compile the native Swift 5.10 / iOS 17+ app and WidgetKit extension.
   - Produce a downloadable artifact named **`TimezoneCal-Unsigned-IPA`** (`TimezoneCal-Unsigned.ipa`).

### Part B — Install on Your iPhone Using a Free Testing App on Windows
Choose either of the two most popular free iOS sideloading / testing tools for Windows (both work with a **free standard Apple ID**—no $99 Developer Program required):

#### Option 1: Sideloadly (Fastest 2-Minute Setup on Windows)
1. Download and install **Sideloadly** for Windows from [sideloadly.io](https://sideloadly.io/) (ensure non-Microsoft-Store iTunes & iCloud for Windows are installed as prompted).
2. Plug your iPhone into your Windows PC via USB (and tap **Trust This Computer** on your iPhone).
3. Drag and drop `TimezoneCal-Unsigned.ipa` (downloaded from your GitHub Action) into Sideloadly.
4. Enter your free Apple ID email—Sideloadly signs the `.ipa` with your free Apple personal team certificate and installs **TimezoneCal** directly onto your iPhone!
5. On your iPhone, go to:
   - **Settings → General → VPN & Device Management → [Your Apple ID] → Trust**
   - **Settings → Privacy & Security → Developer Mode → Turn On**

#### Option 2: AltStore / SideStore (Wireless Refresh on iPhone)
1. Install **AltServer for Windows** from [altstore.io](https://altstore.io/).
2. Install the free **AltStore** app onto your iPhone using AltServer.
3. Download `TimezoneCal-Unsigned.ipa` on your iPhone, open the **AltStore** app → **My Apps** → tap **`+`** in the top-left corner, and select `TimezoneCal-Unsigned.ipa`.

---

## Step 3: Submitting to Apple TestFlight & App Store Review

When you are happy with your testing and ready to distribute via **Apple TestFlight** and submit for **App Store Review**:

1. **Enroll in the Apple Developer Program** ($99/year at [developer.apple.com/programs](https://developer.apple.com/programs/)).
2. **Use Codemagic (Free Cloud Mac Tier for App Store Publishing from Windows):**
   - Sign up at [codemagic.io](https://codemagic.io/) (includes 500 free macOS build minutes/month) and connect your GitHub repository.
   - Connect your **App Store Connect API Key** in Codemagic's automatic code-signing wizard (Codemagic automatically creates your iOS Distribution Certificate, `group.com.timezonecal.shared` App Group, and Provisioning Profiles for both `com.timezonecal.TimezoneCal` and `com.timezonecal.TimezoneCal.TimezoneCalWidgets`—no Mac required!).
   - Trigger a build to push directly to **TestFlight**.
3. **Final Pre-Submission Checklist in App Store Connect:**
   - Test all 4 widgets from your TestFlight build on your iPhone Home Screen and Lock Screen.
   - Provide your App Store screenshots (6.7" and 6.1" iPhone sizes), Privacy Policy URL (note: TimezoneCal stores all data locally on-device in `UserDefaults` and collects zero analytics/tracking data, so you can select **"Data Not Collected"** in App Store Privacy!).
   - Click **Submit for Review**.
