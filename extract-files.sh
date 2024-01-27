#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=j7popelteskt
VENDOR=samsung

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        vendor/bin/hw/gpsd)
            "${PATCHELF}" --add-needed "libgpsd_shim.so" "${2}"
            ;;
	vendor/lib/mediadrm/libwvdrmengine.so|vendor/lib/libwvhidl.so)
	    "${PATCHELF}" --replace-needed libprotobuf-cpp-lite.so libprotobuf-cpp-lite-v29.so "${2}"
	    ;;
	vendor/lib/libsec-ril.so)
	    "${PATCHELF}" --replace-needed libprotobuf-cpp-full.so libprotobuf-cpp-full-v29.so "${2}"
	    "${PATCHELF}" --add-needed libcutils_shim.so "${2}"
	    "${PATCHELF}" --replace-needed libsqlite.so libsqlite-v29.so "${2}"
	    "${PATCHELF}" --replace-needed libxml2.so libxml2-v29.so "${2}"
	    ;;
	lib/libaudioroute.so)
	    sed -i 's/system/vendor/' "${2}"
	    ;;
	lib/hw/camera.exynos7870.so)
	    "${PATCHELF}" --replace-needed libcamera_client.so libcamera_metadata_helper.so "$2"
	    "${PATCHELF}" --replace-needed libgui.so libgui_vendor.so "$2"
	    ;;
	lib/libexynoscamera.so|lib/libexynoscamera3.so)
	    "${PATCHELF}" --remove-needed libcamera_client.so "$2"
	    "${PATCHELF}" --remove-needed libgui.so "$2"
            ;;
	lib/libsensorlistener.so)
	    "${PATCHELF}" --remove-needed libandroid.so "$2"
	    "${PATCHELF}" --add-needed libsensorndkbridge.so "$2"
	    ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
