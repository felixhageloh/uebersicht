//
//  UBLocation.m
//  Übersicht
//
//  Created by Felix Hageloh on 9/12/14.
//  Copyright (c) 2014 tracesOf. All rights reserved.
//

#import "UBLocation.h"

@implementation UBLocation {
    CLLocationManager* locationManager;
    CLGeocoder* geoCoder;
    NSMutableDictionary* waitingForReponse;
    NSString* callbackSignature;
    NSString* currentPosition;
    BOOL serviceStarted;
}

- (id)init {
    self = [super init];
    
    if (self) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        geoCoder = [[CLGeocoder alloc] init];
        
        waitingForReponse = [[NSMutableDictionary alloc] init];
        callbackSignature = @"__UBCallbacks__.call(%@, %@)";
        
        serviceStarted = NO;
    }
    
    return self;
}

- (void)userContentController:(WKUserContentController *)controller
    didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSString* callbackId = message.body[@"callbackId"];
    if ([message.body[@"type"] isEqualToString:@"registerCallback"]) {
        if (!serviceStarted) {
            [self startService];
        }
        
        waitingForReponse[callbackId] = message;
        
        if (currentPosition) {
            [self respondToMessage:message withArguments:currentPosition];
        }
    } else if([message.body[@"type"] isEqualToString:@"removeCallback"]) {
        [waitingForReponse removeObjectForKey:callbackId];
        
        if (waitingForReponse.count == 0) {
            [self stopService];
        }
    }
}

- (void)respondToMessage:(WKScriptMessage*)message withArguments:(NSString*)args
{
   [message.webView
        evaluateJavaScript: [NSString
            stringWithFormat:callbackSignature,
            message.body[@"callbackId"],
            args
        ]
        completionHandler: nil
    ];
}

- (void)startService
{
    if (serviceStarted) { return; }

    [locationManager startUpdatingLocation];
    serviceStarted = YES;
}

- (void)stopService
{
    if (!serviceStarted) { return; }

    [locationManager stopUpdatingLocation];
    currentPosition = nil;
    serviceStarted = NO;
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
    
    
    NSDate *timestamp = location.timestamp;
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
    

    return [NSString
        stringWithFormat:format,
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
        address[@"CountryCode"]
    ];

}


#
#pragma mark CoreLocation delegates
#

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    
    [geoCoder cancelGeocode];
    [geoCoder
        reverseGeocodeLocation:location
        completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error) return;
            CLPlacemark *placemark = ((CLPlacemark*)placemarks[0]);
            self->currentPosition = [self toJSString:location placeMark:placemark];
            
            for (id callbackId in self->waitingForReponse) {
                [self
                 respondToMessage: self->waitingForReponse[callbackId]
                 withArguments: self->currentPosition
                ];
            }
        }
    ];
}

- (void)locationManager:(CLLocationManager *)manager
    didFailWithError:(NSError *)error
{
}


@end
