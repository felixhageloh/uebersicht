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
    NSString *widgetsUrl;
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
        [self sendToDesktop];
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
    [webView setResourceLoadDelegate:self];
}

- (void)loadUrl:(NSString*)url
{
    widgetsUrl = url;
    [webView setMainFrameURL:url];
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

- (void)wakeFromSleep:(NSNotification *)notification
{
    [webView reloadFromOrigin:self];
}

#
#pragma mark window control
#

- (void)fillScreen:(CGDirectDisplayID)screenId
{
    NSRect fullscreen = [self toQuartzCoordinates:CGDisplayBounds(screenId)];
    int menuBarHeight = [[NSApp mainMenu] menuBarHeight];
    
    fullscreen.size.height = fullscreen.size.height - menuBarHeight;
    [self setFrame:fullscreen display:YES];
    [self onWorkspaceChange:nil];
}

- (void)sendToDesktop
{
    [self setLevel:kCGDesktopWindowLevel];
}

- (void)comeToFront
{
    [self setLevel:kCGNormalWindowLevel-1];
    [self makeKeyAndOrderFront:self];
}

- (BOOL)isInFront
{
    return self.level == kCGNormalWindowLevel-1;
}

#
#pragma mark WebView delegates
#

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    NSLog(@"loaded %@", webView.mainFrameURL);
    if (frame == [frame findFrameNamed:@"_top"]) {
        [[webView windowScriptObject] setValue:self forKey:@"os"];
    }
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame
{
    [self handleWebviewLoadError:error];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame {
    [self handleWebviewLoadError:error];
}

- (NSURLRequest*)webView:(WebView *)sender resource:(id)identifier
         willSendRequest:(NSURLRequest *)request
        redirectResponse:(NSURLResponse *)redirectResponse
          fromDataSource:(WebDataSource *)dataSource
{
    if ([request.mainDocumentURL.host isEqualToString: @"localhost"]) {
        return request;
    } else {
        [[NSWorkspace sharedWorkspace] openURL:request.URL];
        return [NSURLRequest requestWithURL:[NSURL URLWithString:widgetsUrl]];
    }
}

- (void)handleWebviewLoadError:(NSError *)error
{
    NSURL* url = [error.userInfo objectForKey:@"NSErrorFailingURLKey"];
    NSLog(@"%@ failed to load: %@ Reloading...", url, error.localizedDescription);
    
    [self performSelector:@selector(loadUrl:) withObject:url.absoluteString
               afterDelay:5.0];
}

#
#pragma mark wallpaper methods
#

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

// old coordinate system is flipped
- (NSRect)toQuartzCoordinates:(NSRect)screenRect
{
    CGRect mainScreenRect = CGDisplayBounds (CGMainDisplayID ());
    
    screenRect.origin.y = -1 * (screenRect.origin.y + screenRect.size.height - mainScreenRect.size.height);
    
    return screenRect;
}


- (void)wallpaperChanged
{
    [[webView windowScriptObject] evaluateWebScript:@"window.dispatchEvent(new Event('onwallpaperchange'))"];
}


#
#pragma mark WebscriptObject
#

- (NSString*)wallpaperDataUrl
{
    NSString *base64 = [self.wallpaper base64EncodedStringWithOptions:0];
    return [@"data:image/png;base64, " stringByAppendingString:base64];
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(wallpaperDataUrl)) {
        return NO;
    }

    return YES;
}

#
#pragma mark flags
#

- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder { return YES; }
- (BOOL)resignFirstResponder { return YES; }
- (BOOL)acceptsMouseMovedEvents { return YES; }

@end
