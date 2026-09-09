#import <Preferences/PSListController.h>
#import "CylinderPreferences.h"
#import <Preferences/PSSpecifier.h>
#import "CLEffect.h"

@interface CylinderSettingsListController: PSListController
@property (nonatomic, retain, readonly) CylinderPreferences *settings;
- (void)setSelectedEffects:(NSArray *)effects;
-(void)setSelectedFormula:(NSString *)formula;
-(void)setFormulas:(NSDictionary *)formulas;
- (void)writeSettings;
@end
