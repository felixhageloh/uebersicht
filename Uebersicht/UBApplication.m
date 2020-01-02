//
//  UBApplication.m
//  Uebersicht
//
//  Created by Felix Hageloh on 7/8/19.
//  Copyright © 2019 tracesOf. All rights reserved.
//

#import "UBApplication.h"

@implementation UBApplication

- (void)sendEvent:(NSEvent *)event
{
    if (event.type == NSEventTypeMouseEntered) {
        [event.window makeKeyWindow];
    } 
    [super sendEvent:event];
}

@end
