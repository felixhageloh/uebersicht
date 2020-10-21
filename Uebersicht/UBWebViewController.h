//
//  UBWebViewController.h
//  Uebersicht
//
//  Created by Felix Hageloh on 2/7/16.
//  Copyright © 2016 tracesOf. All rights reserved.
//

#import <Foundation/Foundation.h>
@import WebKit;

@interface UBWebViewController : NSObject<WKNavigationDelegate, WKScriptMessageHandler>

@property (strong, readonly) NSView* view;

- (id)initWithFrame:(NSRect)frame;
- (void)load:(NSURL*)url;
- (void)reload;
- (void)redraw;
- (void)destroy;
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;
- (void)makeBackground;
- (void)makeForeground;
- (void)makeAgnostic;

@end
