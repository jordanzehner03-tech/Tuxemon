#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/app"
cp -R "$root"/{tuxemon,mods,run_tuxemon.py,LICENSE,ATTRIBUTIONS.md} "$work/app/"
cp "$root/buildconfig/android/main.py" "$work/app/"
# Enable the game's virtual controls on first launch in the staged copy.
sed -i 's/^    overlay: bool = False$/    overlay: bool = True/' "$work/app/tuxemon/config.py"
cd "$work"
p4a apk --private "$work/app" --bootstrap=sdl2 --arch=arm64-v8a \
    --sdk-dir="$ANDROID_HOME" --ndk-dir="$ANDROID_NDK_HOME" \
    --android-api=35 --ndk-api=24 --minsdk=24 --orientation=landscape \
    --package=org.tuxemon.tuxemon --name=Tuxemon --version=0.4.35 \
    --local-recipes="$root/buildconfig/android/recipes" \
    --requirements='python3,android,openssl,pygame-ce,Pillow,pydantic-core,pydantic==2.12.3,babel,cbor,websockets,packaging,pyscroll>=2.31,pytmx==3.32,requests,natsort,PyYAML>=6.0.2,prompt_toolkit,pygame-menu-ce==4.5.2,pyperclip,typing_extensions,annotated-types,typing-inspection,wcwidth,idna,certifi,charset-normalizer,urllib3'
mkdir -p "$root/dist/android"
cp ./*.apk "$root/dist/android/Tuxemon-arm64.apk"
