#import <Foundation/Foundation.h>

@interface CylinderPreferences : NSObject
- (void)registerDefaults:(NSDictionary *)defaults;
- (id)objectForKey:(NSString *)key;
- (NSArray *)arrayForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (void)setObject:(id)value forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
@end
