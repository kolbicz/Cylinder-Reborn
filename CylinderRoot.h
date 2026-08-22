#import <Foundation/Foundation.h>

#if defined(THEOS_PACKAGE_SCHEME_ROOTHIDE)
#import <roothide.h>
#define CYLINDER_ROOT_PATH(path) jbroot(path)
#elif defined(THEOS_PACKAGE_SCHEME_ROOTLESS)
#import <rootless.h>
#define CYLINDER_ROOT_PATH(path) ROOT_PATH_NS(path)
#else
#define CYLINDER_ROOT_PATH(path) path
#endif
