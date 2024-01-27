#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)

TARGET_BOOT_ANIMATION_RES := 720

# Inherit some common PixelExperience stuff.
$(call inherit-product, vendor/aosp/config/common_full_phone.mk)

# Inherit from j7popelteskt device
$(call inherit-product, device/samsung/j7popelteskt/device.mk)

PRODUCT_DEVICE := j7popelteskt
PRODUCT_NAME := aosp_j7popelteskt
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-J727S
PRODUCT_MANUFACTURER := samsung

PRODUCT_GMS_CLIENTID_BASE := android-samsung

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="j7popelteskt-user 9 PPR1.180610.011 J727SKSU5CUD2 release-keys"

BUILD_FINGERPRINT := samsung/j7popelteskt/j7popelteskt:9/PPR1.180610.011/J727SKSU5CUD2:user/release-keys
