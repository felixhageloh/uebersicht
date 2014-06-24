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
}

@synthesize mainView;
@synthesize statusBarMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [mainView setDrawsBackground:NO];
    [mainView setMaintainsBackForwardList:NO];
    
    statusBarItem = [self addStatusItemToMenu: statusBarMenu];
    preferences   = [[UBPreferencesController alloc] initWithWindowNibName:@"UBPreferencesController"];
    
    keepServerAlive = YES;
    [self startServer];
    
    // enable the web inspector
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wakeFromSleep:)
                                                 name:NSWorkspaceDidWakeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(frameChanged:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:nil];
}

- (void)startServer
{
    NSLog(@"starting server task");
    
    [mainView setHidden:YES];
    void (^parseOutput)(NSString *) = ^(NSString* output) {
        if ([output rangeOfString:@"server started"].location != NSNotFound) {
            [mainView setMainFrameURL:@"http://localhost:41416"];
            [mainView setHidden:NO];
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
        inspector = [WebInspector.alloc initWithWebView:mainView];
    }
    
    [inspector show:self];

}

// the inspector might be attached to the webview, in which case we can detect frame changes
- (void)frameChanged:(NSNotification *)notification
{
    if ([notification object] != [[mainView mainFrame] frameView])
        return;
    
    
    if (CGRectEqualToRect(mainView.mainFrame.frameView.frame, mainView.frame)) {
         [mainView.window setLevel:kCGDesktopWindowLevel];
    } else {
         [mainView.window setLevel:kCGNormalWindowLevel-1];
    }
        
    
}

- (void)wakeFromSleep:(NSNotification *)notification
{
    [mainView reload:self];
}

@end
