//
//  UBWindowsController.m
//  Uebersicht
//
//  Created by Felix Hageloh on 30/09/2020.
//  Copyright © 2020 tracesOf. All rights reserved.
//

#import "UBWindowsController.h"
#import "UBWindowGroup.h"
#import "WKInspector.h"
#import "WKView.h"
#import "WKPage.h"
#import "WKWebViewInternal.h"

@import WebKit;

@implementation UBWindowsController {
    NSMutableDictionary* windows;
}

- (id)init
{
    self = [super init];
    if (self) {
        windows = [[NSMutableDictionary alloc] initWithCapacity:42];
    }
    return self;
}


- (void)updateWindows:(NSDictionary*)screens
              baseUrl:(NSURL*)baseUrl
   interactionEnabled:(Boolean)interactionEnabled
         forceRefresh:(Boolean)forceRefresh
{
    NSMutableArray* obsoleteScreens = [[windows allKeys] mutableCopy];
    UBWindowGroup* windowGroup;
    
    for(NSNumber* screenId in screens) {
        if (![windows objectForKey:screenId]) {
            windowGroup = [[UBWindowGroup alloc]
                initWithInteractionEnabled: interactionEnabled
            ];
            [windows setObject:windowGroup forKey:screenId];
            [windowGroup loadUrl: [self screenUrl:screenId baseUrl:baseUrl]];
        } else {
            windowGroup = windows[screenId];
            if (forceRefresh) {
                [windowGroup reload];
            }
        }
        
        [windowGroup setFrame:[self screenRect:screenId] display:YES];
        [obsoleteScreens removeObject:screenId];
    }
    
    for (NSNumber* screenId in obsoleteScreens) {
        [windows[screenId] close];
        [windows removeObjectForKey:screenId];
    }
    
    NSLog(@"using %lu screens", (unsigned long)[windows count]);
}

- (NSRect)screenRect:(NSNumber*)screenId
{
    NSRect screenRect = CGDisplayBounds([screenId unsignedIntValue]);
    CGRect mainScreenRect = CGDisplayBounds(CGMainDisplayID());
    int menuBarHeight = [[NSApp mainMenu] menuBarHeight];

    screenRect.origin.y = -1 * (screenRect.origin.y + screenRect.size.height -
                                mainScreenRect.size.height);

    screenRect.size.height = screenRect.size.height - menuBarHeight;
    
    return screenRect;
}

- (void)setInteractionEnabled:(Boolean)isEnabled
{
    for (NSNumber* screenId in windows) {
        [windows[screenId] setInteractionEnabled: isEnabled];
    }
}

- (void)reloadAll
{
    for (NSNumber* screenId in windows) {
        UBWindowGroup* window = windows[screenId];
        [window reload];
    }
}

- (void)closeAll
{
    for (UBWindowGroup* window in [windows allValues]) {
        [window close];
    }
    [windows removeAllObjects];
}

- (void)showDebugConsoleForScreen:(NSNumber*)screenId
{
    
    NSWindow* window = [(UBWindowGroup*)windows[screenId] foreground] == nil
        ? [(UBWindowGroup*)windows[screenId] background]
        : [(UBWindowGroup*)windows[screenId] foreground];
    WKPageRef page = NULL;
    SEL pageForTesting = @selector(_pageForTesting);
    
    if ([window.contentView.subviews[0] isKindOfClass:[WKView class]]) {
        WKView* webview = window.contentView.subviews[0];
        page = webview.pageRef;
    } else if ([window.contentView respondsToSelector:pageForTesting]) {
        page = (__bridge WKPageRef)([window.contentView
            performSelector: pageForTesting
        ]);
    }
    
    if (page) {
        WKInspectorRef inspector = WKPageGetInspector(page);

        [NSApp activateIgnoringOtherApps:YES];
        
        WKInspectorShowConsole(inspector);
        [self
            performSelector: @selector(detachInspector:)
            withObject: (__bridge id)(inspector)
            afterDelay: 0
        ];
    }
}

- (void)detachInspector:(WKInspectorRef)inspector
{
     WKInspectorDetach(inspector);
}

- (void)workspaceChanged
{
    for (NSNumber* screenId in windows) {
        [windows[screenId] workspaceChanged];
    }
}

- (void)wallpaperChanged
{
    for (NSNumber* screenId in windows) {
        [windows[screenId] wallpaperChanged];
    }
}

- (NSURL*)screenUrl:(NSNumber*)screenId baseUrl:(NSURL*)baseUrl
{
    return [baseUrl
        URLByAppendingPathComponent:[NSString
            stringWithFormat:@"%@",
            screenId
        ]
    ];
}

@end
