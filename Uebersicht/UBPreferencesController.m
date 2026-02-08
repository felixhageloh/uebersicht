//
//  UBPreferencesController.m
//  Übersicht
//
//  Created by Felix Hageloh on 20/3/14.
//  Copyright (c) 2014 Felix Hageloh.
//
//  Released under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version. See <http://www.gnu.org/licenses/> for
//  details.

#import "UBPreferencesController.h"

@implementation UBPreferencesController {
    LSSharedFileListRef loginItems;
}

@synthesize filePicker;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        
        NSData* defaultWidgetDir = [self ensureDefaultsWidgetDir];
        NSDictionary *appDefaults = @{
            @"widgetDirectory": defaultWidgetDir,
            @"enableInteraction": @YES
        };
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
                
        // watch for login item changes
        loginItems = LSSharedFileListCreate(NULL,
                                            kLSSharedFileListSessionLoginItems,
                                            NULL);
        
        LSSharedFileListAddObserver(loginItems,
                                    CFRunLoopGetMain(),
                                    kCFRunLoopCommonModes,
                                    loginItemsChanged,
                                    (__bridge void*)self);
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [[self.window standardWindowButton:NSWindowMiniaturizeButton] setEnabled:NO];
    [[self.window standardWindowButton:NSWindowZoomButton] setEnabled:NO];
    
    [self widgetDirChanged:self.widgetDir];
}

#
#pragma mark Widget Directory
#

- (IBAction)showFilePicker:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self setWidgetDir:[openPanel URLs][0]];
        }
        
        [self->filePicker selectItemAtIndex:0];
    }];
}

- (NSURL*)widgetDir
{
    NSData* widgetDir = [[NSUserDefaults standardUserDefaults]
                         objectForKey:@"widgetDirectory"];
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:widgetDir];
}

- (void)setWidgetDir:(NSURL*)newDir
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:newDir]
                 forKey:@"widgetDirectory"];
    
    [self widgetDirChanged:newDir];
    [(UBAppDelegate *)[NSApp delegate] widgetDirDidChange];
}

- (void)widgetDirChanged:(NSURL*)url
{
    NSImage *iconImage = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
    [iconImage setSize:NSMakeSize(16,16)];
    
    // TODO: see if we could use bindings for this
    [[filePicker itemAtIndex:0] setTitle: [url path]];
    [[filePicker itemAtIndex:0] setImage:iconImage];
}


- (NSData*)ensureDefaultsWidgetDir
{
    NSArray* urls = [[NSFileManager defaultManager]
        URLsForDirectory:NSApplicationSupportDirectory
        inDomains:NSUserDomainMask
    ];
    
    NSURL* defaultDir = [urls[0]
        URLByAppendingPathComponent:@"Übersicht/widgets"
        isDirectory:YES
    ];
    
    [self createIfNotExists:defaultDir];
    
    return [NSKeyedArchiver archivedDataWithRootObject:defaultDir];
}

- (void)createIfNotExists:(NSURL*)defaultWidgetDir
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    
    if ([fileManager fileExistsAtPath:[defaultWidgetDir path] isDirectory:&isDir] && isDir) {
        return;
    }
    
    NSError* error;
    [fileManager createDirectoryAtURL:defaultWidgetDir
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&error];

    if (error) {
        NSLog(@"%@", error);
        return;
    }
    
    NSURL* gettinStartedWidget = [[NSBundle mainBundle] URLForResource:@"GettingStarted" withExtension:@"jsx"];
    
    [fileManager copyItemAtURL:gettinStartedWidget
                         toURL:[defaultWidgetDir URLByAppendingPathComponent:@"GettingStarted.jsx"]
                         error:&error];
    
    NSURL* logo = [[NSBundle mainBundle] URLForResource:@"übersicht-logo" withExtension:@"png"];
    
    [fileManager copyItemAtURL:logo
                         toURL:[defaultWidgetDir URLByAppendingPathComponent:@"logo.png"]
                         error:&error];
    
    if (error) {
        NSLog(@"%@", error);
    }
    
}

#
#pragma mark Login Shell
#


- (BOOL)loginShell
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"loginShell"];
}

- (void)setLoginShell:(BOOL)enabled
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:@"loginShell"];
    [(UBAppDelegate *)[NSApp delegate] loginShellDidChange];
}


#
#pragma mark Interaction
#


- (BOOL)enableInteraction
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults valueForKey:@"enableInteraction"] boolValue];
}

- (void)setEnableInteraction:(BOOL)enabled
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(enabled) forKey:@"enableInteraction"];
    [(UBAppDelegate *)[NSApp delegate] interactionDidChange];
}

#
#pragma mark Always On Top
#


- (BOOL)alwaysOnTop
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults valueForKey:@"alwaysOnTop"] boolValue];
}

- (void)setAlwaysOnTop:(BOOL)enabled
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(enabled) forKey:@"alwaysOnTop"];
    [(UBAppDelegate *)[NSApp delegate] alwaysOnTopDidChange];
}

#
#pragma mark Startup
#

- (BOOL)startAtLogin
{
    return [self getLoginItem] != NULL;
}

- (void)setStartAtLogin:(BOOL)doStart
{
    if (doStart) {
        NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListInsertItemURL(loginItems,
                                      kLSSharedFileListItemLast,
                                      NULL,
                                      NULL,
                                      (__bridge CFURLRef)bundleURL,
                                      NULL,
                                      NULL);
    } else {
        LSSharedFileListItemRef loginItemRef = [self getLoginItem];
        if (loginItemRef) {
            LSSharedFileListItemRemove(loginItems, loginItemRef);
            CFRelease(loginItemRef);
        }
        
    }
}

- (LSSharedFileListItemRef)getLoginItem
{
    CFArrayRef snapshotRef = LSSharedFileListCopySnapshot(loginItems, NULL);
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
    LSSharedFileListItemRef itemRef = NULL;
    CFURLRef itemURLRef;
    
    for (id item in (__bridge NSArray*)snapshotRef) {
        itemRef = (__bridge LSSharedFileListItemRef)item;
        if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            if ([bundleURL isEqual:((__bridge NSURL *)itemURLRef)]) {
                CFRetain(itemRef);
                break;
            }
        }
        itemRef = NULL;
    }
    
    CFRelease(snapshotRef);
    return itemRef;
}

static void loginItemsChanged(LSSharedFileListRef listRef, void *context)
{
    UBPreferencesController *controller = (__bridge UBPreferencesController*)context;
    
    [controller willChangeValueForKey:@"startAtLogin"];
    [controller didChangeValueForKey:@"startAtLogin"];
}

#
#pragma mark Teardown
#

- (void)dealloc
{
    LSSharedFileListRemoveObserver(loginItems,
                                   CFRunLoopGetMain(),
                                   kCFRunLoopCommonModes,
                                   loginItemsChanged,
                                   (__bridge void*)self);
    CFRelease(loginItems);
}


@end
