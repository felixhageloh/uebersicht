//
//  UBMouseHandler.m
//  
//
//  Created by Felix Hageloh on 23/11/15.
//
//

#import "UBMouseHandler.h"
#import "UBWindow.h"

@implementation UBMouseHandler {
    NSWindow* window;
}

- (id)initWithWindow:(NSWindow*)aWindow
{
    self = [super init];
    
    if (self) {
        window = aWindow;
        
        // listen to mouse events
        CFMachPortRef eventTap = CGEventTapCreate(
            kCGHIDEventTap,
            kCGHeadInsertEventTap,
            kCGEventTapOptionListenOnly,
            CGEventMaskBit(kCGEventLeftMouseUp),
            &onGlobalMouseEvent,
            (__bridge void *)(self)
        );
        CFRunLoopSourceRef runLoopSourceRef = CFMachPortCreateRunLoopSource(NULL, eventTap, 0);
        CFRelease(eventTap);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSourceRef, kCFRunLoopDefaultMode);
        CFRelease(runLoopSourceRef);
    }
    
    return self;
}

CGEventRef onGlobalMouseEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* self)
{
    
    UBMouseHandler* this = (__bridge UBMouseHandler*)self;
    [(UBWindow*)this.window sendToDesktop];


//    CGPoint mouseLocation = CGEventGetLocation(event);
//    CFArrayRef windowList = CGWindowListCopyWindowInfo(
//        kCGWindowListOptionOnScreenAboveWindow | kCGWindowListExcludeDesktopElements,
//        (CGWindowID)[this.window windowNumber]
//    );
//    
//    CFDictionaryRef windowData;
//    CGRect windowBounds;
//    NSString *ownerName;
//    BOOL isOccluded = NO;
//    
//    for (int i = 0 ; i < CFArrayGetCount(windowList); i++) {
//        windowData = CFArrayGetValueAtIndex(windowList, i);
//        CGRectMakeWithDictionaryRepresentation(
//            CFDictionaryGetValue(windowData, kCGWindowBounds),
//            &windowBounds
//        );
//        ownerName = CFDictionaryGetValue(windowData, kCGWindowOwnerName);
//        
//        isOccluded =
//            ![ownerName isEqualToString:@"Dock"] &&
//            CGRectContainsPoint(windowBounds, mouseLocation);
//        
//
//        if (isOccluded) {
//            break;
//        }
//    }
//    
//    if (!isOccluded) {
//        [this.window orderFront:this];
//    }
//    
//
//    CFRelease(windowList);
//
    return event;
}

- (NSWindow*)window
{
    return window;
}


@end
