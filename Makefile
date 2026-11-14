FINALPACKAGE = 1

ARCHS = arm64 arm64e

# This fork targets iOS 15+ and provides separate native rootless and roothide packages.
export TARGET ?= iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME ?= rootless

export ADDITIONAL_CFLAGS = -DTHEOS_LEAN_AND_MEAN -fobjc-arc -DLUA_USE_IOS

export ADDITIONAL_CFLAGS += -fno-ptrauth-objc-class-ro

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cylinder
Cylinder_FILES = tweak/tweak.x $(wildcard tweak/*.m) lua/onelua.c
# MAKE_LIB leaves out the standalone interpreter's main().
lua/onelua.c_CFLAGS = -DMAKE_LIB -O2

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += settings
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/Cylinder/$(ECHO_END)
	$(ECHO_NOTHING)rsync -a --exclude .DS_Store scripts/ $(THEOS_STAGING_DIR)/Library/Cylinder/$(ECHO_END)

# Logs are shared by SpringBoard and Settings (mobile), but remain inside the jailbreak root.
# Roothide maintainer scripts run under its bootstrap path translation, where /Library is jbroot-relative.
before-package::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/DEBIAN$(ECHO_END)
	$(ECHO_NOTHING)sed 's|@CYLINDER_PREFIX@|$(THEOS_PACKAGE_INSTALL_PREFIX)|g' packaging/postinst.in > $(THEOS_STAGING_DIR)/DEBIAN/postinst$(ECHO_END)
	$(ECHO_NOTHING)chmod 0755 $(THEOS_STAGING_DIR)/DEBIAN/postinst$(ECHO_END)
