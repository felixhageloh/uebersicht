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
#import "UBWidgetsController.h"
#import "UBWidgetsStore.h"
#import "UBWebSocket.h"
#import "UBWindowsController.h"

int const PORT = 41416;

@implementation UBAppDelegate {
    NSStatusItem* statusBarItem;
    NSTask* widgetServer;
    UBPreferencesController* preferences;
    UBScreensController* screensController;
    UBWindowsController* windowsController;
    BOOL shuttingDown;
    BOOL keepServerAlive;
    int portOffset;
    UBWidgetsStore* widgetsStore;
    UBWidgetsController* widgetsController;
    BOOL needsRefresh;
    NSString *token;
}

@synthesize statusBarMenu;

static const uint kTokenLength256Bits = 32;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    needsRefresh = YES;
    statusBarItem = [self addStatusItemToMenu: statusBarMenu];
    preferences = [[UBPreferencesController alloc]
        initWithWindowNibName:@"UBPreferencesController"
    ];

    // NSTask doesn't terminate when xcode stop is pressed. Other ways of
    // spawning the server, like system() or popen() have the same problem.
    // So, hit em with a hammer :(
    system("killall -m node-");
    
    widgetsStore = [[UBWidgetsStore alloc] init];

    screensController = [[UBScreensController alloc]
        initWithChangeListener:self
    ];
    
    windowsController = [[UBWindowsController alloc] init];
    
    widgetsController = [[UBWidgetsController alloc]
        initWithMenu: statusBarMenu
        widgets: widgetsStore
        screens: screensController
        preferences: preferences
    ];
    [widgetsStore onChange: ^(NSDictionary* widgets) {
        [self->widgetsController render];
    }];
    
    // make sure notifcations always show
    NSUserNotificationCenter* unc = [NSUserNotificationCenter
        defaultUserNotificationCenter
    ];
    unc.delegate = self;
    

    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver: self
        selector: @selector(wakeFromSleep:)
        name: NSWorkspaceDidWakeNotification
        object: nil
    ];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver: self
        selector: @selector(workspaceChanged:)
        name: NSWorkspaceActiveSpaceDidChangeNotification
        object: nil
    ];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver: self
        selector: @selector(loginSessionBecameActive:)
        name: NSWorkspaceSessionDidBecomeActiveNotification
        object: nil
    ];
 
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver: self
        selector: @selector(loginSessionResigned:)
        name: NSWorkspaceSessionDidResignActiveNotification
        object: nil
    ];
    
    // start server and load webview
    portOffset = 0;
    [self startUp];
    
    [self listenToWallpaperChanges];
}

- (void)fetchState:(void (^)(NSDictionary*))callback
{
    [[UBWebSocket sharedSocket] open:[self serverUrl:@"ws"]
                               token:token];

    NSURL *urlPath = [[self serverUrl:@"http"] URLByAppendingPathComponent: @"state/"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:urlPath];
    [request setValue:@"Übersicht" forHTTPHeaderField:@"Origin"];
    [request setValue:[NSString stringWithFormat:@"token=%@", token] forHTTPHeaderField:@"Cookie"];
    NSURLSessionDataTask *t = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"error loading state: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@{});
            });
            return;
        }

        NSError *jsonError = nil;
        NSDictionary *dataDictionary = [NSJSONSerialization
            JSONObjectWithData: data
            options: NSJSONReadingMutableContainers
            error: &jsonError
        ];
        if (jsonError) {
            NSLog(@"error parsing state: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@{});
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            callback(dataDictionary);
        });
    }];
    [t resume];
}

- (void)startUp
{

    NSLog(@"starting server task");

    void (^handleData)(NSString*) = ^(NSString* output) {
        // note that these might be called several times
        if ([output rangeOfString:@"server started"].location != NSNotFound) {
            [self fetchState:^(NSDictionary* state) {
                [self->widgetsStore reset: state];
                // this will trigger a render
                [self->screensController syncScreens:self];
            }];
        } else if ([output rangeOfString:@"EADDRINUSE"].location != NSNotFound) {
            self->portOffset++;
        }
    };

    void (^handleExit)(NSTask*) = ^(NSTask* theTask) {
        if (!self->shuttingDown) {
            [self shutdown];
        }
        if (self->portOffset >= 20) {
            self->keepServerAlive = NO;
            NSLog(@"couldn't find an open port. Giving up...");
        }
        if (self->keepServerAlive) {
            [self
                performSelector: @selector(startUp)
                withObject: nil
                afterDelay: 1.0
            ];
        }
    };
    
    shuttingDown = NO;
    keepServerAlive = YES;
    widgetServer = [self
        launchWidgetServer: [preferences.widgetDir path]
        onData: handleData
        onExit: handleExit
    ];
}

- (void)shutdown:(Boolean)keepAlive
{
    if (shuttingDown) {
        return;
    }
    shuttingDown = YES;

    keepServerAlive = keepAlive;
    [windowsController closeAll];
    [[UBWebSocket sharedSocket] close];
    if (widgetServer){
        [widgetServer terminate];
    }
}

- (void)shutdown
{
    [self shutdown:false];
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
    [item.button setImage: image];
    [item setMenu:aMenu];
    [item setEnabled:YES];

    return item;
}

- (NSTask*)launchWidgetServer:(NSString*)widgetPath
                       onData:(void (^)(NSString*))dataHandler
                       onExit:(void (^)(NSTask*))exitHandler
{
    token = generateToken(kTokenLength256Bits);

    NSBundle* bundle     = [NSBundle mainBundle];
    NSString* nodePath   = [bundle pathForResource:@"localnode" ofType:nil];
    NSString* serverPath = [bundle pathForResource:@"server" ofType:@"js"];

    NSTask *task = [[NSTask alloc] init];

    NSPipe *inPipe = [NSPipe pipe];
    NSFileHandle *fh = [inPipe fileHandleForWriting];
    NSMutableDictionary *secrets = [[NSMutableDictionary alloc] init];
    secrets[@"token"] = token;
    NSError *jsonErr = NULL;
    NSData *stdinData = [NSJSONSerialization dataWithJSONObject:secrets options:0 error:&jsonErr];
    if (!stdinData) {
        NSLog(@"[FATAL] %@", jsonErr);
        return NULL;
    }
    [fh writeData:stdinData];
    [fh closeFile];
    [task setStandardInput:inPipe];

    [task setStandardOutput:[NSPipe pipe]];
    [task.standardOutput fileHandleForReading].readabilityHandler = ^(NSFileHandle *handle) {
        NSData *output = [handle availableData];
        NSString *outStr = [[NSString alloc]
            initWithData:output
            encoding:NSUTF8StringEncoding
        ];
        
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
        @"-s", [[self getPreferencesDir] path],
        !preferences.enableSecurity ? @"--disable-token" : @"",
        preferences.loginShell ? @"--login-shell" : @""
    ]];
    
    [task launch];
    return task;
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

- (NSURL*)serverUrl:(NSString*)protocol
{
    // trailing slash required for load policy in UBWindow
    return [NSURL
        URLWithString:[NSString
            stringWithFormat:@"%@://127.0.0.1:%d/", protocol, PORT+portOffset
        ]
    ];
}


#
#pragma mark Screen Handling
#

- (void)screensChanged:(NSDictionary*)screens
{
    if (widgetsController) {
        [windowsController
            updateWindows:screens
            baseUrl: [self serverUrl: @"http"]
            token:token
            interactionEnabled: preferences.enableInteraction
            forceRefresh: needsRefresh
        ];
        needsRefresh = NO;
    }
}

#
# pragma mark received actions
#


- (void)widgetDirDidChange
{
    [self shutdown:true];
}

- (void)loginShellDidChange
{
    [self shutdown:true];
}

- (void)interactionDidChange
{
    [windowsController closeAll];
    needsRefresh = YES;
    [screensController syncScreens:self];
}

- (void)enableSecurityDidChange
{
    [self shutdown:true];
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
    needsRefresh = YES;
    [screensController syncScreens:self];
}

- (IBAction)showDebugConsole:(id)sender
{
    NSNumber* currentScreen = [[NSScreen mainScreen]
        deviceDescription
    ][@"NSScreenNumber"];
    
    [windowsController showDebugConsolesForScreen:currentScreen];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)wakeFromSleep:(NSNotification *)notification
{
    [windowsController reloadAll];
}

- (void)workspaceChanged:(NSNotification *)notification
{
    [windowsController workspaceChanged];
}

- (void)wallpaperChanged:(NSNotification *)notification
{
    [windowsController wallpaperChanged];
}

- (void)loginSessionBecameActive:(NSNotification *)notification
{
    [self startUp];
}

- (void)loginSessionResigned:(NSNotification *)notification
{
    [self shutdown];
}


- (void)listenToWallpaperChanges
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
        NSLibraryDirectory,
        NSUserDomainMask,
        YES
    );
    
    CFStringRef path = (__bridge CFStringRef)[paths[0]
        stringByAppendingPathComponent:@"/Application Support/Dock/"
    ];
    
    FSEventStreamContext context = {
        0,
        (__bridge void *)(self), NULL, NULL, NULL
    };
    FSEventStreamRef stream;
    
    stream = FSEventStreamCreate(
        NULL,
        &wallpaperSettingsChanged,
        &context,
        CFArrayCreate(NULL, (const void **)&path, 1, NULL),
        kFSEventStreamEventIdSinceNow,
        0,
        kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
    );
    
    FSEventStreamScheduleWithRunLoop(
        stream,
        CFRunLoopGetCurrent(),
        kCFRunLoopDefaultMode
    );
    FSEventStreamStart(stream);

}

void wallpaperSettingsChanged(
    ConstFSEventStreamRef streamRef,
    void *this,
    size_t numEvents,
    void *eventPaths,
    const FSEventStreamEventFlags eventFlags[],
    const FSEventStreamEventId eventIds[]
)
{
    CFStringRef path;
    CFArrayRef  paths = eventPaths;

    for (int i=0; i < numEvents; i++) {
        path = CFArrayGetValueAtIndex(paths, i);
        if (CFStringFindWithOptions(path, CFSTR("desktoppicture.db"),
                                    CFRangeMake(0,CFStringGetLength(path)),
                                    kCFCompareCaseInsensitive,
                                    NULL) == true) {
            [(__bridge UBAppDelegate*)this
                performSelector:@selector(wallpaperChanged:)
                withObject:nil
                afterDelay:0.5
            ];
        }
    }
}

/*!
    @function generateToken

    @abstract
    Returns a base64-encoded @p NSString* of specified number of random bytes.

    @param length
    A reasonably large, non-zero number representing the length in bytes.
    For example, a value of 32 would generate a 256-bit token.

    @result Returns @p NSString* on success; panics on failure.
*/
NSString* generateToken(uint length) {
    UInt8 buf[length];

    int error = SecRandomCopyBytes(kSecRandomDefault, length, &buf);
    if (error != errSecSuccess) {
        panic("failed to generate token");
    }

    return [[NSData dataWithBytes:buf length:length] base64EncodedStringWithOptions:0];
}

#
# pragma mark script support
#

- (NSArray*)getWidgets
{
   return [widgetsController widgetsForScripting];
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
    return [key isEqualToString:@"widgets"];
}

- (void)reloadWidget:(NSString*)widgetId
{
    [widgetsController reloadWidget:widgetId];
}

@end
