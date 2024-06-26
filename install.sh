#!/bin/zsh

set -e

CURDIR=$(pwd)

APP_PATH=$1

if [ -z "$APP_PATH" ]; then
    echo "Usage: install.sh path/to/app/bundle.app"
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: App bundle not found at ${APP_PATH}"
    exit 1
fi

INFO_PLIST_PATH="${APP_PATH}/Info.plist"

if [ ! -f "$INFO_PLIST_PATH" ]; then
    echo "ERROR: Info.plist file not found at ${INFO_PLIST_PATH}"
    exit 1
fi

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST_PATH" 2>/dev/null)

if [ -z "$BUNDLE_ID" ]; then
    echo "ERROR: App is missing a bundle ID, is CFBundleIdentifier set in ${$INFO_PLIST_PATH}?"
    exit 1
fi

export CRYPTEX_ID="${BUNDLE_ID}.cryptex"
export CRYPTEX_VERSION='1.0.0.0'

echo "App bundle ID is ${BUNDLE_ID}, cryptex ID will be ${CRYPTEX_ID}"

BUILD_DIR="${CURDIR}/build/${BUNDLE_ID}-build"

rm -Rf ${BUILD_DIR} 2>/dev/null || true

echo "Creating build directory at ${BUILD_DIR}"

mkdir -p "${BUILD_DIR}"

export CRYPTEX_ROOT_DIR="${BUILD_DIR}/${CRYPTEX_ID}.dstroot"

echo "Creating distribution root"

# Copy template dstroot into build dir
cp -Rf 'APP_CRYPTEX_TEMPLATE.dstroot' "${CRYPTEX_ROOT_DIR}"

export CRYPTEX_LAUNCHD_DIR=${CRYPTEX_ROOT_DIR}/Library/LaunchDaemons
export CRYPTEX_APP_DIR=${CRYPTEX_ROOT_DIR}/System/Applications
export CRYPTEX_USR_DIR=${CRYPTEX_ROOT_DIR}/usr
export CRYPTEX_BIN_DIR=${CRYPTEX_USR_DIR}/bin
export CRYPTEX_LIB_DIR=${CRYPTEX_USR_DIR}/lib

# Copy app bundle into cryptex dstroot

echo "Copying app into cryptex"

mkdir -p "${CRYPTEX_APP_DIR}"
cp -R "${APP_PATH}" "${CRYPTEX_APP_DIR}/" || { echo "Failed to copy app into cryptex"; exit 1; }

# Create unique label for appregistrard based on app bundle ID

DAEMON_JOB_ID="${BUNDLE_ID}.appregistrard"

export DAEMON_PLIST_PATH="${CRYPTEX_LAUNCHD_DIR}/${DAEMON_JOB_ID}.plist"

# Rename appregistrard plist to match the new job ID
mv "${CRYPTEX_LAUNCHD_DIR}/appregistrardaemon.plist" "${DAEMON_PLIST_PATH}"

# Ensure daemon plist exists
if [ ! -f "$DAEMON_PLIST_PATH" ]; then
    echo "ERROR: Couldn't find daemon plist path, is the template damaged? Expected at ${DAEMON_PLIST_PATH}"
    exit 1
fi

# Set the Label property inside the daemon plist to the new job ID
/usr/libexec/PlistBuddy -c "Set Label ${DAEMON_JOB_ID}" "${DAEMON_PLIST_PATH}" || { echo "Failed to set the daemon Label"; exit 1; }

export CRYPTEX_PATH="${BUILD_DIR}/${CRYPTEX_ID}.cxbd"
export CRYPTEX_DMG_PATH="${BUILD_DIR}/${CRYPTEX_ID}.dmg"


if [ ! -d "$CRYPTEX_ROOT_DIR" ]; then
    echo "Distribution root doesn't exist at ${CRYPTEX_PATH}"
    exit 1
fi

echo "Preparing cryptex with distribution root $CRYPTEX_ROOT_DIR"

echo "Creating DMG"

rm -f ${CRYPTEX_DMG_PATH} 2>/dev/null
hdiutil create -fs hfs+ -srcfolder ${CRYPTEX_ROOT_DIR} ${CRYPTEX_DMG_PATH}

echo "Creating cryptex"

cryptexctl create --research --replace -o ${BUILD_DIR} --identifier=${CRYPTEX_ID} --version=${CRYPTEX_VERSION} --variant=research ${CRYPTEX_DMG_PATH}

echo "Personalizing cryptex"

cryptexctl personalize --replace -o ${BUILD_DIR} --variant=research ${CRYPTEX_PATH} || { echo "Personalization failed"; exit 1; }

echo "Attempting uninstall in case cryptex already exist"

cryptexctl uninstall ${CRYPTEX_ID} || true

echo "Installing cryptex"

cryptexctl install --variant=research --persist ${CRYPTEX_PATH}.signed || { echo "Failed to install cryptex :("; exit 1; }

echo "✅ App cryptex for ${BUNDLE_ID} installed!"
echo ""