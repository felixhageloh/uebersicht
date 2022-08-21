//
//  UBWindowGroup.m
//  Uebersicht
//
//  Created by Felix Hageloh on 05/10/2020.
//  Copyright © 2020 tracesOf. All rights reserved.
//

#import "UBWindowGroup.h"
#import "UBWindow.h"

@implementation UBWindowGroup

@synthesize foreground;
@synthesize background;


- (id)initWithInteractionEnabled:(BOOL)interactionEnabled
{
    self = [super init];
    if (self) {
        if (interactionEnabled) {
            foreground = [[UBWindow alloc]
                initWithWindowType: UBWindowTypeForeground
            ];
            [foreground orderFront:self];
        }
        
        background = [[UBWindow alloc]
            initWithWindowType: interactionEnabled
                ? UBWindowTypeBackground
                : UBWindowTypeAgnostic
        ];
        [background orderFront:self];
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

- (void)loadUrl:(NSURL*)url
{
    [foreground loadUrl: url];
    [background loadUrl: url];
}

- (void)setToken:(NSString*)token
{
    [foreground setToken:token];
    [background setToken:token];
}

- (void)setFrame:(NSRect)frame display:(BOOL)flag
{
    [foreground setFrame:frame display:flag];
    [background setFrame:frame display:flag];
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
