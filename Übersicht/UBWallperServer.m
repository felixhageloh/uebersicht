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
    UInt32 wallpaperId;
}
;
- (id)initWithWindow:(NSWindow*)aWindow
{
    self = [super init];
    
    if (self) {
        window = aWindow;
        port   = 41620;
        
        int tries = 0;
        while (![self startHTTPServer:port] && tries < 10) {
            tries++; port++;
        }
        
        NSWorkspace* ws      = [NSWorkspace sharedWorkspace];
        prevWallpaperUrl     = [[ws desktopImageURLForScreen:window.screen] absoluteURL];
        prevWallpaperOptions = [ws desktopImageOptionsForScreen:window.screen];
        wallpaperId          = 0;
    }
    
    return self;
}

- (void)listenToWallpaperChanges
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    CFStringRef path = (__bridge CFStringRef)[paths[0]
                                              stringByAppendingPathComponent:@"/Application Support/Dock/"];
    
    FSEventStreamContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    FSEventStreamRef stream;
    
    stream = FSEventStreamCreate(NULL,
                                 &wallpaperSettingsChanged,
                                 &context,
                                 CFArrayCreate(NULL, (const void **)&path, 1, NULL),
                                 kFSEventStreamEventIdSinceNow,
                                 0,
                                 kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
                                 );
    
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);

}

- (bool)startHTTPServer:(int)aPort
{
    socketPort = [[NSSocketPort alloc] initWithTCPPort:aPort];
    if (!socketPort) {
        return false;
    }

    fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:socketPort.socket
                                               closeOnDealloc:YES];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(newConnection:)
               name:NSFileHandleConnectionAcceptedNotification
             object:nil];
    
    [fileHandle acceptConnectionInBackgroundAndNotify];
    
    return YES;
    
}

- (void)newConnection:(NSNotification *)notification
{
    //NSLog(@"wallaper server: received wallpaper request");
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
    //NSLog(@"wallaper server: sending wallpaper");
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
        //NSLog(@"wallpaper server: done");
        CFRelease(headerData);
        CFRelease(response);
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

- (UInt32)wallpaperId
{
    return wallpaperId;
}

// old coordinate system is flipped
- (NSRect)toQuartzCoordinates:(NSRect)screenRect
{
    CGRect mainScreenRect = CGDisplayBounds (CGMainDisplayID ());
    
    screenRect.origin.y = -1 * (screenRect.origin.y + screenRect.size.height -
                                mainScreenRect.size.height);
    
    return screenRect;
}


- (void)notifyWallaperChange
{
    // batch wallpaper change calls together
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(triggerChangeHandler)
                                               object:nil];
    
    [self performSelector:@selector(triggerChangeHandler)
               withObject:nil
               afterDelay:1];
}

- (void)triggerChangeHandler
{
    wallpaperId++;
    if(changeHandler) changeHandler();
}

- (void)workspaceChanged:(NSNotification*)event
{
// == This checks whether the wallpaper has actually changed. Disabled for now as it was causing issues 
//    NSLog(@"workpace changed");
//    NSURL *currWallpaperUrl = [[[NSWorkspace sharedWorkspace]
//                                 desktopImageURLForScreen:window.screen] absoluteURL];
//    NSDictionary *currWallpaperOptions = [[NSWorkspace sharedWorkspace]
//                                          desktopImageOptionsForScreen:window.screen];
    [self notifyWallaperChange];

//    if ((prevWallpaperUrl && ![prevWallpaperUrl isEqual:currWallpaperUrl]) ||
//        (prevWallpaperOptions && ![prevWallpaperOptions isEqualToDictionary:currWallpaperOptions])) {
//        NSLog(@"wallpaper is different");
//        [self notifyWallaperChange];
//    }
//    
//    prevWallpaperUrl = currWallpaperUrl;
//    prevWallpaperOptions = currWallpaperOptions;
}

- (void)onWallpaperChange:(WallpaperChangeBlock)handler
{
    if (!fileHandle) {
        NSLog(@"wallpaper change listener requested, but wallpaper server could not be started.");
        return;
    }
    
    changeHandler = handler;
    [self listenToWallpaperChanges];
    
    NSWorkspace* ws  = [NSWorkspace sharedWorkspace];
    NSNotificationCenter* notifications = [ws notificationCenter];
    [notifications addObserver:self
                      selector:@selector(workspaceChanged:)
                          name:NSWorkspaceActiveSpaceDidChangeNotification
                        object:nil];
}


- (NSString*)url
{
    return [NSString stringWithFormat:@"http://127.0.0.1:%d/wallpaper/%i",
            port,
            wallpaperId];
}

void wallpaperSettingsChanged(
                ConstFSEventStreamRef streamRef,
                void *this,
                size_t numEvents,
                void *eventPaths,
                const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[])
{
    CFStringRef path;
    CFArrayRef  paths = eventPaths;

    //printf("Callback called\n");
    for (int i=0; i < numEvents; i++) {
        path = CFArrayGetValueAtIndex(paths, i);
        if (CFStringFindWithOptions(path, CFSTR("desktoppicture.db"),
                                    CFRangeMake(0,CFStringGetLength(path)),
                                    kCFCompareCaseInsensitive,
                                    NULL) == true) {
            [(__bridge UBWallperServer*)this notifyWallaperChange];
        }
    }
}

@end
