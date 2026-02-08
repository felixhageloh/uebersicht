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
                     alwaysOnTop:(BOOL)alwaysOnTop
{
    self = [super init];
    if (self) {
        if (interactionEnabled || alwaysOnTop) {
            UBWindowType foregroundType = alwaysOnTop
                ? UBWindowTypeAlwaysOnTop
                : UBWindowTypeForeground;
            foreground = [[UBWindow alloc]
                initWithWindowType: foregroundType
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
