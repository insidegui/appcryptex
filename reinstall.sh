#!/bin/zsh

set -e

# For every signed bundle found, reinstall the cryptex
for dir in $(find . -type d -name "*.cxbd.signed"); do
    absdir=$(realpath "$dir")
    name=$(basename "$dir")
    
    echo "Reinstalling $name..."

    cryptexctl install --variant=research --persist "$absdir" || { echo "Failed to install $name :("; exit 1; }
done