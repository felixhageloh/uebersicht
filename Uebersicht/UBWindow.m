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
@import WebKit;

@implementation UBWindow {
    NSURL *widgetsUrl;
    BOOL webviewLoaded;
    WKWebView* webView;
}

- (id)init
{

    self = [super
        initWithContentRect: NSMakeRect(0, 0, 0, 0)
        styleMask: NSBorderlessWindowMask
        backing: NSBackingStoreBuffered
        defer: NO
    ];
    
    if (self) {
        [self setBackgroundColor:[NSColor clearColor]];
        [self setOpaque:NO];
        [self sendToDesktop];
        [self setCollectionBehavior:(
            NSWindowCollectionBehaviorTransient |
            NSWindowCollectionBehaviorCanJoinAllSpaces |
            NSWindowCollectionBehaviorIgnoresCycle
        )];

        [self setRestorable:NO];
        [self disableSnapshotRestoration];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        
        webView = [self buildWebView];
        [self setContentView:webView];
    }

    return self;
}


- (WKWebView*)buildWebView
{
    WKWebView* view = [[WKWebView alloc]
        initWithFrame: [self frame]
        configuration: [[WKWebViewConfiguration alloc] init]
    ];
    
    [view setValue:@YES forKey:@"drawsTransparentBackground"];
    [view.configuration.preferences
        setValue: @YES
        forKey: @"developerExtrasEnabled"
    ];
    view.navigationDelegate = (id<WKNavigationDelegate>)self;
//    [view setMaintainsBackForwardList:NO];
    
    return view;
}

- (void)teardownWebview:(WKWebView*)view
{
//    [view setFrameLoadDelegate:nil];
//    [[view windowScriptObject] removeWebScriptKey:@"geolocation"];
    view.navigationDelegate = nil;
    [view stopLoading:self];
    [view removeFromSuperview];
}

- (void)loadUrl:(NSURL*)url
{
    widgetsUrl = url;
    webviewLoaded = NO;
    [webView loadRequest:[NSURLRequest requestWithURL: url]];
}

- (void)reload
{
    webviewLoaded = NO;
    [webView reloadFromOrigin:self];
}


- (void)close
{
    [self teardownWebview:webView];
    [super close];
}

- (void) forceRedraw
{
    [webView
        evaluateJavaScript:@"window.dispatchEvent(new Event('onwallpaperchange'))"
        completionHandler: nil
    ];
}

#
#pragma mark signals/events
#

- (void)workspaceChanged
{
    [self forceRedraw];
}

- (void)wallpaperChanged
{
    [self forceRedraw];
}

#
#pragma mark window control
#


- (void)sendToDesktop
{
    [self setLevel:kCGDesktopWindowLevel];
}

- (void)comeToFront
{
    if (self.isInFront) return;

    [self setLevel:kCGNormalWindowLevel-1];
    [NSApp activateIgnoringOtherApps:NO];
    [self makeKeyAndOrderFront:self];
}

- (BOOL)isInFront
{
    return self.level == kCGNormalWindowLevel-1;
}

#
#pragma mark WebView delegates
#

- (void)webView:(WebView *)sender didFinishNavigation:(WKNavigation*)navigation
{
    NSLog(@"loaded %@", webView.URL);
//    JSContextRef jsContext = [frame globalContext];
//    UBLocation* location   = [[UBLocation alloc] initWithContext:jsContext];
//
//    [[webView windowScriptObject] setValue:location forKey:@"geolocation"];
    [self workspaceChanged];
}

- (void)webView:(WebView *)sender
    didFailNavigation:(WKNavigation*)nav
    withError:(NSError *)error
{
    [self handleWebviewLoadError:error];
}

- (void)webView:(WebView *)sender
    didFailProvisionalNavigation:(WKNavigation *)nav
    withError:(NSError *)error
{
    [self handleWebviewLoadError:error];
}


- (void)webView: (WebView *)theWebView
    decidePolicyForNavigationAction: (WKNavigationAction*)action
    decisionHandler: (void (^)(WKNavigationActionPolicy))handler
{
    if (!action.sourceFrame.mainFrame) {
        handler(WKNavigationActionPolicyAllow);
    } else if (action.navigationType == WKNavigationTypeLinkActivated) {
        [[NSWorkspace sharedWorkspace] openURL:action.request.URL];
        handler(WKNavigationActionPolicyCancel);
    } else if ([action.request.URL isEqualTo: widgetsUrl]) {
        handler(WKNavigationActionPolicyAllow);
    } else {
        handler(WKNavigationActionPolicyCancel);
    }

}

- (void)handleWebviewLoadError:(NSError *)error
{
    NSLog(@"Error loading webview: %@", error);
    [self
        performSelector: @selector(loadUrl:)
        withObject: widgetsUrl
        afterDelay: 5.0
    ];
}


#
#pragma mark flags
#

- (BOOL)canBecomeKeyWindow { return [self isInFront]; }
- (BOOL)canBecomeMainWindow { return [self isInFront]; }
- (BOOL)acceptsFirstResponder { return [self isInFront]; }
- (BOOL)acceptsMouseMovedEvents { return [self isInFront]; }

@end
