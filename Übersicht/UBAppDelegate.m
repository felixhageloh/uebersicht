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

@implementation UBAppDelegate {
    NSStatusItem* statusBarItem;
    NSTask* widgetServer;
    UBPreferencesController* preferences;
    BOOL keepServerAlive;
    WebInspector *inspector;
    uint32 lastScreenNumber;
}

@synthesize window;
@synthesize statusBarMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    statusBarItem = [self addStatusItemToMenu: statusBarMenu];
    preferences   = [[UBPreferencesController alloc] initWithWindowNibName:@"UBPreferencesController"];
    
    if ([NSScreen.screens count] > 1)
        [self addScreensToMenu:statusBarMenu];
    
    [self sendWindowToScreen:CGMainDisplayID()];

    keepServerAlive = YES;
    [self startServer];
    
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
}

- (void)startServer
{
    NSLog(@"starting server task");

    void (^parseOutput)(NSString *) = ^(NSString* output) {
        if ([output rangeOfString:@"server started"].location != NSNotFound) {
            [window loadUrl:@"http://localhost:41416"];
        } else if ([output rangeOfString:@"error"].location != NSNotFound) {
            [self notifyUser:output withTitle:@"Error"];
        }
    };

    void (^keepAlive)(NSTask*) = ^(NSTask* theTask) {
        if (keepServerAlive) {
            [self startServer];
        }
    };

    widgetServer = [self launchWidgetServer:[preferences.widgetDir path]
                                     onData:parseOutput
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

    [item setImage:[[NSBundle mainBundle] imageForResource:@"status-icon"]];
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

    // NSTask doesn't terminate when xcode stop is pressed. Other ways of spawning
    // the server, like system() or popen() have the same problem.
    // So, hit em with a hammer :(
    system("killall localnode");

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:nodePath];
    [task setArguments:@[serverPath, @"-d", widgetPath]];


    NSPipe* nodeout = [NSPipe pipe];
    [task setStandardOutput:nodeout];
    [[nodeout fileHandleForReading] waitForDataInBackgroundAndNotify];

    void (^callback)(NSNotification *) = ^(NSNotification *notification) {
        NSData *output   = [[nodeout fileHandleForReading] availableData];
        NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];

        dataHandler(outStr);

        NSLog(@"%@", outStr);
        [[nodeout fileHandleForReading] waitForDataInBackgroundAndNotify];
    };

    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification
                                                      object:[nodeout fileHandleForReading]
                                                       queue:nil
                                                  usingBlock:callback];


    task.terminationHandler = ^(NSTask *theTask) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        dispatch_async(dispatch_get_main_queue(), ^{
            exitHandler(theTask);
        });
    };

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

    NSInteger index = [self indexOfScreenMenuItems:menu];
    newItem = [NSMenuItem separatorItem];
    [newItem setRepresentedObject:@"screen"];
    [menu insertItem:newItem atIndex:index];
    
    CGDirectDisplayID displays[20];
    uint32_t numDisplays;
    
    CGGetActiveDisplayList(20, displays, &numDisplays);
    
    for(int i = 0; i < numDisplays; i++) {
        if (CGDisplayIsInMirrorSet(displays[i]))
            continue;
        
        name = [self screenNameForDisplay:displays[i]];
        if (!name)
            name = [NSString stringWithFormat:@"Display %i", i];

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
    CFDictionaryRef info;
    io_iterator_t iter;
    io_service_t serv;
    
    CFMutableDictionaryRef matching = IOServiceMatching("IODisplayConnect");
    
    // releases matching for us
    kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iter);
    if (err) return NULL;
    
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
    CGDirectDisplayID displays[20];
    uint32_t numDisplays;
    uint32 screenId;
    BOOL foundScreenAgain = NO;
    
    CGGetActiveDisplayList(20, displays, &numDisplays);

    [self removeScreensFromMenu:statusBarMenu];
    
    if (numDisplays > 1)
        [self addScreensToMenu:statusBarMenu];
    
    for (int i = 0; i < numDisplays; i++) {
        screenId = displays[i];
        if (CGDisplayIsInMirrorSet(screenId))
            continue;
        
        if (lastScreenNumber == CGDisplayUnitNumber(screenId)) {
            foundScreenAgain = YES;
            [self sendWindowToScreen:screenId];
        }
    }
    
    if (!foundScreenAgain)
        [self sendWindowToScreen:CGMainDisplayID()];
        
}

- (void)sendWindowToScreen:(CGDirectDisplayID)screenId
{
    CGRect screenRect = CGDisplayBounds(screenId);
    CGRect mainScreenRect = CGDisplayBounds (CGMainDisplayID ());
    // flip coordinates
    screenRect.origin.y = -1 * (screenRect.origin.y + screenRect.size.height - mainScreenRect.size.height);
    
    [window fillScreen:screenRect];
    lastScreenNumber = CGDisplayUnitNumber(screenId);
    
    [self markScreen:screenId inMenu:statusBarMenu];
}


#
# pragma mark received actions
#

- (void)screenWasSelected:(id)sender
{
    [self sendWindowToScreen:(CGDirectDisplayID)[sender tag]];
}

- (void)widgetDirDidChange
{
    if (widgetServer){
        // server will restart by itself
        [widgetServer terminate];
    } else {
        [self startServer];
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

- (IBAction)refreshWidgets:(id)sender
{
    [window.webView reload:sender];
}

- (IBAction)showDebugConsole:(id)sender
{
    if (!inspector) {
        inspector = [WebInspector.alloc initWithWebView:window.webView];
    }

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
        [window setLevel:kCGDesktopWindowLevel];
    }
}

// the inspector might be attached to the webview, in which case we can detect frame changes
- (void)frameChanged:(NSNotification *)notification
{
    if ([notification object] != window.webView.mainFrame.frameView)
        return;

    // make sure the inspector is clickable if attached
    if (CGRectEqualToRect(window.webView.mainFrame.frameView.frame, window.webView.frame)) {
         [window setLevel:kCGDesktopWindowLevel];
    } else {
         [window setLevel:kCGNormalWindowLevel-1];
    }
}

@end
