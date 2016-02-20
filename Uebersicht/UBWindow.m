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
#import "UBLocation.h"

@implementation UBWindow {
    NSURL *widgetsUrl;
    BOOL webviewLoaded;
    WebView* webView;
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
        [self setCollectionBehavior:(NSWindowCollectionBehaviorTransient |
                                     NSWindowCollectionBehaviorCanJoinAllSpaces |
                                     NSWindowCollectionBehaviorIgnoresCycle)];

        [self setRestorable:NO];
        [self disableSnapshotRestoration];
        [self setDisplaysWhenScreenProfileChanges:YES];
        
        webView = [self buildWebView];
        [self setContentView:webView];
    }

    return self;
}


- (WebView*)buildWebView
{
    WebView* view = [[WebView alloc]
        initWithFrame: [self frame]
        frameName: nil
        groupName: nil
    ];
    [view setDrawsBackground:NO];
    [view setMaintainsBackForwardList:NO];
    [view setFrameLoadDelegate:self];
    [view setPolicyDelegate:self];
    
    return view;
}

- (void)teardownWebview:(WebView*)view
{
    [view setFrameLoadDelegate:nil];
    [view setPolicyDelegate:nil];
}

- (void)loadUrl:(NSURL*)url
{
    widgetsUrl = url;
    webviewLoaded = NO;
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
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

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (frame == webView.mainFrame) {
        NSLog(@"loaded %@", webView.mainFrameURL);
        JSContextRef jsContext = [frame globalContext];
        UBLocation* location   = [[UBLocation alloc] initWithContext:jsContext];
        
        [[webView windowScriptObject] setValue:self forKey:@"os"];
        [[webView windowScriptObject] setValue:location forKey:@"geolocation"];
        [self workspaceChanged];
    }
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame
{
    [self handleWebviewLoadError:error];
}

- (void)webView:(WebView *)sender
    didFailProvisionalLoadWithError:(NSError *)error
    forFrame:(WebFrame *)frame
{
    [self handleWebviewLoadError:error];
}


- (void)webView:(WebView *)theWebView
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
    request:(NSURLRequest *)request
    frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener
{
    int actionType = [actionInformation[WebActionNavigationTypeKey]
        unsignedIntValue
    ];
    
    if (frame != theWebView.mainFrame) {
        [listener use];
    } else if (actionType == WebNavigationTypeLinkClicked) {
        [[NSWorkspace sharedWorkspace] openURL:request.URL];
        [listener ignore];
    } else if ([request.URL isEqualTo: widgetsUrl]) {
        [listener use];
    } else {
        [listener ignore];
    }

}

- (void)handleWebviewLoadError:(NSError *)error
{
    NSURL* url = [error.userInfo objectForKey:@"NSErrorFailingURLKey"];
    if ([url isEqualTo: widgetsUrl]) {
        NSLog(
            @"%@ failed to load: %@ Reloading...",
            url,
            error.localizedDescription
        );

        [self
            performSelector: @selector(loadUrl:)
            withObject: widgetsUrl
            afterDelay: 5.0
        ];
    }
}


#
#pragma mark WebscriptObject
#

- (void)workspaceChanged
{
    [[webView windowScriptObject]
        evaluateWebScript:@"window.dispatchEvent(new Event('onwallpaperchange'))"
    ];
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    return YES;
}

#
#pragma mark flags
#

- (BOOL)canBecomeKeyWindow { return [self isInFront]; }
- (BOOL)canBecomeMainWindow { return [self isInFront]; }
- (BOOL)acceptsFirstResponder { return [self isInFront]; }
- (BOOL)acceptsMouseMovedEvents { return [self isInFront]; }

@end
