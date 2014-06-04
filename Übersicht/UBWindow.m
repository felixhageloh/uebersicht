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

@implementation UBWindow

@synthesize webView;

- (id) initWithContentRect:(NSRect)contentRect
                 styleMask:(NSUInteger)aStyle
                   backing:(NSBackingStoreType)bufferingType
                     defer:(BOOL)flag
{

    self = [super initWithContentRect:contentRect
                            styleMask:NSBorderlessWindowMask
                              backing:bufferingType
                                defer:flag];
    
    if (self) {
        [self setBackgroundColor:[NSColor clearColor]];
        [self setOpaque:NO];
        [self setLevel:kCGDesktopWindowLevel];
        [self setCollectionBehavior:(NSWindowCollectionBehaviorTransient |
                                     NSWindowCollectionBehaviorCanJoinAllSpaces |
                                     NSWindowCollectionBehaviorIgnoresCycle)];
        
        [self setRestorable:NO];
        [self disableSnapshotRestoration];
        [self setDisplaysWhenScreenProfileChanges:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(makeFullscreen)
                                                     name:NSApplicationDidChangeScreenParametersNotification
                                                   object:nil];
    }
    
    return self;
}

- (void) awakeFromNib
{
    [self initWebView];
    [self makeFullscreen];
}

- (void)initWebView
{
    [webView setDrawsBackground:NO];
    [webView setMaintainsBackForwardList:NO];
}

- (void)loadUrl:(NSString*)url
{
    [webView setMainFrameURL:url];
}

- (void)makeFullscreen
{
    NSRect fullscreen = [[NSScreen mainScreen] frame];
    
    // TODO: when app launches, this is 0 (I guess mainMenu is not init yet)
    int menuBarHeight = [[NSApp mainMenu] menuBarHeight];
    NSLog(@"%d\n", menuBarHeight);
    
    fullscreen.size.height = fullscreen.size.height - 22;
    [self setFrame:fullscreen display:YES];

}

@end
