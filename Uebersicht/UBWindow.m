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
#import "UBWebViewController.h"

@implementation UBWindow {
    UBWebViewController* webViewController;
    NSTrackingArea* trackingArea;
}

- (id)init
{

    self = [super
        initWithContentRect: NSMakeRect(0, 0, 0, 0)
        styleMask: NSBorderlessWindowMask
        backing: NSBackingStoreBuffered
        defer: NO
    ];
    
    if (self) {
        [self setBackgroundColor:[NSColor clearColor]];
        [self setOpaque:NO];
        [self sendToDesktop];
        [self setCollectionBehavior:(
            NSWindowCollectionBehaviorTransient |
            NSWindowCollectionBehaviorCanJoinAllSpaces |
            NSWindowCollectionBehaviorIgnoresCycle
        )];

        [self setRestorable:NO];
        [self disableSnapshotRestoration];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self setReleasedWhenClosed:NO];
        [self setIgnoresMouseEvents:YES];
        
        webViewController = [[UBWebViewController alloc]
            initWithFrame: [self frame]
        ];
        [self setContentView:webViewController.view];
        [self setupTrackingArea];
    }

    return self;
}



- (void)setupTrackingArea
{
    trackingArea = [[NSTrackingArea alloc]
        initWithRect: self.contentView.bounds
        options: NSTrackingMouseMoved
            | NSTrackingMouseEnteredAndExited
            | NSTrackingActiveAlways
        owner: nil
        userInfo: nil
    ];
    [self.contentView addTrackingArea:trackingArea];
}

- (void)setFrame:(NSRect)newFrame display:(BOOL)doDisplay
{
    [super setFrame:newFrame display:doDisplay];
    [self updateTrackingArea];
}

- (void)updateTrackingArea
{
    if (trackingArea != nil) {
        [self.contentView removeTrackingArea:trackingArea];
    }
    if (self.contentView) {
        [self setupTrackingArea];
    }
}

- (void)loadUrl:(NSURL*)url
{
    [webViewController load:url];
}

- (void)reload
{
    [webViewController reload];
}

// TODO: check if we can do at least some cleanups in webViewController#destroy
//- (void)close
//{
//    [webViewController destroy];
//    [super close];
//}


#
#pragma mark signals/events
#

- (void)workspaceChanged
{
    [webViewController redraw];
}

- (void)wallpaperChanged
{
    [webViewController redraw];
}

#
#pragma mark window control
#


- (void)sendToDesktop
{
    [self setLevel:kCGNormalWindowLevel-1];
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    if ([[defaults valueForKey:@"compatibilityMode"] boolValue]) {
//        [self setLevel:kCGDesktopWindowLevel - 1];
//    } else {
//        [self setLevel:kCGDesktopWindowLevel];
//    }
}

- (void)comeToFront
{
    if (self.isInFront) return;

    [self setLevel:kCGNormalWindowLevel-1];
    [NSApp activateIgnoringOtherApps:NO];
    [self makeKeyAndOrderFront:self];
}

- (BOOL)isInFront
{
    return self.level == kCGNormalWindowLevel-1;
}


#
#pragma mark flags
#

- (BOOL)isKeyWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)acceptsFirstResponder { return [self isInFront]; }
- (BOOL)acceptsMouseMovedEvents { return YES; }

@end
