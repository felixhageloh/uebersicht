//
//  WebInspector.h
//  Übersicht
//
//  Created by Felix Hageloh on 3/4/14.
//  Copyright (c) 2014 Felix Hageloh. All rights reserved.
//
// Apple does not expose this api, but the implementation exists (the internets told me and it works)

@interface WebInspector : NSObject
- (id)initWithWebView:(WebView *)webView;
- (void)show:(id)sender;
@end