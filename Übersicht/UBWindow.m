//
//  UBWindow.m
//  Übersicht
//
//  A window that sits on desktop level, is always fullscreen and doesn't show
//  up in Mission Control
//
//  Created by Felix Hageloh on 20/9/13.
//  Copyright (c) 2013 tracesOf. All rights reserved.
//

#import "UBWindow.h"

@implementation UBWindow

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
        [self makeFullscreen];
        
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

- (void)makeFullscreen
{
    NSRect fullscreen = [[NSScreen mainScreen] frame];
    
    // TODO: when app launches, this is 0 (I guess mainMenu is not init yet)
    //int menuBarHeight = [[NSApp mainMenu] menuBarHeight];
    
    fullscreen.size.height = fullscreen.size.height - 22;
    [self setFrame:fullscreen display:YES];

}

@end
