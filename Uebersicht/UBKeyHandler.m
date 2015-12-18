//
//  UBMouseHandler.m
//  
//
//  Created by Felix Hageloh on 23/11/15.
//
//

#import "UBKeyHandler.h"
#import "UBWindow.h"
#import "UBPreferencesController.h"

@implementation UBKeyHandler {
    UBPreferencesController* preferences;
    id listener;
}

- (id)initWithPreferences:(UBPreferencesController*)thePreferences
                 listener:(id)aListener
{
    self = [super init];
    
    if (self) {
        preferences = thePreferences;
        listener = aListener;
        
        // listen to keyboard events
        CFMachPortRef eventTap = CGEventTapCreate(
            kCGHIDEventTap,
            kCGHeadInsertEventTap,
            kCGEventTapOptionListenOnly,
            CGEventMaskBit(kCGEventFlagsChanged),
            &onModifierKeyChange,
            (__bridge void *)(self)
        );
        CFRunLoopSourceRef runLoopSourceRef = CFMachPortCreateRunLoopSource(
            NULL,
            eventTap,
            0
        );
        CFRelease(eventTap);
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            runLoopSourceRef,
            kCFRunLoopDefaultMode
        );
        CFRelease(runLoopSourceRef);
    }
    
    return self;
}

- (UBPreferencesController*)preferences
{
    return preferences;
}

- (void)modifierKeyReleased
{
    [listener modifierKeyReleased];
}


- (void)modifierKeyPressed
{
    [listener modifierKeyPressed];
}

CGEventRef onModifierKeyChange(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* self)
{
    
    UBKeyHandler* this = (__bridge UBKeyHandler*)self;
    if((CGEventGetFlags(event) & [this.preferences interactionShortcut]) == 0) {
        [this modifierKeyReleased];
    } else {
        [this modifierKeyPressed];
    }

    return event;
}


@end
