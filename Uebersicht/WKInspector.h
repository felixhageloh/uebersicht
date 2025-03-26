/*
 * https://raw.githubusercontent.com/WebKit/webkit/master/Source/WebKit2/UIProcess/API/C/WKInspector.h
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 *
 */

#ifndef WKInspector_h
#define WKInspector_h

#include "WKBase.h"

#ifndef __cplusplus
#include <stdbool.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif


WK_EXPORT WKPageRef WKInspectorGetPage(WKInspectorRef inspector);

WK_EXPORT bool WKInspectorIsConnected(WKInspectorRef inspector);
WK_EXPORT bool WKInspectorIsVisible(WKInspectorRef inspector);
WK_EXPORT bool WKInspectorIsFront(WKInspectorRef inspector);

WK_EXPORT void WKInspectorConnect(WKInspectorRef inspector);

WK_EXPORT void WKInspectorShow(WKInspectorRef inspector);
WK_EXPORT void WKInspectorHide(WKInspectorRef inspector);
WK_EXPORT void WKInspectorClose(WKInspectorRef inspector);

WK_EXPORT void WKInspectorShowConsole(WKInspectorRef inspector);
WK_EXPORT void WKInspectorShowResources(WKInspectorRef inspector);

WK_EXPORT bool WKInspectorIsAttached(WKInspectorRef inspector);
WK_EXPORT void WKInspectorAttach(WKInspectorRef inspector);
WK_EXPORT void WKInspectorDetach(WKInspectorRef inspector);

WK_EXPORT bool WKInspectorIsProfilingPage(WKInspectorRef inspector);
WK_EXPORT void WKInspectorTogglePageProfiling(WKInspectorRef inspector);

#ifdef __cplusplus
}
#endif

#endif // WKInspector_h