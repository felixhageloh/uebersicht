//
//  UBWindowGroup.m
//  Uebersicht
//
//  Created by Felix Hageloh on 05/10/2020.
//  Copyright © 2020 tracesOf. All rights reserved.
//

#import "UBWindowGroup.h"

@implementation UBWindowGroup

@synthesize foreground;
@synthesize background;


- (id)init
{
    self = [super init];
    if (self) {
        background = [[UBWindow alloc] init];
        [background orderFront:self];
        [background setInteractionEnabled:NO];
    }
    return self;
}

- (void)close
{
    [foreground close];
    [background close];
}

- (void)reload
{
    [foreground reload];
    [background reload];
}

- (void)loadUrl:(NSURL *)url
{
    [foreground loadUrl:url];
    [background loadUrl:url];
}

- (void)setFrame:(NSRect)frame display:(BOOL)flag
{
    [foreground setFrame:frame display:flag];
    [background setFrame:frame display:flag];
}

- (void)setInteractionEnabled:(BOOL)interactionEnabled
{
    if (interactionEnabled) {
        foreground = [[UBWindow alloc] init];
        [foreground setInteractionEnabled:YES];
        [foreground orderFront:self];
    } else {
        [foreground close];
        foreground = nil;
    }
}

- (void)wallpaperChanged
{
    [foreground wallpaperChanged];
    [background wallpaperChanged];
}

- (void)workspaceChanged
{
    [foreground workspaceChanged];
    [background workspaceChanged];
}

@end
