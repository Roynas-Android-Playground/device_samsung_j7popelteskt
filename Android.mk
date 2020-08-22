#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),j7popelteskt)
include $(call all-subdir-makefiles,$(LOCAL_PATH))

include $(CLEAR_VARS)

LIBGLES_MALI_LIBRARY := /vendor/lib/egl/libGLES_mali.so

VULKAN_SYMLINK := $(TARGET_OUT_VENDOR)/lib/hw/vulkan.exynos5.so
$(VULKAN_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating lib/hw/vulkan.exynos5.so symlink: $@"
	@mkdir -p $(dir $@)
	$(hide) ln -sf $(LIBGLES_MALI_LIBRARY) $@

ALL_DEFAULT_INSTALLED_MODULES += \
	$(VULKAN_SYMLINK)

include $(CLEAR_VARS)

LIBGLES_MALI_LIBRARY := /vendor/lib/egl/libGLES_mali.so

LIBOPENCL_SYMLINK := $(TARGET_OUT_VENDOR)/lib/libOpenCL.so
$(LIBOPENCL_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating lib/libOpenCL.so symlink: $@"
	@mkdir -p $(dir $@)
	$(hide) ln -sf libOpenCL.so.1 $@

LIBOPENCL1_SYMLINK := $(TARGET_OUT_VENDOR)/lib/libOpenCL.so.1
$(LIBOPENCL1_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating lib/libOpenCL.so.1 symlink: $@"
	@mkdir -p $(dir $@)
	$(hide) ln -sf libOpenCL.so.1.1 $@

LIBOPENCL11_SYMLINK := $(TARGET_OUT_VENDOR)/lib/libOpenCL.so.1.1
$(LIBOPENCL11_SYMLINK): $(LOCAL_INSTALLED_MODULE)
	@echo "Creating lib/libOpenCL.so.1.1 symlink: $@"
	@mkdir -p $(dir $@)
	$(hide) ln -sf $(LIBGLES_MALI_LIBRARY) $@

ALL_DEFAULT_INSTALLED_MODULES += \
	$(LIBOPENCL_SYMLINK) \
	$(LIBOPENCL1_SYMLINK) \
	$(LIBOPENCL11_SYMLINK)

endif
