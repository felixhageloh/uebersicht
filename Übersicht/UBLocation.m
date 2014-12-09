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
    NSMutableArray* listeners;
    CLLocationManager* locationManager;
    CLLocation * currentLocation;
}

- (id) initWithContext:(JSContextRef)context {
    self = [super init];
    
    if (self) {
        jsContext = context;
        currentLocation = nil;
        serviceStarted = NO;
        listeners = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)startService {
    if (serviceStarted) { return;}
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
    serviceStarted = YES;
}

- (NSString*)toJSString:(CLLocation *)location
{
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
          speed];

}

- (void)callJSFunction:(WebScriptObject*)function withLocation:(CLLocation *)location
{
    JSStringRef json = JSStringCreateWithCFString((__bridge CFStringRef)[self toJSString:location]);
    JSValueRef obj   = JSValueMakeFromJSONString(jsContext, json);
    
    JSObjectCallAsFunction(jsContext, [function JSObject], NULL, 1, &obj, NULL);
}


#
#pragma mark WebscriptObject
#

- (void)getCurrentPosition:(WebScriptObject *)callback {
    
    if (!serviceStarted) [self startService];
    
    if (!currentLocation) {
        [listeners addObject:callback];
    } else {
        [self callJSFunction:callback withLocation:currentLocation];
    }
    
   
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(getCurrentPosition:)) {
        return NO;
    }
    
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(getCurrentPosition:))
        return @"getCurrentPosition";
    
    return nil;
}


#
#pragma mark CoreLocation delegates
#

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    currentLocation = newLocation;
    
    for (id callback in listeners) {
        [self callJSFunction:callback withLocation:currentLocation];
    }
    
    [listeners removeAllObjects];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
}


@end
