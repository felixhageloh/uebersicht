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
#import "UBWallperServer.h"

#define CLCOORDINATE_EPSILON 0.005f
#define CLCOORDINATES_EQUAL2( coord1, coord2 ) (fabs(coord1.latitude - coord2.latitude) < CLCOORDINATE_EPSILON && fabs(coord1.longitude - coord2.longitude) < CLCOORDINATE_EPSILON)

@implementation UBWindow {
    NSString *widgetsUrl;
    UBWallperServer* wallpaperServer;
    BOOL webviewLoaded;
    CLLocationManager* locationManager;
}

@synthesize webView;

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
        [self sendToDesktop];
        [self setCollectionBehavior:(NSWindowCollectionBehaviorTransient |
                                     NSWindowCollectionBehaviorCanJoinAllSpaces |
                                     NSWindowCollectionBehaviorIgnoresCycle)];
        
        // Start location services
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation];

        [self setRestorable:NO];
        [self disableSnapshotRestoration];
        [self setDisplaysWhenScreenProfileChanges:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(wakeFromSleep:)
                                                     name:NSWorkspaceDidWakeNotification
                                                   object:nil];
    }


    return self;
}

- (void)awakeFromNib
{
    [self initWebView];
}

- (void)initWebView
{
    [webView setDrawsBackground:NO];
    [webView setMaintainsBackForwardList:NO];
    [webView setFrameLoadDelegate:self];
    [webView setPolicyDelegate:self];
}

- (void)loadUrl:(NSString*)url
{
    if (!wallpaperServer) {
        wallpaperServer = [[UBWallperServer alloc] initWithWindow:self];
        [wallpaperServer onWallpaperChange:^{
            [self notifyWebviewOfWallaperChange];
        }];
    }
    
    widgetsUrl    = url;
    webviewLoaded = NO;
    [webView setMainFrameURL:url];
}

- (void)reload
{
    webviewLoaded = NO;
    [webView reloadFromOrigin:self];
}


- (void)wakeFromSleep:(NSNotification *)notification
{
    [webView reloadFromOrigin:self];
}

#
#pragma mark window control
#

- (void)fillScreen:(CGDirectDisplayID)screenId
{
    NSRect fullscreen = [self toQuartzCoordinates:CGDisplayBounds(screenId)];
    int menuBarHeight = [[NSApp mainMenu] menuBarHeight];
    
    fullscreen.size.height = fullscreen.size.height - menuBarHeight;
    [self setFrame:fullscreen display:YES];
}

- (void)sendToDesktop
{
    [self setLevel:kCGDesktopWindowLevel];
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

- (NSRect)toQuartzCoordinates:(NSRect)screenRect
{
    CGRect mainScreenRect = CGDisplayBounds (CGMainDisplayID ());
    
    screenRect.origin.y = -1 * (screenRect.origin.y + screenRect.size.height -
                                mainScreenRect.size.height);
    
    return screenRect;
}

#
#pragma mark WebView delegates
#

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    NSLog(@"loaded %@", webView.mainFrameURL);
    if (frame == [frame findFrameNamed:@"_top"]) {
        [[webView windowScriptObject] setValue:self forKey:@"os"];
        [self notifyWebviewOfWallaperChange];
        
        if (locationManager.location) {
            [self notifyWebviewOfLocationChange:locationManager.location];
        }
    }
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame
{
    [self handleWebviewLoadError:error];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame {
    [self handleWebviewLoadError:error];
}


- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
                                                           request:(NSURLRequest *)request
                                                             frame:(WebFrame *)frame
                                                   decisionListener:(id<WebPolicyDecisionListener>)listener
{
    if ([actionInformation[WebActionNavigationTypeKey] unsignedIntValue] == WebNavigationTypeLinkClicked) {
        [[NSWorkspace sharedWorkspace] openURL:request.URL];
        [listener ignore];
    } else if ([request.URL.absoluteString isEqualToString:widgetsUrl]) {
        [listener use];
    } else {
        [listener ignore];
    }

}

- (void)handleWebviewLoadError:(NSError *)error
{
    NSURL* url = [error.userInfo objectForKey:@"NSErrorFailingURLKey"];
    NSLog(@"%@ failed to load: %@ Reloading...", url, error.localizedDescription);
    
    [self performSelector:@selector(loadUrl:) withObject:url.absoluteString
               afterDelay:5.0];
}

#
#pragma mark CoreLocation delegates
#

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // Only notify the webview if the location has actually changed
    if (!oldLocation || !CLCOORDINATES_EQUAL2(newLocation.coordinate, oldLocation.coordinate)) {
        [self notifyWebviewOfLocationChange:newLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self notifyWebviewOfLocationChange:nil];
}

#
#pragma mark WebscriptObject
#

- (void)notifyWebviewOfWallaperChange
{
    [[webView windowScriptObject]
        evaluateWebScript:@"window.dispatchEvent(new Event('onwallpaperchange'))"];
}

- (NSString*)wallpaperUrl
{
    return wallpaperServer.url;
}

- (void)notifyWebviewOfLocationChange:(CLLocation *)location
{
    // It may make more sense to retain the last known location so widgets will continue to
    // work until there's another valid location
    if (!location) {
        NSString *script;
        script = [NSString stringWithFormat:@"window.dispatchEvent(new CustomEvent('onlocationchange', { 'detail': { 'position': {} } }))"];
        
        [[webView windowScriptObject] evaluateWebScript:script];
    }
    
    // Coordinates properties (Position.coords)
    CLLocationDegrees latitude = location.coordinate.latitude;
    CLLocationDegrees longitude = location.coordinate.longitude;
    CLLocationDistance altitude = location.altitude;
    CLLocationSpeed speed = location.speed;
    CLLocationDirection heading = location.course;
    CLLocationAccuracy accuracy = location.horizontalAccuracy;
    CLLocationAccuracy altitudeAccuracy = location.verticalAccuracy;
    // Position.timestamp
    NSDate *timestamp = location.timestamp;
    
    NSString *detail;
    detail = [NSString stringWithFormat:@"{ 'position': { 'timestamp': %f, 'coords': { 'latitude': %f, 'longitude': %f, 'altitude': %f, 'accuracy': %f, 'altitudeAccuracy': %f, 'heading': %f, 'speed': %f } } }",
              (timestamp.timeIntervalSince1970 * 1000),
              latitude,
              longitude,
              altitude,
              accuracy,
              altitudeAccuracy,
              heading,
              speed];
    
    NSString *script;
    script = [NSString stringWithFormat:@"window.dispatchEvent(new CustomEvent('onlocationchange', { 'detail': %@ }))", detail];
    
    [[webView windowScriptObject] evaluateWebScript:script];
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(wallpaperUrl)) {
        return NO;
    }

    return YES;
}

#
#pragma mark flags
#

- (BOOL)canBecomeKeyWindow      { return [self isInFront]; }
- (BOOL)canBecomeMainWindow     { return [self isInFront]; }
- (BOOL)acceptsFirstResponder   { return [self isInFront]; }
- (BOOL)acceptsMouseMovedEvents { return [self isInFront]; }

@end
