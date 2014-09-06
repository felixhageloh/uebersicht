//
//  UBWallperServer.h
//  Übersicht
//
//  Created by Felix Hageloh on 26/8/14.
//  Copyright (c) 2014 tracesOf. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^WallpaperChangeBlock)(void);

@interface UBWallperServer : NSObject

- (id)initWithWindow:(NSWindow*)aWindow;
- (void)onWallpaperChange:(WallpaperChangeBlock)handler;
- (NSString*)url;

@end
