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
# These releases provide pure Python fallbacks, but no Android wheels.
stage_python_package() {
    local archive=$1 digest=$2 url=$3 source_dir=$4
    curl --fail --location --retry 3 "$url" --output "$work/$archive"
    echo "$digest  $work/$archive" | sha256sum --check
    tar -xzf "$work/$archive" -C "$work"
    cp -R "$work/$source_dir" "$work/app/"
}
stage_python_package yaml.tgz d584d9ec91ad65861cc08d42e834324ef890a082e591037abe114850ff7bbc3e \
    https://files.pythonhosted.org/packages/source/p/pyyaml/pyyaml-6.0.2.tar.gz pyyaml-6.0.2/lib/yaml
stage_python_package cbor.tgz 13225a262ddf5615cbd9fd55a76a0d53069d18b07d2e9f19c39e6acb8609bbb6 \
    https://files.pythonhosted.org/packages/source/c/cbor/cbor-1.0.0.tar.gz cbor-1.0.0/cbor
# The bundled android recipe imports Cython in setup.py before declaring it.
# Supply its build requirements to the isolated wheel build.
cp -R "$root/buildconfig/android/recipes" "$work/recipes"
recipe=$(python -c 'from pathlib import Path; import pythonforandroid.recipes.android as a; print(Path(a.__file__).parent)')
cp -R "$recipe" "$work/recipes/android"
cat > "$work/recipes/android/src/pyproject.toml" <<'TOML'
[build-system]
requires = ["setuptools<82", "wheel", "Cython>=3.1,<3.2"]
build-backend = "setuptools.build_meta"
TOML
cd "$work"
p4a apk --private "$work/app" --no-byte-compile-python --bootstrap=sdl2 --arch=arm64-v8a \
    --sdk-dir="$ANDROID_HOME" --ndk-dir="$ANDROID_NDK_HOME" \
    --android-api=35 --ndk-api=24 --minsdk=24 --orientation=landscape \
    --package=org.tuxemon.tuxemon --name=Tuxemon --version=0.4.35 \
    --local-recipes="$work/recipes" \
    --requirements='python3,android,openssl,pygame-ce,Pillow,pydantic-core,pydantic==2.12.3,babel,websockets,packaging,pyscroll>=2.31,pytmx==3.32,requests,natsort,prompt_toolkit,pygame-menu-ce==4.5.2,pyperclip,typing_extensions,annotated-types,typing-inspection,wcwidth,idna,certifi,charset-normalizer,urllib3'
mkdir -p "$root/dist/android"
cp ./*.apk "$root/dist/android/Tuxemon-arm64.apk"
