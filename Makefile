THEOS_PACKAGE_SCHEME=rootless
export ARCHS = arm64 arm64e

FINALPACKAGE = 1

TARGET := iphone:clang:14.5:15.0

export ADDITIONAL_CFLAGS = -DTHEOS_LEAN_AND_MEAN -fobjc-arc -Wno-deprecated

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cylinder
Cylinder_FILES = tweak/tweak.x $(wildcard tweak/*.m) lua/onelua.c

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += settings
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/Cylinder/$(ECHO_END)
	$(ECHO_NOTHING)rsync -a --exclude .DS_Store scripts/ $(THEOS_STAGING_DIR)/Library/Cylinder/$(ECHO_END)