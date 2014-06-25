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
    uint32 lastScreen;
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

-(NSInteger)indexOfScreenMenuItems:(NSMenu*)menu
{
    return [menu indexOfItem:[menu itemWithTitle:@"Check for Updates..."]] + 2;
}

- (void)addScreensToMenu:(NSMenu*)menu
{
    NSString *title;
    NSMenuItem *newItem;

    NSInteger index = [self indexOfScreenMenuItems:menu];
    newItem = [NSMenuItem separatorItem];
    [newItem setRepresentedObject:@"screen"];
    [menu insertItem:newItem atIndex:index];
    
    CGDirectDisplayID displays[20];
    uint32_t numDisplays;
    
    CGGetActiveDisplayList(20, displays, &numDisplays);
    
    int screenIdx = 1;
    for(int i = 0; i < numDisplays; i++) {
        if (CGDisplayIsInMirrorSet(displays[i]))
            continue;
        
        title   = [NSString stringWithFormat:@"Show in Display %u", screenIdx];
        newItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(screenWasSelected:) keyEquivalent:@""];
        
        [newItem setState:(displays[i] == [self getScreenId:window.screen] ? NSOnState : NSOffState)];
        [newItem setTag:displays[i]];
        [newItem setRepresentedObject:@"screen"];
        [menu insertItem:newItem atIndex:index+i];
        
        screenIdx++;
    }
}

- (void)removeScreensFromMenu:(NSMenu*)menu
{
    for (NSMenuItem *item in [menu itemArray]){
        if ([item.representedObject isEqualToString:@"screen"]) {
            [menu removeItem:item];
        }
    }
}

- (void)screenWasSelected:(id)sender
{
    NSMenu *menu = [sender menu];
    
    NSInteger index = [self indexOfScreenMenuItems:menu];
    NSInteger lastIndex = index + [NSScreen.screens count];
    
    for (;index < lastIndex; index++) {
        [[menu itemAtIndex:index] setState:NSOffState];
    }
    
    [sender setState:NSOnState];
    [self sendWindowToScreen:(CGDirectDisplayID)[sender tag]];
}

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
        
        if (lastScreen == CGDisplayUnitNumber(screenId)) {
            foundScreenAgain = YES;
            [self sendWindowToScreen:screenId];
        }
    }
    
    if (!foundScreenAgain)
        [self sendWindowToScreen:CGMainDisplayID()];
        
}

- (CGDirectDisplayID)getScreenId:(NSScreen*) screen
{
    return [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
}

- (void)sendWindowToScreen:(CGDirectDisplayID)screenId
{
    CGRect screenRect = CGDisplayBounds(screenId);
    CGRect  mainScreenRect = CGDisplayBounds (CGMainDisplayID ());
    // flip coordinates
    screenRect.origin.y = -1 * (screenRect.origin.y + screenRect.size.height - mainScreenRect.size.height);
    
    [window fillScreen:screenRect];
    lastScreen = CGDisplayUnitNumber(screenId);
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

- (void)notifyUser:(NSString*)message withTitle:(NSString*)title
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
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

- (IBAction)showDebugConsole:(id)sender
{
    if (!inspector) {
        inspector = [WebInspector.alloc initWithWebView:window.webView];
    }

    [inspector show:self];
    [window setLevel:kCGNormalWindowLevel-1];

}

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
