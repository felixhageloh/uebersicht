/*
 * https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/API/C/WKPage.h
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 */

#ifndef WKPage_h
#define WKPage_h

#import "WKBase.h"
#import "WKInspector.h"

WK_EXPORT WKInspectorRef WKPageGetInspector(WKPageRef page);

#endif
