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

@implementation UBWindow {
    WebScriptObject *scriptObject;
}

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
    [webView setFrameLoadDelegate:self];
}

- (void)loadUrl:(NSString*)url
{
    [webView setMainFrameURL:url];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (frame == [frame findFrameNamed:@"_top"]) {
        scriptObject = [sender windowScriptObject];
        [scriptObject setValue:self forKey:@"os"];
    }
}

- (void)makeFullscreen
{
    NSRect fullscreen = [[NSScreen mainScreen] frame];
    
    int menuBarHeight = [[NSApp mainMenu] menuBarHeight];
    
    fullscreen.size.height = fullscreen.size.height - menuBarHeight;
    [self setFrame:fullscreen display:YES];
}

- (NSString*)wallpaperUrl
{
    return [[[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[self screen]] path];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(wallpaperUrl)) {
        return NO;
    }
    
    return YES;
}

@end
