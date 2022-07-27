#!/bin/bash

# Configuration file
CONFIG=./.config

# source can read from process substitution, hence, it only imports the content provided by head i.e the first 3 lines
# We do this because config file not only contains variables but also patch names & sourcing a file in bash executes it.
source <( head -n 3 "$config" )

# Get line numbers where included & excluded patches start from. 
# We rely on the hardcoded messages to get the line numbers using grep
excluded_start="$(grep -n -m1 'EXCLUDE PATCHES' "$CONFIG" | cut -d':' -f1)"
included_start="$(grep -n -m1 'INCLUDE PATCHES' "$CONFIG" | cut -d':' -f1)"

# Get everything but hashes from between the EXCLUDE PATCH & INCLUDE PATCH line
# Note: '^[^#[:blank:]]' ignores starting hashes and/or blank characters i.e, whitespace & tab excluding newline
excluded_patches="$(tail -n +$excluded_start $CONFIG | head -n "$(( included_start - excluded_start ))" | grep '^[^#[:blank:]]')"

# Get everything but hashes starting from INCLUDE PATCH line until EOF
included_patches="$(tail -n +$included_start $CONFIG | grep '^[^#[:blank:]]')"

# Array for storing patches
declare -a patches

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
artifacts["revanced-integrations.apk"]="revanced/revanced-integrations app-release-unsigned .apk"
artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"
artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"

## Functions

get_artifact_download_url() {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url result
    api_url="https://api.github.com/repos/$1/releases/latest"
    # shellcheck disable=SC2086
    result=$(curl -s $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo "${result:1:-1}"
}

# Function for populating patches array, using a function here reduces redundancy & satisfies DRY principals
populate_patches() {
    # Note: <<< defines a 'here-string'. Meaning, it allows reading from variables just like from a file
    while read -r patch; do
        patches+=("$1 $patch")
    done <<< "$2"
}

# Function containing ReVanced build command
build_apps() {
    echo "--------------------------------"
    echo "Building ${5:9}"
    echo "--------------------------------"
    java -jar revanced-cli.jar $1 -b revanced-patches.jar $2 \ 
                $3 ${patches[@]} \
                $EXPERIMENTAL \
                $4 $5
}

## Main

# cleanup to fetch new revanced on next run
if [[ "$1" == "clean" ]]; then
    rm -f revanced-cli.jar revanced-integrations.apk revanced-patches.jar
    exit
fi

if [[ "$1" == "experimental" ]]; then
    EXPERIMENTAL="--experimental"
fi

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f "$artifact" ]; then
        echo "Downloading $artifact"
        # shellcheck disable=SC2086,SC2046
        curl -sLo "$artifact" $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

# Fetch microG
chmod +x apkeep

if [ ! -f "vanced-microG.apk" ]; then
    # Vanced microG 0.2.24.220220
    VMG_VERSION="0.2.24.220220"

    echo "Downloading Vanced microG"
    ./apkeep -a com.mgoogle.android.gms@$VMG_VERSION .
    mv com.mgoogle.android.gms@$VMG_VERSION.apk vanced-microG.apk
fi

# If the variables are NOT empty, call populate_patches with proper arguments
[[ ! -z "$excluded_patches" ]] && populate_patches "-e" "$excluded_patches"
[[ ! -z "$included_patches" ]] && populate_patches "-i" "$included_patches"

mkdir -p build

# List of arguments expected by ReVanced CLI
readonly INTEGRATIONS=("-m revanced-integrations.apk")
readonly MOUNT=("--mount" "-e microg-support")
readonly YT=("-a com.google.android.youtube.apk" "-o build/revanced-")
readonly YTM=("-a com.google.android.apps.youtube.music.apk" "-o build/revanced-music-")
readonly ROOT_SUFFIX="root.apk"
readonly NON_ROOT_SUFFIX="nonroot.apk"

# Compile build based on user's preferences. If nothing is specified, it will build everything
case "$APP-$VARIANT" in
    "YT-"|"yt-")
        echo "Building both variants of YouTube"
        build_apps "${INTEGRATIONS[@]}" "${MOUNT[@]}" "${YT[@]}$ROOT_SUFFIX"
        build_apps "${INTEGRATIONS[@]}" "" "" "${YT[@]}$NON_ROOT_SUFFIX"
        ;;
    "YT-ROOT"|"yt-root")
        echo "Building root variant of YouTube"
        build_apps "${INTEGRATIONS[@]}" "${MOUNT[@]}" "${YT[@]}$ROOT_SUFFIX"
        ;;
    "YT-NON-ROOT"|"yt-non-root")
        echo "Building non-root variant of YouTube"
        build_apps "${INTEGRATIONS[@]}" "" "" "${YT[@]}$NON_ROOT_SUFFIX"
        ;;
    "YTM-"|"ytm-")
        echo "Building both variants of YouTube Music"
        build_apps "" "${MOUNT[@]}" "${YTM[@]}$ROOT_SUFFIX"
        build_apps "" "" "" "${YTM[@]}$NON_ROOT_SUFFIX"
        ;;
    "YTM-ROOT"|"ytm-root")
        echo "Building root variant of YouTube Music"
        build_apps "" "${MOUNT[@]}" "${YTM[@]}$ROOT_SUFFIX"
        ;;
    "YTM-NON-ROOT"|"ytm-non-root")
        echo "Building non-root variant of YouTube Music"
        build_apps "" "" "" "${YTM[@]}$NON_ROOT_SUFFIX"
        ;;
    "-ROOT"|"-root")
        echo "Building ROOT variant of YT & YTM"
        build_apps "${INTEGRATIONS[@]}" "${MOUNT[@]}" "${YT[@]}$ROOT_SUFFIX"
        build_apps "" "${MOUNT[@]}" "${YTM[@]}$ROOT_SUFFIX"
        ;;
    "-NON-ROOT"|"-non-root")
        echo "Building NON-ROOT variant of YT & YTM"
        build_apps "${INTEGRATIONS[@]}" "" "" "${YT[@]}$NON_ROOT_SUFFIX"
        build_apps "" "" "" "${YTM[@]}$NON_ROOT_SUFFIX"
        ;;
    *)
        echo "Building Everything"
        build_apps "${INTEGRATIONS[@]}" "${MOUNT[@]}" "${YT[@]}$ROOT_SUFFIX"
        build_apps "${INTEGRATIONS[@]}" "" "" "${YT[@]}$NON_ROOT_SUFFIX"
        build_apps "" "${MOUNT[@]}" "${YTM[@]}$ROOT_SUFFIX"
        build_apps "" "" "" "${YTM[@]}$NON_ROOT_SUFFIX"
        ;;
esac