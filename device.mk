#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/samsung/j7popelteskt

# Setup dalvik vm configs
$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)

# Shipping API
PRODUCT_SHIPPING_API_LEVEL := 24

# Rootdir
PRODUCT_PACKAGES += \
   fstab.samsungexynos7870 \
   init.baseband.rc \
   init.samsungexynos7870.rc \
   init.samsungexynos7870.usb.rc

PRODUCT_COPY_FILES += \
   $(LOCAL_PATH)/rootdir/ueventd.rc:$(TARGET_COPY_OUT_VENDOR)/ueventd.rc
