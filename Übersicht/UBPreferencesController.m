//
//  UBPreferencesController.m
//  Übersicht
//
//  Created by Felix Hageloh on 20/3/14.
//  Copyright (c) 2014 tracesOf. All rights reserved.
//

#import "UBPreferencesController.h"

@implementation UBPreferencesController {
    LSSharedFileListRef loginItems;
}

@synthesize filePicker;
@synthesize toolbar;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        
        // set default widget dir and create it if it doesn't exist
        [self setDefaultWidgetDir];
        
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
    
//    [self.window setLevel:NSFloatingWindowLevel];
    
    [[self.window standardWindowButton:NSWindowMiniaturizeButton] setEnabled:NO];
    [[self.window standardWindowButton:NSWindowZoomButton] setEnabled:NO];
    
    [toolbar setSelectedItemIdentifier:@"general"];
    [self widgetDirChanged:self.widgetDir];
}

#
#pragma mark Widget Directory
#

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
    [filePicker selectItemAtIndex:0];
}

- (IBAction)showFilePicker:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];

    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
             [self setWidgetDir:[openPanel URLs][0]];
        }
    }];
}

- (void)setDefaultWidgetDir
{
    NSArray* urls = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                           inDomains:NSUserDomainMask];
    
    NSURL* defaultDir  = [urls[0] URLByAppendingPathComponent:@"Übersicht/widgets"
                                                  isDirectory:YES];
    
    [self createIfNotExists:defaultDir];
    
    NSData* encodedDir = [NSKeyedArchiver archivedDataWithRootObject:defaultDir];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:encodedDir
                                                            forKey:@"widgetDirectory"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
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
    
    NSURL* gettinStartedWidget = [[NSBundle mainBundle] URLForResource:@"getting-started" withExtension:@"coffee"];
    
    [fileManager copyItemAtURL:gettinStartedWidget
                         toURL:[defaultWidgetDir URLByAppendingPathComponent:@"getting-started.coffee"]
                         error:&error];
    
    NSURL* logo = [[NSBundle mainBundle] URLForResource:@"übersicht-logo" withExtension:@"png"];
    
    [fileManager copyItemAtURL:logo
                         toURL:[defaultWidgetDir URLByAppendingPathComponent:@"übersicht-logo.png"]
                         error:&error];
    
    if (error) {
        NSLog(@"%@", error);
    }
    
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
