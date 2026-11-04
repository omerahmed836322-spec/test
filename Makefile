ARCHS := arm64
TARGET := iphone:clang:latest:15.0

# Fixed offline activation lock is enabled by default in this source package.
# Restore the original licensing implementation with: make LOCAL_TEST=0
LOCAL_TEST ?= 1

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME := XsGpS

SOURCE_DIR := Source
SOURCE_M_FILES_RAW := $(sort $(wildcard $(SOURCE_DIR)/*.m))
ROOT_M_FILES_RAW := $(sort $(wildcard *.m))
XS_GPS_ALL_M_FILES := $(if $(ROOT_M_FILES_RAW),$(ROOT_M_FILES_RAW),$(SOURCE_M_FILES_RAW))

# v60 build fix:
# The old project used LocationSpoofer.m as the main hook file. After the
# official rename to XsGpS.m, some repositories may still contain the old
# Source/LocationSpoofer.m file. Compiling both files exports the same C
# symbols and causes duplicate symbol linker errors. When XsGpS.m is present,
# build only the new official hook file and ignore the old duplicate.
ifneq ($(filter XsGpS.m $(SOURCE_DIR)/XsGpS.m,$(XS_GPS_ALL_M_FILES)),)
XsGpS_FILES := $(filter-out LocationSpoofer.m $(SOURCE_DIR)/LocationSpoofer.m,$(XS_GPS_ALL_M_FILES))
else
XsGpS_FILES := $(XS_GPS_ALL_M_FILES)
endif

XsGpS_CFLAGS := -fobjc-arc -Wall -Wextra -Wno-error -Wno-nullability-completeness -Wno-unused-parameter -Wno-deprecated-declarations -I$(SOURCE_DIR) -I.
ifeq ($(LOCAL_TEST),1)
XsGpS_CFLAGS += -DXSGPS_LOCAL_TEST=1
endif
XsGpS_FRAMEWORKS := Foundation UIKit CoreLocation MapKit Photos PhotosUI CoreBluetooth AVFoundation CoreMedia Security WebKit SystemConfiguration CoreGraphics QuartzCore
XsGpS_LDFLAGS := -install_name @executable_path/Frameworks/XsGpS.dylib

include $(THEOS)/makefiles/library.mk
