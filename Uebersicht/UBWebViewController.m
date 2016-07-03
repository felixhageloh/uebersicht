//
//  UBWebViewController.m
//  Uebersicht
//
//  Created by Felix Hageloh on 2/7/16.
//  Copyright © 2016 tracesOf. All rights reserved.
//

#import "UBWebViewController.h"

@implementation UBWebViewController {
    NSURL* url;
}

@synthesize view;

- (id)initWithFrame:(NSRect)frame
{
     self = [super init];
    
     if (self) {
        view = [self buildWebView:frame];
     }
    
     return self;
}

- (void)load:(NSURL*)newUrl
{
    url = newUrl;
    [(WKWebView*)view loadRequest:[NSURLRequest requestWithURL: newUrl]];
}

- (void)reload
{
    [(WKWebView*)view reloadFromOrigin:self];
}

- (void)redraw
{
    [self forceRedraw:(WKWebView*)view];
}

- (void)destroy
{
    [self teardownWebview:(WKWebView *)view];
    view = nil;
}

- (WKWebView*)buildWebView:(NSRect)frame
{
    WKWebView* webView = [[WKWebView alloc]
        initWithFrame: frame
        configuration: [self sharedConfig]
    ];
    
    [webView setValue:@YES forKey:@"drawsTransparentBackground"];
    [webView.configuration.preferences
        setValue: @YES
        forKey: @"developerExtrasEnabled"
    ];
    webView.navigationDelegate = (id<WKNavigationDelegate>)self;
    
    return webView;
}

- (void)teardownWebview:(WKWebView*)webView
{
    webView.navigationDelegate = nil;
    [webView stopLoading:self];
    [webView removeFromSuperview];
}

- (WKWebViewConfiguration*)sharedConfig {
    static WKWebViewConfiguration *sharedConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedConfig =  [[WKWebViewConfiguration alloc] init];
    });
    return sharedConfig;
}

- (void)forceRedraw:(WKWebView*)webView
{
    [view setNeedsDisplay:YES];
}

- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation*)navigation
{
    NSLog(@"loaded %@", webView.URL);
}

- (void)webView:(WKWebView *)sender
    didFailNavigation:(WKNavigation*)nav
    withError:(NSError *)error
{
    [self handleWebviewLoadError:error];
}

- (void)webView:(WKWebView *)sender
    didFailProvisionalNavigation:(WKNavigation *)nav
    withError:(NSError *)error
{
    [self handleWebviewLoadError:error];
}


- (void)webView: (WKWebView *)theWebView
    decidePolicyForNavigationAction: (WKNavigationAction*)action
    decisionHandler: (void (^)(WKNavigationActionPolicy))handler
{
    if (!action.targetFrame.mainFrame) {
        handler(WKNavigationActionPolicyAllow);
    } else if ([action.request.URL isEqual: url]) {
        handler(WKNavigationActionPolicyAllow);
    } else if (action.navigationType == WKNavigationTypeLinkActivated) {
        [[NSWorkspace sharedWorkspace] openURL:action.request.URL];
        handler(WKNavigationActionPolicyCancel);
    } else {
        handler(WKNavigationActionPolicyCancel);
    }

}

- (void)handleWebviewLoadError:(NSError *)error
{
    NSLog(@"Error loading webview: %@", error);
    [self
        performSelector: @selector(load:)
        withObject: url
        afterDelay: 5.0
    ];
}



@end
