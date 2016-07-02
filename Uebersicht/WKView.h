/* https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/API/Cocoa/WKView.h
 * https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/API/Cocoa/WKViewPrivate.h
 * https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/API/mac/WKViewInternal.h
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 */

#ifndef WKView_h
#define WKView_h

#import "WKBase.h"

typedef const struct OpaqueWKPage* WKPageRef;

@interface WKView : NSView {}
@property (readonly) WKPageRef pageRef;
@end

#endif