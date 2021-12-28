/*
 * https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/API/Cocoa/WKWebViewInternal.h
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 */

#ifndef WKWebViewInternal_h
#define WKWebViewInternal_h

#include "WKBase.h"

@interface WKWebView : NSView
- (WKPageRef)_pageForTesting;
@end
#endif
