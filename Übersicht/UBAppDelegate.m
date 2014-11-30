//
//  UBAppDelegate.m
//  Übersicht
//
//  Created by Felix Hageloh on 20/9/13.
//  Copyright (c) 2013 Felix Hageloh.
//
//  Released under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version. See <http://www.gnu.org/licenses/> for
//  details.

#import "UBAppDelegate.h"
#import "UBWindow.h"
#import "UBPreferencesController.m"
#import "WebInspector.h"

int const MAX_DISPLAYS = 42;
int const PORT         = 41416;

@implementation UBAppDelegate {
    NSStatusItem* statusBarItem;
    NSTask* widgetServer;
    UBPreferencesController* preferences;
    BOOL keepServerAlive;
    WebInspector *inspector;
    int portOffset;
}

@synthesize window;
@synthesize statusBarMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    statusBarItem = [self addStatusItemToMenu: statusBarMenu];
    preferences   = [[UBPreferencesController alloc] initWithWindowNibName:@"UBPreferencesController"];
    
    // Handles the screen entries in the menu, and will send the window to the user's preferred screen
    [self screensChanged:self];
    
    
    // NSTask doesn't terminate when xcode stop is pressed. Other ways of spawning
    // the server, like system() or popen() have the same problem.
    // So, hit em with a hammer :(
    system("killall localnode");
    
    // start server and load webview
    portOffset      = 0;
    keepServerAlive = YES;
    [self startServer: ^(NSString* output) {
        if ([output rangeOfString:@"server started"].location != NSNotFound) {
            // trailing slash required for load policy in UBWindow
            [window loadUrl:[NSString stringWithFormat:@"http://127.0.0.1:%d/", PORT+portOffset]];
        } else if ([output rangeOfString:@"EADDRINUSE"].location != NSNotFound) {
            portOffset++;
            if (portOffset >= 20) {
                keepServerAlive = NO;
                NSLog(@"couldn't find an open port. Giving up...");
            }
        } else if ([output rangeOfString:@"error"].location != NSNotFound) {
            [self notifyUser:output withTitle:@"Error"];
        };
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screensChanged:)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];

    // enable the web inspector
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // events to detect web inspector opening/closing
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(aWindowClosed:)
                                                 name:NSWindowWillCloseNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(frameChanged:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:nil];
    
    // listen to command key changes
    CFMachPortRef eventTap = CGEventTapCreate(kCGHIDEventTap,
                                              kCGHeadInsertEventTap,
                                              kCGEventTapOptionListenOnly,
                                              CGEventMaskBit(kCGEventFlagsChanged),
                                              &cmdKeyChange,
                                              (__bridge void *)(self));
    CFRunLoopSourceRef runLoopSourceRef = CFMachPortCreateRunLoopSource(NULL, eventTap, 0);
    CFRelease(eventTap);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSourceRef, kCFRunLoopDefaultMode);
    CFRelease(runLoopSourceRef);
}

- (void)startServer:(void (^)(NSString*))callback
{
    NSLog(@"starting server task");

    void (^keepAlive)(NSTask*) = ^(NSTask* theTask) {
        if (keepServerAlive) {
            [self performSelector:@selector(startServer:) withObject:callback afterDelay:5.0];
        }
    };

    widgetServer = [self launchWidgetServer:[preferences.widgetDir path]
                                     onData:callback
                                     onExit:keepAlive];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    keepServerAlive = NO;
    [widgetServer terminate];
}

- (NSStatusItem*)addStatusItemToMenu:(NSMenu*)aMenu
{
    NSStatusBar*  bar = [NSStatusBar systemStatusBar];
    NSStatusItem* item;

    item = [bar statusItemWithLength: NSSquareStatusItemLength];
    
    NSImage *image = [[NSBundle mainBundle] imageForResource:@"status-icon"];
    [image setTemplate:YES];
    [item setImage: image];
    [item setHighlightMode:YES];
    [item setMenu:aMenu];
    [item setEnabled:YES];

    return item;
}

- (NSTask*)launchWidgetServer:(NSString*)widgetPath
                       onData:(void (^)(NSString*))dataHandler
                       onExit:(void (^)(NSTask*))exitHandler
{
    NSBundle* bundle     = [NSBundle mainBundle];
    NSString* nodePath   = [bundle pathForResource:@"localnode" ofType:nil];
    NSString* serverPath = [bundle pathForResource:@"server" ofType:@"js"];

    NSTask *task = [[NSTask alloc] init];

    [task setStandardOutput:[NSPipe pipe]];
    [task.standardOutput fileHandleForReading].readabilityHandler = ^(NSFileHandle *handle) {
        NSData *output   = [handle availableData];
        NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
        
        NSLog(@"%@", outStr);
        dispatch_async(dispatch_get_main_queue(), ^{
            dataHandler(outStr);
        });
    };
    
    task.terminationHandler = ^(NSTask *theTask) {
        [theTask.standardOutput fileHandleForReading].readabilityHandler = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            exitHandler(theTask);
        });
    };
    
    [task setLaunchPath:nodePath];
    [task setArguments:@[serverPath, @"-d", widgetPath,
                         @"-p", [NSString stringWithFormat:@"%d", PORT + portOffset]]];
    [task launch];
    return task;
}

- (void)notifyUser:(NSString*)message withTitle:(NSString*)title
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

CGEventRef cmdKeyChange (CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* self) {
    
    UBAppDelegate* this = (__bridge UBAppDelegate*)self;
    if((CGEventGetFlags(event) & this.interactionShortcutKey) == 0) {
        [this.window sendToDesktop];
    } else {
        [this.window comeToFront];
    }
    return event;
}

- (CGEventFlags)interactionShortcutKey
{
    return preferences.interactionShortcut;
}


#
#pragma mark status bar menu handling
#

// TODO: move these in a controller
-(NSInteger)indexOfScreenMenuItems:(NSMenu*)menu
{
    return [menu indexOfItem:[menu itemWithTitle:@"Check for Updates..."]] + 2;
}

- (void)addScreensToMenu:(NSMenu*)menu
{
    NSString *title;
    NSMenuItem *newItem;
    NSString *name;
    NSMutableDictionary *nameList = [[NSMutableDictionary alloc] initWithCapacity:MAX_DISPLAYS];

    NSInteger index = [self indexOfScreenMenuItems:menu];
    newItem = [NSMenuItem separatorItem];
    [newItem setRepresentedObject:@"screen"];
    [menu insertItem:newItem atIndex:index];
    
    CGDirectDisplayID displays[MAX_DISPLAYS];
    uint32_t numDisplays;
    
    CGGetActiveDisplayList(MAX_DISPLAYS, displays, &numDisplays);
    
    for(int i = 0; i < numDisplays; i++) {
        if (CGDisplayIsInMirrorSet(displays[i]))
            continue;
        
        name = [self screenNameForDisplay:displays[i]];
        if (!name)
            name = [NSString stringWithFormat:@"Display %i", i];
        
        NSNumber *count;
        if ((count = nameList[name])) {
            nameList[name] = [NSNumber numberWithInt:count.intValue+1];
            name = [name stringByAppendingString:[NSString stringWithFormat:@" (%i)", count.intValue+1]];
        } else {
            nameList[name] = [NSNumber numberWithInt:1];
        }
       
        title   = [NSString stringWithFormat:@"Show on %@", name];
        newItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(screenWasSelected:) keyEquivalent:@""];
        [newItem setTag:displays[i]];
        [newItem setRepresentedObject:@"screen"];
        [menu insertItem:newItem atIndex:index+i];
    }
}

- (NSString*)screenNameForDisplay:(CGDirectDisplayID)displayID
{
    if (CGDisplayIsBuiltin(displayID)) {
        return @"Built-in Display";
    }
    
    CFDictionaryRef deviceInfo = getDisplayInfoDictionary(displayID);
    
    if (!deviceInfo) {
        return nil;
    }
    
    NSString *name = nil;
    NSDictionary *localizedNames = [(__bridge NSDictionary *)deviceInfo
                                    objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    if ([localizedNames count] > 0) {
    	name = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
    }
    CFRelease(deviceInfo);
    return name;
}

- (void)removeScreensFromMenu:(NSMenu*)menu
{
    for (NSMenuItem *item in [menu itemArray]){
        if ([item.representedObject isEqualToString:@"screen"]) {
            [menu removeItem:item];
        }
    }
}

// could probably use bindings for this
- (void)markScreen:(CGDirectDisplayID)screenId inMenu:(NSMenu*)menu
{
    for (NSMenuItem *item in [menu itemArray]){
        if (![item.representedObject isEqualToString:@"screen"])
            continue;
        
        [item setState:(item.tag == screenId ? NSOnState : NSOffState)];
    }
}

// can't belive you are making. me. do. this.
static CFDictionaryRef getDisplayInfoDictionary(CGDirectDisplayID displayID)
{
    CFDictionaryRef info = nil;
    io_iterator_t iter;
    io_service_t serv;
    
    CFMutableDictionaryRef matching = IOServiceMatching("IODisplayConnect");
    
    // releases matching for us
    kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iter);
    if (err) return nil;
    
    while ((serv = IOIteratorNext(iter)) != 0)
    {
        
        CFIndex vendorID, productID;
        CFNumberRef vendorIDRef, productIDRef;
        Boolean success;
        
        info = IODisplayCreateInfoDictionary(serv,kIODisplayOnlyPreferredName);
        
        vendorIDRef  = CFDictionaryGetValue(info, CFSTR(kDisplayVendorID));
        productIDRef = CFDictionaryGetValue(info, CFSTR(kDisplayProductID));
        
        success  = CFNumberGetValue(vendorIDRef, kCFNumberCFIndexType, &vendorID);
        success &= CFNumberGetValue(productIDRef, kCFNumberCFIndexType, &productID);
        
        if (!success || CGDisplayVendorNumber(displayID) != vendorID ||
            CGDisplayModelNumber(displayID)  != productID) {
            CFRelease(info);
            info = nil;
            continue;
        }
        
        break;
    }
    
    IOObjectRelease(serv);
    IOObjectRelease(iter);
    return info;
}



#
#pragma mark Screen Handling
#


- (void)screensChanged:(id)sender
{
    CGDirectDisplayID displays[MAX_DISPLAYS];
    uint32_t numDisplays;
    uint32 screenId;
    
    CGGetActiveDisplayList(MAX_DISPLAYS, displays, &numDisplays);

    [self removeScreensFromMenu:statusBarMenu];
    
    if (numDisplays > 1) {
        [self addScreensToMenu:statusBarMenu];
    }
    
    // Most recently preferred screens will be listed first,
    // so the first match we found will be the preferred screen.
    NSArray* preferredScreens = [self getPreferredScreens];
    for (int i = 0; i < preferredScreens.count; i++) {
        NSInteger preferredScreenNumber = [preferredScreens[i] integerValue];
        for (int j = 0; j < numDisplays; j++) {
            screenId = displays[j];
            if (CGDisplayIsInMirrorSet(screenId))
                continue;
            
            if (preferredScreenNumber == CGDisplayUnitNumber(screenId)) {
                [self sendWindowToScreen:screenId];
                return;
            }
        }
    }
    // Couldn't find a preferred screen; use the primary display
    [self sendWindowToScreen:CGMainDisplayID()];
}

- (void)sendWindowToScreen:(CGDirectDisplayID)screenId
{
    [window fillScreen:screenId];
    
    [self markScreen:screenId inMenu:statusBarMenu];
}

- (NSMutableArray*)getPreferredScreens
{
    NSMutableArray* preferredScreens;
    NSArray* preferredScreensPref = [[NSUserDefaults standardUserDefaults]
                                     objectForKey:@"preferredScreens"];
    if (!preferredScreensPref) {
        preferredScreensPref = @[];
    }
    preferredScreens = [NSMutableArray arrayWithArray:preferredScreensPref];
    return preferredScreens;
}

- (void)setPreferredScreen:(CGDirectDisplayID)screenId
{
    NSNumber* displayNumber = @(CGDisplayUnitNumber(screenId));
    
    // Add displayNumber to the preferredScreens user default array.
    // Also make sure it's only in there once (i.e. remove it first)
    
    NSMutableArray* preferredScreens = [self getPreferredScreens];
    [preferredScreens removeObject:displayNumber];
    // Most recently preferred screens are at the beginning of the array
    [preferredScreens insertObject:displayNumber atIndex:0];
    
    [[NSUserDefaults standardUserDefaults]
     setObject:preferredScreens forKey:@"preferredScreens"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#
# pragma mark received actions
#

- (void)screenWasSelected:(id)sender
{
    [self sendWindowToScreen:(CGDirectDisplayID)[sender tag]];
    [self setPreferredScreen:(CGDirectDisplayID)[sender tag]];
}

- (void)widgetDirDidChange
{
    if (widgetServer){
        // server will restart by itself
        [widgetServer terminate];
    }
}

- (IBAction)showPreferences:(id)sender
{
    [preferences showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [preferences.window makeKeyAndOrderFront:self];
}

- (IBAction)openWidgetDir:(id)sender
{
    [[NSWorkspace sharedWorkspace]openURL:preferences.widgetDir];
}

- (IBAction)visitWidgetGallery:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://tracesof.net/uebersicht-widgets/"]];
}

- (IBAction)refreshWidgets:(id)sender
{
    [window reload];
}

- (IBAction)showDebugConsole:(id)sender
{
    if (!inspector) {
        inspector = [WebInspector.alloc initWithWebView:window.webView];
    }
    
    [window comeToFront];
    [NSApp activateIgnoringOtherApps:YES];
    [inspector show:self];
}

#
# pragma mark debug console handling
#

- (void)aWindowClosed:(NSNotification *)notification
{
    // WebInspcetor might have closed
    if ([@"WebInspectorWindow" isEqual:NSStringFromClass ([[notification object] class])]) {
        [window sendToDesktop];
    }
}

// the inspector might be attached to the webview, in which case we can detect frame changes
- (void)frameChanged:(NSNotification *)notification
{
    if ([notification object] != window.webView.mainFrame.frameView)
        return;

    // make sure the inspector is clickable if attached
    if (CGRectEqualToRect(window.webView.mainFrame.frameView.frame, window.webView.frame)) {
         [window sendToDesktop];
    } else {
         [window comeToFront];
    }
}

@end
