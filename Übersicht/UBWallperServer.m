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
    
    NSSocketPort *socketPort;
    NSFileHandle *fileHandle;
    NSFileHandle *currentClient;
    int port;
}
;
- (id)initWithWindow:(NSWindow*)aWindow
{
    self = [super init];
    
    if (self) {
        window = aWindow;
        port   = 41620;
        
        NSWorkspace* ws  = [NSWorkspace sharedWorkspace];
        NSNotificationCenter* notifications = [ws notificationCenter];
        [notifications addObserver:self
                          selector:@selector(onWorkspaceChange:)
                              name:NSWorkspaceActiveSpaceDidChangeNotification
                            object:nil];
        
        prevWallpaperUrl     = [[ws desktopImageURLForScreen:window.screen] absoluteURL];
        prevWallpaperOptions = [ws desktopImageOptionsForScreen:window.screen];
        
        [self startHTTPServer:port];
    }
    
    return self;
}

- (void)startHTTPServer:(int)aPort
{
    socketPort = [[NSSocketPort alloc] initWithTCPPort:aPort];

    fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:socketPort.socket
                                               closeOnDealloc:YES];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(newConnection:)
               name:NSFileHandleConnectionAcceptedNotification
             object:nil];
    
    [fileHandle acceptConnectionInBackgroundAndNotify];
    
}

- (void)newConnection:(NSNotification *)notification
{
    NSLog(@"wallaper server: received wallpaper request");
    NSDictionary *userInfo = [notification userInfo];
    NSFileHandle *client   = [userInfo objectForKey:
                                      NSFileHandleNotificationFileHandleItem];
    
    NSNumber *errorNo = [userInfo objectForKey:@"NSFileHandleError"];
    if( errorNo ) {
        NSLog(@"NSFileHandle Error: %@", errorNo);
        return;
    }
    
    [fileHandle acceptConnectionInBackgroundAndNotify];
    
    [currentClient closeFile];
    currentClient = client;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sendWallaper:client];
    });
}

- (void)sendWallaper:(NSFileHandle*)client
{
    NSLog(@"wallaper server: sending wallpaper");
    NSData *wallpaper = [self currentWallpaper];
    
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault,
                                                            200,
                                                            NULL,
                                                            kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(response,
                                     (CFStringRef)@"Content-Type",
                                     (CFStringRef)@"image/png");
    CFHTTPMessageSetHeaderFieldValue(response,
                                     (CFStringRef)@"Connection",
                                     (CFStringRef)@"close");
    CFHTTPMessageSetHeaderFieldValue(response,
                                     (CFStringRef)@"Content-Length",
                                     (__bridge CFStringRef)[NSString stringWithFormat:@"%ld", wallpaper.length]);
    CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);
    
    @try
    {
        [client writeData:(__bridge NSData *)headerData];
        [client writeData:wallpaper];
    }
    @catch (NSException *exception)
    {
        NSLog(@"wallaper server: %@", exception);
    }
    @finally
    {
        NSLog(@"wallpaper server: done");
        CFRelease(headerData);
    }
    
    [client closeFile];
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


- (NSNumber*)port
{
    return [NSNumber numberWithInt:port];
}

@end
