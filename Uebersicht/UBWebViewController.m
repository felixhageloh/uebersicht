//
//  UBWebViewController.m
//  Uebersicht
//
//  Created by Felix Hageloh on 2/7/16.
//  Copyright © 2016 tracesOf. All rights reserved.
//

#import "UBWebViewController.h"
#import "UBLocation.h"
#import "UBWebView.h"

@implementation UBWebViewController {
    NSURL* url;
    BOOL isBackground;
}

@synthesize view;

- (id)initWithFrame:(NSRect)frame
{
     self = [super init];
    
     if (self) {
        view = [self buildWebView:frame];
        isBackground = NO;
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

- (void)makeBackground
{
    [self makeBackground:(WKWebView *)view];
    isBackground = YES;
}

- (WKWebView*)buildWebView:(NSRect)frame
{
    WKWebView* webView = [[UBWebView alloc]
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
        sharedConfig = [self buildConfig];
    });
    return sharedConfig;
}

- (WKWebViewConfiguration*)buildConfig
{
    WKUserContentController* ucController = [
        [WKUserContentController alloc] init
    ];
    
    // geolocation
    [ucController
        addScriptMessageHandler: [[UBLocation alloc] init]
        name: @"geolocation"
    ];
    
    NSString* geolocationScript = [NSString
        stringWithContentsOfURL: [[NSBundle mainBundle]
            URLForResource: @"geolocation"
            withExtension: @"js"
        ]
        encoding: NSUTF8StringEncoding
        error: nil
    ];
    [ucController addUserScript:[[WKUserScript alloc]
        initWithSource: geolocationScript
        injectionTime: WKUserScriptInjectionTimeAtDocumentStart
        forMainFrameOnly: YES
    ]];
    
    // hack to make old widgets relying on process.argv[0] work
    NSString* processArgvHack = [NSString
        stringWithFormat:@"process = {argv: ['%@'.replace(/ /g, '\\\\ ')]}",
        [[NSBundle mainBundle] pathForResource:@"localnode" ofType:nil]
    ];
    [ucController addUserScript:[[WKUserScript alloc]
        initWithSource: processArgvHack
        injectionTime: WKUserScriptInjectionTimeAtDocumentStart
        forMainFrameOnly: YES
    ]];
    
    [ucController addScriptMessageHandler: self name: @"uebersicht"];
    
    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = ucController;
    
    return config;
}

- (void)forceRedraw:(WKWebView*)webView
{
    [webView
         evaluateJavaScript:
             @"document.documentElement.style.transform = 'scale(1)';\
               requestAnimationFrame(function() {\
                 document.documentElement.style.transform = '';\
               });"
         completionHandler:NULL
     ];
}

- (void)makeBackground:(WKWebView*)webView
{
    [webView
         evaluateJavaScript: @"window.isBackground = true;"
         completionHandler:NULL
     ];
}

- (void)webView:(WKWebView *)webView
    didFinishNavigation:(WKNavigation*)navigation
{
    NSLog(
        @"loaded %@ %@",
        webView.URL,
        isBackground ? @"background" : @"foreground"
    );

    [webView
         evaluateJavaScript: isBackground
            ? @"window.isBackground = true;"
            : @"window.isBackground = false;"
         completionHandler:NULL
    ];
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

- (void)userContentController:(WKUserContentController *)controller
    didReceiveScriptMessage:(WKScriptMessage *) message
{
    if ([message.body isEqual: @"widgetEnter"]) {
        [message.webView.window setIgnoresMouseEvents: NO];
    } else if ([message.body isEqual:@"widgetLeave"]) {
        [message.webView.window setIgnoresMouseEvents: YES];
    }
}

@end
