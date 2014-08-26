//
//  UBWallperServer.m
//  Übersicht
//
//  Created by Felix Hageloh on 26/8/14.
//  Copyright (c) 2014 tracesOf. All rights reserved.
//

#import "UBWallperServer.h"


@implementation UBWallperServer {
    NSWindow* window;
    NSURL *prevWallpaperUrl;
    NSDictionary *prevWallpaperOptions;
    WallpaperChangeBlock changeHandler;
}
;
- (id)initWithWindow:(NSWindow*)aWindow
{
    self = [super init];
    
    if (self) {
        window = aWindow;
        
        NSWorkspace* ws  = [NSWorkspace sharedWorkspace];
        NSNotificationCenter* notifications = [ws notificationCenter];
        [notifications addObserver:self
                          selector:@selector(onWorkspaceChange:)
                              name:NSWorkspaceActiveSpaceDidChangeNotification
                            object:nil];
        
        prevWallpaperUrl     = [[ws desktopImageURLForScreen:window.screen] absoluteURL];
        prevWallpaperOptions = [ws desktopImageOptionsForScreen:window.screen];
    }
    
    return self;
}

- (void)startWallperServer
{
    NSSocketPort *socketPort;
    socketPort = [[NSSocketPort alloc] initWithTCPPort:4567];
    
    NSFileHandle *fileHandle;
    fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:socketPort.socket
                                               closeOnDealloc:YES];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(newWpConnection:)
               name:NSFileHandleConnectionAcceptedNotification
             object:nil];
    
    [fileHandle acceptConnectionInBackgroundAndNotify];
    
}

- (void)newWpConnection:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSFileHandle *remoteFileHandle = [userInfo objectForKey:
                                      NSFileHandleNotificationFileHandleItem];
    
    NSNumber *errorNo = [userInfo objectForKey:@"NSFileHandleError"];
    if( errorNo ) {
        NSLog(@"NSFileHandle Error: %@", errorNo);
        return;
    }
    
//    [fileHandle acceptConnectionInBackgroundAndNotify];
//    
//    if( remoteFileHandle ) {
//        SimpleHTTPConnection *connection;
//        connection = [[SimpleHTTPConnection alloc] initWithFileHandle:
//                      remoteFileHandle
//                                                             delegate:self];
//        if( connection ) {
//            NSIndexSet *insertedIndexes;
//            insertedIndexes = [NSIndexSet indexSetWithIndex:
//                               [connections count]];
//            [self willChange:NSKeyValueChangeInsertion
//             valuesAtIndexes:insertedIndexes forKey:@"connections"];
//            [connections addObject:connection];
//            [self didChange:NSKeyValueChangeInsertion
//            valuesAtIndexes:insertedIndexes forKey:@"connections"];
//            [connection release];
//        }
//    }
}

- (NSData*)currentWallpaper
{
    CGImageRef cgImage;
    cgImage = CGWindowListCreateImage([self toQuartzCoordinates:window.screen.frame],
                                      kCGWindowListOptionOnScreenBelowWindow,
                                      (CGWindowID)[window windowNumber],
                                      kCGWindowImageDefault);
    
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return [bitmapRep representationUsingType:NSPNGFileType properties:nil];
}

// old coordinate system is flipped
- (NSRect)toQuartzCoordinates:(NSRect)screenRect
{
    CGRect mainScreenRect = CGDisplayBounds (CGMainDisplayID ());
    
    screenRect.origin.y = -1 * (screenRect.origin.y + screenRect.size.height -
                                mainScreenRect.size.height);
    
    return screenRect;
}


- (void)onWorkspaceChange:(NSNotification*)event
{
    NSURL *currWallpaperUrl = [[[NSWorkspace sharedWorkspace]
                                 desktopImageURLForScreen:window.screen] absoluteURL];
    NSDictionary *currWallpaperOptions = [[NSWorkspace sharedWorkspace]
                                          desktopImageOptionsForScreen:window.screen];
    
    if ((prevWallpaperUrl && ![prevWallpaperUrl isEqual:currWallpaperUrl]) ||
        (prevWallpaperOptions && ![prevWallpaperOptions isEqualToDictionary:currWallpaperOptions])) {
        changeHandler();
    }
    prevWallpaperUrl = currWallpaperUrl;
    prevWallpaperOptions = currWallpaperOptions;
}

- (void)onWallpaperChange:(WallpaperChangeBlock)handler
{
    changeHandler = handler;
}


@end
