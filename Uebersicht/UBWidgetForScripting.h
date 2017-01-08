//
//  UBWidgetForScripting.h
//  Uebersicht
//
//  Created by Felix Hageloh on 7/1/17.
//  Copyright © 2017 tracesOf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UBWidgetForScripting : NSObject

@property (nonatomic) NSString *id;
@property (nonatomic) BOOL hidden;
@property (nonatomic) BOOL showOnAllScreens;
@property (nonatomic) BOOL showOnMainScreen;

-(id)initWithId:(NSString*)widgetId andSettings:(NSDictionary*)settings;
@end
