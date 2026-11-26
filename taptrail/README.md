# TapTrail

An iPhone app that logs every Apple Pay purchase with **where** you were, **when** (to the second), **how much**, and **how** you paid (which card).

iOS doesn't let apps read Apple Pay purchases directly. Instead, TapTrail adds a **Log Purchase** action to Shortcuts, and a Wallet **Transaction** automation runs it each time you tap to pay. The automation passes in the merchant, amount and card. TapTrail then records:

- the exact time of the tap
- your location (coordinates, plus accuracy)
- the actual store: it searches Apple Maps for the merchant's name near you, so `STARBUCKS #1234` becomes the real Starbucks and its address
- the amount and currency (it reads `$4.50`, `4,50 €`, `£1,234.56` and so on)
- the card you used

Screens: a list grouped by day with daily and monthly totals and search, a map of every purchase, a detail page with a mini map, an "Open in Maps" button and notes, and a Setup tab with step-by-step instructions. You can also add cash purchases by hand. Everything stays on the phone (SwiftData). Nothing is uploaded.

## Run it

You need a Mac with **Xcode 16 or newer** and an iPhone on **iOS 17 or newer**.

1. Open `taptrail/TapTrail.xcodeproj` in Xcode.
2. Click the **TapTrail** target → **Signing & Capabilities** → pick your Apple ID under **Team**. If Xcode complains about the bundle ID, change `com.example.TapTrail` to something unique, e.g. `com.yourname.TapTrail`.
3. Plug in your iPhone, select it at the top of the window, and press **Run** (⌘R). The first time, you need to trust the developer profile on the phone: **Settings → General → VPN & Device Management**.

A free Apple ID works for your own phone, but the app expires after 7 days and you re-run it from Xcode. A paid Apple Developer account ($99/year) gives you a year and TestFlight/App Store access.

## Set up the automation (on the iPhone)

1. Open **Shortcuts** → **Automation** → **+**.
2. Choose **Transaction**. Select your cards and choose **Run Immediately** → **Next**.
3. Choose **New Blank Automation**.
4. Add **Get Current Location**.
5. Add **Log Purchase** (TapTrail).
6. Set **Merchant** → *Shortcut Input → Merchant*, **Amount** → *Shortcut Input → Amount*, **Card** → *Shortcut Input → Card or Pass*, **Location** → *Current Location*.
7. Tap **Done**, then go buy something.

The same steps are in the app's **Setup** tab.

## Limits

- The Transaction automation fires when you **tap to pay in a store** with your iPhone. Online Apple Pay checkouts may not trigger it.
- Some banks don't send the merchant or amount. The purchase is still logged with the time and place, and you can edit it.
- Location is where your phone was at the moment you tapped, usually accurate to a few meters outdoors and less precise indoors.

## Project layout

```
TapTrail/
  TapTrailApp.swift          app entry + tabs
  Intents/LogPurchaseIntent  the Shortcuts action
  Services/                  location, Apple Maps store lookup, saving
  Model/                     Purchase (SwiftData), amount parsing
  Views/                     list, map, detail, add, setup
Tests/main.swift             amount parser checks (swiftc, see file header)
```

The Xcode project uses folder-synced groups, so new `.swift` files in `TapTrail/` are picked up automatically.
