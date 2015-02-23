//
//  UBLocation.m
//  Übersicht
//
//  Created by Felix Hageloh on 9/12/14.
//  Copyright (c) 2014 tracesOf. All rights reserved.
//

#import "UBLocation.h"

@implementation UBLocation {
    BOOL serviceStarted;
    JSContextRef jsContext;
    NSMutableDictionary* listeners;
    NSMutableArray* pendingCallbacks;
    CLLocationManager* locationManager;
    CLGeocoder *geoCoder;
    NSNumber* currListenerId;
    
    CLLocation  *currentLocation;
    CLPlacemark *currentPlaceMark;
}

- (id) initWithContext:(JSContextRef)context {
    self = [super init];

    if (self) {
        jsContext        = context;
        currentLocation  = nil;
        currentPlaceMark = nil;
        serviceStarted   = NO;
        pendingCallbacks = [[NSMutableArray alloc] init];
        listeners        = [[NSMutableDictionary alloc] init];
        currListenerId   = @1;

        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        geoCoder = [[CLGeocoder alloc] init];
    }

    return self;
}

- (void)startService {
    if (serviceStarted) { return; }

    [locationManager startUpdatingLocation];

    serviceStarted = YES;
}

- (void)stopService {
    if (!serviceStarted) { return; }

    [locationManager stopUpdatingLocation];
    currentLocation = nil;
    serviceStarted  = NO;
}

- (NSString*)toJSString:(CLLocation *)location placeMark:(CLPlacemark*)placeMark
{
    // Coordinates properties (Position.coords)
    CLLocationDegrees latitude = location.coordinate.latitude;
    CLLocationDegrees longitude = location.coordinate.longitude;
    CLLocationDistance altitude = location.altitude;
    CLLocationSpeed speed = location.speed;
    CLLocationDirection heading = location.course;
    CLLocationAccuracy accuracy = location.horizontalAccuracy;
    CLLocationAccuracy altitudeAccuracy = location.verticalAccuracy;
    
    NSDate *timestamp     = location.timestamp;
    NSDictionary *address = placeMark.addressDictionary;
    
    NSString* format = @"{ \
        \"position\": { \
            \"timestamp\": %f, \
            \"coords\": { \
                \"latitude\": %f, \
                \"longitude\": %f, \
                \"altitude\": %f, \
                \"accuracy\": %f, \
                \"altitudeAccuracy\": %f, \
                \"heading\": %f, \
                \"speed\": %f \
            } \
        }, \
        \"address\": { \
            \"street\": \"%@\", \
            \"city\": \"%@\", \
            \"zip\": \"%@\", \
            \"country\": \"%@\", \
            \"state\": \"%@\", \
            \"CountryCode\": \"%@\" \
        } \
    }";
    

    return [NSString stringWithFormat:format,
          (timestamp.timeIntervalSince1970 * 1000),
          latitude,
          longitude,
          altitude,
          accuracy,
          altitudeAccuracy,
          heading,
          speed,
          address[@"Street"],
          address[@"City"],
          address[@"ZIP"],
          address[@"Country"],
          address[@"State"],
          address[@"CountryCode"]];

}

- (void)callJSFunction:(WebScriptObject*)function
          withLocation:(CLLocation *)location
             placeMark:(CLPlacemark *)placeMark
{
    JSStringRef json = JSStringCreateWithCFString(
      (__bridge CFStringRef)[self toJSString:location placeMark:placeMark]
    );
    JSValueRef err, res;
    JSValueRef obj = JSValueMakeFromJSONString(jsContext, json);
    res = JSObjectCallAsFunction(jsContext, [function JSObject], NULL, 1, &obj, &err);
    
    JSStringRelease(json);
    
    if (res == NULL && err != NULL) {
        
        // TODO: this seems like a roundabout way to log an exception. Also, line numbers, stack etc
        // are lost
        JSStringRef errorString = JSValueToStringCopy(jsContext, err, NULL);
        NSString *message = (__bridge NSString*)JSStringCopyCFString(kCFAllocatorDefault, errorString);
        NSString *log     = [NSString stringWithFormat:@"console.error(\"%@\")", message];

        JSStringRef script = JSStringCreateWithCFString((__bridge CFStringRef)log);
        JSEvaluateScript(jsContext, script, NULL, NULL, 0, NULL);
        
        JSStringRelease(errorString);
        JSStringRelease(script);
    }

}


#
#pragma mark WebscriptObject
#

- (void)getCurrentPosition:(WebScriptObject *)callback {

    if (!serviceStarted) [self startService];
    [pendingCallbacks addObject:callback];

}

- (NSNumber*)watchPosition:(WebScriptObject *)callback {

    if (!serviceStarted) [self startService];

    currListenerId = [NSNumber numberWithInt:currListenerId.intValue + 1];
    listeners[currListenerId] = callback;

    if (currentLocation && currentPlaceMark) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self callJSFunction:callback withLocation:currentLocation
                                             placeMark:currentPlaceMark];
        });
    }

    return currListenerId;
}

- (void)clearWatch:(NSNumber *)listenerId {
    [listeners removeObjectForKey:listenerId];
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(getCurrentPosition:) ||
        aSelector == @selector(watchPosition:) ||
        aSelector == @selector(clearWatch:)) {
        return NO;
    }

    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(getCurrentPosition:))
        return @"getCurrentPosition";
    else if (sel == @selector(watchPosition:))
        return @"watchPosition";
    else if (sel == @selector(clearWatch:))
        return @"clearWatch";

    return nil;
}


#
#pragma mark CoreLocation delegates
#

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    currentLocation  = [locations lastObject];
    currentPlaceMark = nil;
    [geoCoder reverseGeocodeLocation:currentLocation
                   completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (!error)
            currentPlaceMark = ((CLPlacemark*)placemarks[0]);
        
        for (id callback in pendingCallbacks) {
            [self callJSFunction:callback withLocation:currentLocation
                                             placeMark:currentPlaceMark];
        }
        for (id key in listeners) {
            [self callJSFunction:listeners[key] withLocation:currentLocation
                                                   placeMark:currentPlaceMark];
        }
        
        [pendingCallbacks removeAllObjects];
    }];
    


    if (listeners.count == 0) [self stopService];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
}


@end
