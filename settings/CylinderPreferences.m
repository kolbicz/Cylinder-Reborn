#import "CylinderPreferences.h"

static CFStringRef const CylinderPreferencesDomain = CFSTR("com.ryannair05.cylinder");

@interface CylinderPreferences ()
@property(nonatomic, copy) NSDictionary *registeredDefaults;
@end

@implementation CylinderPreferences

- (void)registerDefaults:(NSDictionary *)defaults
{
    self.registeredDefaults = defaults;
}

- (id)objectForKey:(NSString *)key
{
    CFPreferencesAppSynchronize(CylinderPreferencesDomain);
    id value = CFBridgingRelease(CFPreferencesCopyAppValue(
        (__bridge CFStringRef)key, CylinderPreferencesDomain));
    return value ?: self.registeredDefaults[key];
}

- (NSArray *)arrayForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    return [value isKindOfClass:NSArray.class] ? value : nil;
}

- (BOOL)boolForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    return [value respondsToSelector:@selector(boolValue)] && [value boolValue];
}

- (void)setObject:(id)value forKey:(NSString *)key
{
    CFPreferencesSetAppValue((__bridge CFStringRef)key,
        (__bridge CFPropertyListRef)value, CylinderPreferencesDomain);
    CFPreferencesAppSynchronize(CylinderPreferencesDomain);
}

- (void)removeObjectForKey:(NSString *)key
{
    CFPreferencesSetAppValue((__bridge CFStringRef)key, NULL,
        CylinderPreferencesDomain);
    CFPreferencesAppSynchronize(CylinderPreferencesDomain);
}

@end
