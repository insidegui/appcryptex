# App Cryptex

This includes a template for a research cryptex that installs an app bundle with arbitrary entitlements.

To install the app bundle, run the `install.sh` script with the path to the `.app` bundle as the first argument.

## How does it work?

This project includes an `APP_CRYPTEX_TEMPLATE.dstroot` directory defining the template for a cryptex distribution root.

The template already includes the `appregistrard` daemon, which will call LaunchServices in order to register any apps present inside the `/System/Applications` directory within the cryptex.

The install script takes care of creating a copy of the app cryptex template, changing the name and label of the app registrar daemon to something unique based on the app's bundle ID, exporting the relevant variables then running the commands required to install the cryptex, which in turn installs the app.

Creating a new cryptex for each individual app is better than having a massive cryptex with lots of apps as it allows for faster iteration, since each build/install cycle requires personalizing and installing the cryptex.

## Why is SpringBoard killing my app?

As of iOS 18 (beta 1) SpringBoard should just launch cryptex apps without any issues, however before iOS 18 SpringBoard would kill apps installed this way due to signature validation issues.

If you're on iOS 17, you'll have to bypass this signature validation in SpringBoard by hooking `-[FBSApplicationInfo type]` to always return `1`, and `-[_FBSMISInterfaceWrapperImpl validateSignatureForPath:options:userInfo:]` to always return `0`. This can easily be done with Frida.

## Where's the code for appregistrard?

I'm not ready to make that code available, so you'll have to just trust me for now. Feel free to reverse it in case you're worried about anything nefarious going on. All it does is call a LaunchServices API to register apps inside the cryptex.

Here's the most relevant code snippet, which you may adapt to write your own `appregistrard` if desired:

```swift
let registration: [String: Any] = [
    "Path": <path to application bundle>,
    kCFBundleIdentifierKey as String: <app bundle id>
]

if LSApplicationWorkspace.default.registerApplicationDictionary(registration) {
    // App registered successfully

    notify_post("com.apple.mobile.application_installed")
    notify_post("com.apple.itunesstored.application_installed")
} else {
    // App registration failed
}
```

## Customizing Behavior (optional)

Apps inside the cryptex can customize the way they're installed by adding a `ResearchApp` dictionary to their `Info.plist` file.

Currently, `appregistrard` supports the following properties in the `ResearchApp` dictionary:

- `Removable` (BOOL): set to `YES` to allow the app to be deleted by the user like any normal app
- `WantsContainer` (BOOL): set to `YES` for the daemon to create a data container for the app
