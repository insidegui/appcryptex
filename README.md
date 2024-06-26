# App Cryptex

This includes a template for a research cryptex that installs an app bundle with arbitrary entitlements.

To install the app bundle, run the `install.sh` script with the path to the `.app` bundle as the first argument.

## How does it work?

This project includes an `APP_CRYPTEX_TEMPLATE.dstroot` directory defining the template for a cryptex distribution root.

The template already includes the `appregistrard` daemon, which will call LaunchServices in order to register any apps present inside the `/System/Applications` directory within the cryptex.

The install script takes care of creating a copy of the app cryptex template, changing the name and label of the app registrar daemon to something unique based on the app's bundle ID, exporting the relevant variables then running the commands required to install the cryptex, which in turn installs the app.

Creating a new cryptex for each individual app is better than having a massive cryptex with lots of apps as it allows for faster iteration, since each build/install cycle requires personalizing and installing the cryptex.