//
//  UBLocation.h
//  Übersicht
//
//  Created by Felix Hageloh on 9/12/14.
//  Copyright (c) 2014 tracesOf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <CoreLocation/CoreLocation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface UBLocation : NSObject<CLLocationManagerDelegate>

- (id) initWithContext:(JSContextRef)context;
- (void)getCurrentPosition:(WebScriptObject *)callback;
@end
