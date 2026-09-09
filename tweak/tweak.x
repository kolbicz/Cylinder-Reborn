#import "tweak.h"
#import "luastuff.h"
#import "../Defines.h"
#import "UIView+Cylinder.h"
#import <objc/message.h>

static BOOL _enabled;
static u_int32_t _randSeedForCurrentPage;
__weak static SBIconView *neededView;
static NSMutableArray *frameArray;
static BOOL _suspendedForIconEditing;

static BOOL cylinder_is_icon_editing(void)
{
    Class controllerClass = objc_getClass("SBIconController");
    SEL sharedSelector = @selector(sharedInstance);
    SEL editingSelector = @selector(isEditing);
    if(!controllerClass || ![controllerClass respondsToSelector:sharedSelector])
        return false;

    id controller = ((id (*)(id, SEL))objc_msgSend)(controllerClass, sharedSelector);
    return controller && [controller respondsToSelector:editingSelector]
        && ((BOOL (*)(id, SEL))objc_msgSend)(controller, editingSelector);
}

void reset_icon_layout(__unsafe_unretained SBIconListView *self)
{
    self.layer.transform = CATransform3DIdentity;
    [self.layer restorePosition];
    self.alpha = 1;
    
    [self enumerateIconViewsUsingBlock:^(SBIconView *v)  {
        v.layer.transform = CATransform3DIdentity;
        [v.layer restorePosition];
        v.alpha = 1;
    }];

}

void page_swipe(SBFolderView *self, SBIconScrollView *scrollView)
{
    CGRect eye = {scrollView.contentOffset, scrollView.bounds.size};

    for (int i = 0; i < scrollView.subviews.count; i++) {
        __unsafe_unretained SBIconListView *view = scrollView.subviews[i];
        // make sure it is an SBIconListView and actually has icons
        if (view.subviews.count < 1 || ![view isKindOfClass:objc_getClass("SBIconListView")]) continue;

        if (view.wasModifiedByCylinder)
        {
            reset_icon_layout(view);
        }

        if(CGRectIntersectsRect(eye, view.frame))
        {
            const float offset = scrollView.contentOffset.x - view.frame.origin.x;

            _enabled = manipulate((UIView *) view, offset, _randSeedForCurrentPage); //defined in luastuff.m
            view.wasModifiedByCylinder = true;
        }
    }
}

void end_scroll(__unsafe_unretained SBFolderView *self)
{
    [self enumerateIconListViewsUsingBlock:^(SBIconListView *view)  {
        reset_icon_layout(view);
        view.wasModifiedByCylinder = false;
        [view setIconsNeedLayout];
        [view setAlphaForAllIcons:1];
    }];
}

%hook SBFolderView //SBIconController
-(void)scrollViewDidScroll:(SBIconScrollView *)scrollView
{   
    %orig;

    // Rotation updates the scroll offset during SpringBoard relayout. Do not
    // interpret that movement as a page swipe, and clear any active effect.
    if (self.isRotating) {
        end_scroll(self);
        return;
    }

    // Dragging icons temporarily replaces and reparents icon views. Running
    // scripts against that transient hierarchy can make them fail and remove
    // themselves from the active effect array.
    if(cylinder_is_icon_editing()) {
        if(!_suspendedForIconEditing) {
            end_scroll(self);
            _suspendedForIconEditing = true;
        }
        return;
    }
    _suspendedForIconEditing = false;

    if(!_enabled) return;

    page_swipe(self, scrollView);
}
%end

%hook SBFolderView 
-(void)scrollViewDidEndDecelerating:(SBIconScrollView *)scrollView
{
    %orig;

    // Always clean up. A Lua error can disable Cylinder after views were changed.
    end_scroll(self);

    if(_enabled) {
        _randSeedForCurrentPage = arc4random();
    }
}

-(void)scrollViewDidEndDragging:(SBIconScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    %orig;

    if (!decelerate) {
        end_scroll(self);
        if (_enabled) {
            _randSeedForCurrentPage = arc4random();
        }
    }
}

%end

%group iOS15
%hook SBRootFolderView 
- (void)updateVisibleColumnRangeWithTotalLists:(NSUInteger)arg1 iconVisibilityHandling:(NSInteger)arg2
{
    return %orig(arg1, 0);
}
%end
%end

#ifndef THEOS_PACKAGE_INSTALL_PREFIX
%group iOS14
%hook SBFolderView 
// For iOS 13, SpringBoard "optimizes" the icon visibility by only showing the bare
// minimum. I have no idea why this works, but it does. An interesting stack trace can
// be found by forcing a crash in -[SBRecycledViewsContainer addSubview:]. Probably best to decompile this function in IDA or something.
-(void)updateVisibleColumnRangeWithTotalLists:(NSUInteger)arg1 columnsPerList:(NSUInteger)arg2 iconVisibilityHandling:(NSInteger)arg3
{
    return %orig(arg1, arg2, 0);
}

%end
%end
#endif

static void loadPrefs()
{
    CFStringRef domain = CFSTR("com.ryannair05.cylinder");
    CFPreferencesAppSynchronize(domain);
    id enabledValue = CFBridgingRelease(CFPreferencesCopyAppValue(
        (__bridge CFStringRef)PrefsEnabledKey, domain));
    id randomValue = CFBridgingRelease(CFPreferencesCopyAppValue(
        (__bridge CFStringRef)PrefsRandomizedKey, domain));
    id effectsValue = CFBridgingRelease(CFPreferencesCopyAppValue(
        (__bridge CFStringRef)PrefsEffectKey, domain));

    BOOL enabled = enabledValue ? [enabledValue boolValue] : YES;
    BOOL random = randomValue ? [randomValue boolValue] : NO;
    NSArray *effects = [effectsValue isKindOfClass:NSArray.class]
        ? effectsValue : DEFAULT_EFFECTS;

    if(!enabled)
    {
        close_lua();
        _enabled = false;
    }
    else
    {
        _enabled = init_lua(effects, random);
    }
}


// the reason for this is create_state() in luastuff.m,
// which loadPrefs() calls, is called when SpringBoard loads.
// Unfortunately calling UIScreen.mainScreen.bounds.size
// causes a bootloop. so instead of setting that 
// global variable there, we set it when we know that
// everything in SpringBoard has already loaded
%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application 
{
    %orig;
	loadPrefs();
}
%end

%ctor{
    %init;

    if (@available(iOS 15, *)) {
        %init(iOS15);
    }
    #ifndef THEOS_PACKAGE_INSTALL_PREFIX
    else {
        %init(iOS14);
    }
    #endif

    //listen to notification center (for settings change)
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, (CFNotificationCallback)loadPrefs, (CFStringRef)kCylinderSettingsChanged, NULL, CFNotificationSuspensionBehaviorCoalesce);
}
