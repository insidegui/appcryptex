> Disclaimer: this project is provided for use within the [Apple Security Research Device Program](https://security.apple.com/research-device/), use for any purpose outside of security research is outside the scope of the project, please don't report issues or request features that are not within that scope.

# App Cryptex Template

This includes a template for a research cryptex that installs an app bundle with arbitrary entitlements.

In order for the app to be installed, the [appregistrard](https://github.com/insidegui/appregistrard) cryptex must be installed on the device.

To install the app bundle, run the `install.sh` script with the path to the `.app` bundle as the first argument.

## How does it work?

This project includes an `APP_CRYPTEX_TEMPLATE.dstroot` directory defining the template for a cryptex distribution root.

The template already includes the directory structure expected by the `appregistrard` daemon, which will call LaunchServices in order to register any apps present inside the `System/Applications` directory within the cryptex.

The install script takes care of creating a copy of the app cryptex template, then running the commands required to install the cryptex, which in turn installs the app.

Creating a new cryptex for each individual app is better than having a massive cryptex with lots of apps as it allows for faster iteration, since each build/install cycle requires personalizing and installing the cryptex.

## Why is SpringBoard killing my app?

As of iOS 18, SpringBoard should just launch cryptex apps without any issues, however before iOS 18 SpringBoard would kill apps installed this way due to signature validation issues. Because of that, `appregistrard` officially supports iOS 18 only.

However, if you're on iOS 17 and would like to try to make this work, you'll have to bypass this signature validation in SpringBoard by hooking `-[FBSApplicationInfo type]` to always return `1`, and `-[_FBSMISInterfaceWrapperImpl validateSignatureForPath:options:userInfo:]` to always return `0`. This can easily be done with Frida.

## Learn More

[Check out the readme for appregistrard](https://github.com/insidegui/appregistrard) to learn more about how the app installation can be customized.