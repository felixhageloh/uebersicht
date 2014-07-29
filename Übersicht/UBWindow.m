//
//  UBWindow.m
//  Übersicht
//
//  A window that sits on desktop level, is always fullscreen and doesn't show
//  up in Mission Control
//
//  Created by Felix Hageloh on 20/9/13.
//  Copyright (c) 2013 Felix Hageloh.
//  Released under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version. See <http://www.gnu.org/licenses/> for
//  details.
//

#import "UBWindow.h"

@implementation UBWindow {
    NSURL *prevWallpaperUrl;
    NSDictionary *prevWallpaperOptions;
}

@synthesize webView;

- (id) initWithContentRect:(NSRect)contentRect
                 styleMask:(NSUInteger)aStyle
                   backing:(NSBackingStoreType)bufferingType
                     defer:(BOOL)flag
{

    self = [super initWithContentRect:contentRect
                            styleMask:NSBorderlessWindowMask
                              backing:bufferingType
                                defer:flag];

    if (self) {
        [self setBackgroundColor:[NSColor clearColor]];
        [self setOpaque:NO];
        [self setLevel:kCGDesktopWindowLevel];
        [self setCollectionBehavior:(NSWindowCollectionBehaviorTransient |
                                     NSWindowCollectionBehaviorCanJoinAllSpaces |
                                     NSWindowCollectionBehaviorIgnoresCycle)];

        [self setRestorable:NO];
        [self disableSnapshotRestoration];
        [self setDisplaysWhenScreenProfileChanges:YES];


        [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self
                                                             selector:@selector(onWorkspaceChange:)
                                                                 name:NSWorkspaceActiveSpaceDidChangeNotification
                                                               object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(wakeFromSleep:)
                                                     name:NSWorkspaceDidWakeNotification
                                                   object:nil];
    }


    return self;
}

- (void) awakeFromNib
{
    [self initWebView];
    prevWallpaperUrl = [[[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[self screen]] absoluteURL];
    prevWallpaperOptions =  [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:[self screen]];
}

- (void)initWebView
{

    [webView setDrawsBackground:NO];
    [webView setMaintainsBackForwardList:NO];
    [webView setFrameLoadDelegate:self];
}

- (void)loadUrl:(NSString*)url
{
    [webView setMainFrameURL:url];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (frame == [frame findFrameNamed:@"_top"]) {
        [[webView windowScriptObject] setValue:self forKey:@"os"];
    }
}

- (void)fillScreen:(CGDirectDisplayID)screenId
{
    NSRect fullscreen = [self toQuartzCoordinates:CGDisplayBounds(screenId)];
    int menuBarHeight = [[NSApp mainMenu] menuBarHeight];

    fullscreen.size.height = fullscreen.size.height - menuBarHeight;
    [self setFrame:fullscreen display:YES];
    [self onWorkspaceChange:nil];
}

// old coordinate system is flipped
- (NSRect)toQuartzCoordinates:(NSRect)screenRect
{
    CGRect mainScreenRect = CGDisplayBounds (CGMainDisplayID ());

    screenRect.origin.y = -1 * (screenRect.origin.y + screenRect.size.height - mainScreenRect.size.height);
    
    return screenRect;
}

- (NSData*)wallpaper
{
    CGImageRef cgImage = CGWindowListCreateImage([self toQuartzCoordinates:self.screen.frame],
                                                 kCGWindowListOptionOnScreenBelowWindow,
                                                 (CGWindowID)[self windowNumber],
                                                 kCGWindowImageDefault);
    
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return [bitmapRep representationUsingType:NSPNGFileType properties:nil];
}
    
- (NSString*)wallpaperDataUrl
{
    NSString *base64 = [self.wallpaper base64EncodedStringWithOptions:0];

    
    return [@"data:image/png;base64, " stringByAppendingString:base64];
}

- (void)onWorkspaceChange:(id)sender
{
    NSURL *currWallpaperUrl  = [[[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[self screen]] absoluteURL];
    NSDictionary *currWallpaperOptions = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:[self screen]];

    if (![prevWallpaperUrl isEqual:currWallpaperUrl] ||
        ![prevWallpaperOptions isEqualToDictionary:currWallpaperOptions]) {
        [self wallpaperChanged];
    }
    prevWallpaperUrl = currWallpaperUrl;
    prevWallpaperOptions = currWallpaperOptions;
}

- (void)wallpaperChanged
{
    [[webView windowScriptObject] evaluateWebScript:@"window.dispatchEvent(new Event('onwallpaperchange'))"];
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(wallpaperDataUrl)) {
        return NO;
    }

    return YES;
}

- (void)wakeFromSleep:(NSNotification *)notification
{
    [webView reload:self];
}

@end
