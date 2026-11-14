#!/usr/bin/env ruby
# Compile the production restore helpers against small host-side layer objects.
require 'open3'
require 'tmpdir'
root = File.expand_path('..', __dir__)
source = File.read(File.join(root, 'tweak/CylinderPageContext.m'))
helpers = source[/static BOOL CylinderNearlyEqual.*?(?=\/\/\/ Writes the staged values)/m]
abort 'Could not locate production restoration helpers' unless helpers
program = <<~OBJC
  #import <Foundation/Foundation.h>
  #import <QuartzCore/QuartzCore.h>
  #include <assert.h>
  @interface TestLayer : NSObject
  @property CATransform3D transform;
  @property CGPoint position;
  @end
  @implementation TestLayer @end
  @interface TestView : NSObject
  @property CGFloat alpha;
  @end
  @implementation TestView @end
  typedef unsigned char CylinderDirtyFlags;
  enum { CylinderDirtyTransform = 1, CylinderDirtyPosition = 2, CylinderDirtyAlpha = 4 };
  typedef struct {
    __unsafe_unretained TestLayer *layer;
    __unsafe_unretained TestView *view;
    CylinderDirtyFlags dirty, touched;
    CATransform3D savedTransform, writtenTransform;
    CGPoint savedPosition, writtenPosition;
    CGFloat savedAlpha, writtenAlpha;
    BOOL hasCachedFrame;
  } CylinderEntry;
  #{helpers}
  int main(void) { @autoreleasepool {
    TestLayer *layer = [TestLayer new];
    TestView *view = [TestView new];
    CATransform3D original = CATransform3DIdentity;
    CATransform3D effect = CATransform3DMakeScale(0.5, 0.5, 1);
    CylinderEntry entry = {.layer=layer, .view=view, .dirty=7, .touched=7,
      .savedTransform=original, .writtenTransform=effect,
      .savedPosition={100, 200}, .writtenPosition={20, 30},
      .savedAlpha=1, .writtenAlpha=0.3};
    layer.transform = effect; layer.position = CGPointMake(20, 30); view.alpha = 0.3;
    CylinderEntryRestore(&entry, 7);
    assert(CATransform3DEqualToTransform(layer.transform, original));
    assert(CGPointEqualToPoint(layer.position, CGPointMake(100, 200)));
    assert(view.alpha == 1 && entry.dirty == 0 && entry.touched == 0);
    entry.dirty = 7; entry.touched = 7;
    CATransform3D newer = CATransform3DMakeScale(0.8, 0.8, 1);
    layer.transform = newer; layer.position = CGPointMake(500, 600); view.alpha = 0.9;
    CylinderEntryRestore(&entry, 7);
    assert(CATransform3DEqualToTransform(layer.transform, newer));
    assert(CGPointEqualToPoint(layer.position, CGPointMake(500, 600)));
    assert(view.alpha == 0.9 && entry.dirty == 0);
    entry.dirty = 4; view.alpha = 0.30000001;
    CylinderEntryRestore(&entry, 4);
    assert(view.alpha == 1); // Core Animation float rounding still counts as our write.
    puts("restore regressions: own values restored, SpringBoard values preserved, opacity tolerance passed");
  } return 0; }
OBJC
Dir.mktmpdir('cylinder-core-') do |directory|
  binary = File.join(directory, 'regressions')
  output, status = Open3.capture2e('clang', '-x', 'objective-c', '-fobjc-arc',
    '-framework', 'Foundation', '-framework', 'QuartzCore', '-', '-o', binary, stdin_data: program)
  abort output unless status.success?
  system(binary) || abort('Core regression test failed')
end
