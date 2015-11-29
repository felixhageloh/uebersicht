//
//  UBMouseHandler.m
//  
//
//  Created by Felix Hageloh on 23/11/15.
//
//

#import "UBMouseHandler.h"
#import "UBWindow.h"
#import "UBPreferencesController.h"

@implementation UBMouseHandler {
    UBWindow* window;
    UBPreferencesController* preferences;
}

- (id)initWithWindow:(UBWindow*)aWindow
      andPreferences:(UBPreferencesController*)thePreferences
{
    self = [super init];
    
    if (self) {
        window = aWindow;
        preferences = thePreferences;
        
        // listen to mouse events
        CFMachPortRef eventTap = CGEventTapCreate(
            kCGHIDEventTap,
            kCGHeadInsertEventTap,
            kCGEventTapOptionListenOnly,
            CGEventMaskBit(kCGEventFlagsChanged),
            &onModifierKeyChange,
            (__bridge void *)(self)
        );
        CFRunLoopSourceRef runLoopSourceRef = CFMachPortCreateRunLoopSource(NULL, eventTap, 0);
        CFRelease(eventTap);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSourceRef, kCFRunLoopDefaultMode);
        CFRelease(runLoopSourceRef);
    }
    
    return self;
}

- (UBPreferencesController*)preferences
{
    return preferences;
}

- (UBWindow*)window
{
    return window;
}

CGEventRef onModifierKeyChange(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* self)
{
    
    UBMouseHandler* this = (__bridge UBMouseHandler*)self;
    if((CGEventGetFlags(event) & [this.preferences interactionShortcut]) == 0) {
        [this.window sendToDesktop];
    } else {
        [this.window comeToFront];
    }

    return event;
}


@end
