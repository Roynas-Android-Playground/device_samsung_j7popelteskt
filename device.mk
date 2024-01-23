#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/samsung/j7popelteskt

# Rootdir
PRODUCT_PACKAGES += \
   fstab.samsungexynos7870 \
   init.baseband.rc \
   init.samsungexynos7870.rc \
   init.samsungexynos7870.usb.rc

PRODUCT_COPY_FILES += \
   $(LOCAL_PATH)/rootdir/ueventd.rc:$(TARGET_COPY_OUT_VENDOR)/ueventd.rc
