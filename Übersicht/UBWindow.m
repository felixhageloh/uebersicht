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
#import "UBWallperServer.h"

@implementation UBWindow {
    NSString *widgetsUrl;
    UBWallperServer* wallpaperServer;
    BOOL webviewLoaded;
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(wakeFromSleep:)
                                                     name:NSWorkspaceDidWakeNotification
                                                   object:nil];
    }


    return self;
}

- (void) awakeFromNib
{
    wallpaperServer = [[UBWallperServer alloc] initWithWindow:self];
    [wallpaperServer onWallpaperChange:^{
        [self notifyWebviewOfWallaperChange];
    }];
    
    [self initWebView];
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
    widgetsUrl    = url;
    webviewLoaded = NO;
    [webView setMainFrameURL:url];
}

- (void)reload
{
    webviewLoaded = NO;
    [webView reloadFromOrigin:self];
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

- (NSRect)toQuartzCoordinates:(NSRect)screenRect
{
    CGRect mainScreenRect = CGDisplayBounds (CGMainDisplayID ());
    
    screenRect.origin.y = -1 * (screenRect.origin.y + screenRect.size.height -
                                mainScreenRect.size.height);
    
    return screenRect;
}

#
#pragma mark WebView delegates
#

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    NSLog(@"loaded %@", webView.mainFrameURL);
    if (frame == [frame findFrameNamed:@"_top"]) {
        [[webView windowScriptObject] setValue:self forKey:@"os"];
        [self notifyWebviewOfWallaperChange];
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
    // Title is blank means we are requesting a new website.
    // Only way I found so far to check whether we are navigating away.
    if (dataSource.pageTitle || (!dataSource.pageTitle && !webviewLoaded)) {
        webviewLoaded = YES;
        return request;
    } else {
        NSLog(@"delegating");
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
#pragma mark WebscriptObject
#

- (void)notifyWebviewOfWallaperChange
{
    [[webView windowScriptObject]
        evaluateWebScript:@"window.dispatchEvent(new Event('onwallpaperchange'))"];
}

- (NSString*)wallpaperDataUrl
{
    return [NSString stringWithFormat:@"http://localhost:%@/wallpaper",
                                        wallpaperServer.port];
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

- (BOOL)canBecomeKeyWindow      { return [self isInFront]; }
- (BOOL)canBecomeMainWindow     { return [self isInFront]; }
- (BOOL)acceptsFirstResponder   { return [self isInFront]; }
- (BOOL)becomeFirstResponder    { return [self isInFront]; }
- (BOOL)resignFirstResponder    { return [self isInFront]; }
- (BOOL)acceptsMouseMovedEvents { return [self isInFront]; }

@end
