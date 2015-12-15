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
#import "UBScreensController.h"
#import "WebInspector.h"
#import "UBMouseHandler.h"
#import "UBWidgetsController.h"

int const PORT = 41416;

@implementation UBAppDelegate {
    NSStatusItem* statusBarItem;
    NSTask* widgetServer;
    UBPreferencesController* preferences;
    UBScreensController* screensController;
    BOOL keepServerAlive;
    WebInspector *inspector;
    int portOffset;
    UBMouseHandler* mouseHandler;
    UBWidgetsController* widgetsController;
}

@synthesize window;
@synthesize statusBarMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    statusBarItem = [self addStatusItemToMenu: statusBarMenu];
    screensController = [[UBScreensController alloc]
        initWithChangeListener:self
    ];
    preferences = [[UBPreferencesController alloc]
        initWithWindowNibName:@"UBPreferencesController"
    ];
    
    
    // NSTask doesn't terminate when xcode stop is pressed. Other ways of
    // spawning the server, like system() or popen() have the same problem.
    // So, hit em with a hammer :(
    system("killall localnode");
    
    // start server and load webview
    portOffset = 0;
    keepServerAlive = YES;
    
    [self startServer: ^(NSString* output) {
        NSRange match;
        
        if ([output rangeOfString:@"server started"].location != NSNotFound) {
            widgetsController = [[UBWidgetsController alloc]
                initWithMenu:statusBarMenu
                     screens:screensController
                settingsPath:[self getPreferencesDir]
                     baseUrl:[self baseUrl]
            ];
        
            [self renderOnScreens];
        } else if ([output rangeOfString:@"EADDRINUSE"].location != NSNotFound) {
            portOffset++;
            if (portOffset >= 20) {
                keepServerAlive = NO;
                NSLog(@"couldn't find an open port. Giving up...");
            }
        } else if ([output rangeOfString:@"error"].location != NSNotFound) {
            [self notifyUser:output withTitle:@"Error"];
        } else if ((match = [output rangeOfString:@"registering widget"]).location != NSNotFound) {
            [widgetsController
                addWidget:[self getWidgetId:output outsideRange:match]
            ];
        } else if ((match =[output rangeOfString:@"deleting widget"]).location != NSNotFound) {
             [widgetsController
                removeWidget:[self getWidgetId:output outsideRange:match]
            ];
        };
    }];
    
    // enable the web inspector
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // listen for keyboard events
    mouseHandler = [[UBMouseHandler alloc]
        initWithWindow:window
        andPreferences:preferences
    ];
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
    [[NSStatusBar systemStatusBar] removeStatusItem:statusBarItem];
    
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
    [task setArguments:@[
        serverPath,
        @"-d", widgetPath,
        @"-p", [NSString stringWithFormat:@"%d", PORT + portOffset],
        @"-s", [[self getPreferencesDir] path]
        
    ]];
    
    [task launch];
    return task;
}

- (void)notifyUser:(NSString*)message withTitle:(NSString*)title
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter]
        deliverNotification:notification
    ];
}


- (NSURL*)getPreferencesDir
{
    NSArray* urls = [[NSFileManager defaultManager]
        URLsForDirectory:NSApplicationSupportDirectory
               inDomains:NSUserDomainMask
    ];
    
    return [urls[0]
        URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]
                        isDirectory:YES
    ];
}

- (NSString*)getWidgetId:(NSString*)output outsideRange:(NSRange)range
{
    NSString* widgetId = [output
        stringByReplacingCharactersInRange:range withString:@""
    ];

    return [widgetId
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
    ];
}

- (NSString*)baseUrl
{
    // trailing slash required for load policy in UBWindow
   return [NSString
        stringWithFormat:@"http://127.0.0.1:%d/", PORT+portOffset
    ];
}

#
#pragma mark Screen Handling
#

- (void)sreensChanged:(NSDictionary*)screens
{
    if (widgetsController) {
        [widgetsController screensChanged:screens];
        [self renderOnScreens];
    }
}

- (void)renderOnScreens
{
    for(id key in [screensController screens]) {
        [window fillScreen:[(NSNumber*)key unsignedIntValue]];
        [window loadUrl:[self baseUrl]];
    }
}

#
# pragma mark received actions
#

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
    [[NSWorkspace sharedWorkspace]
        openURL:[NSURL URLWithString:@"http://tracesof.net/uebersicht-widgets/"]
    ];
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
    [[NSUserDefaults standardUserDefaults]
        setBool:NO
         forKey:@"WebKit Web Inspector Setting - inspectorStartsAttached"
    ];
    
    [NSApp activateIgnoringOtherApps:YES];
    [inspector show:self];
}


@end
