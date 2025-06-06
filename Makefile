TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = xiaohongshu

ROOTLESS = 1
ifeq ($(ROOTLESS),1)
 THEOS_PACKAGE_SCHEME=rootless
endif
ifeq ($(THEOS_PACKAGE_SCHEME), rootless)
 TARGET = iphone:clang:latest:15.0
else
 TARGET = iphone:clang:latest:12.0
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = XHSHelper

XHSHelper_FILES = Tweak.x XHSHelperViewController.m
XHSHelper_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk