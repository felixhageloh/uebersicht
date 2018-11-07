//
//  UBWidgetsStore.h
//  
//
//  Created by Felix Hageloh on 26/1/16.
//
//

#import <Foundation/Foundation.h>

@interface UBWidgetsStore : NSObject

- (void)onChange:(void (^)(NSDictionary*))aChangeHandler;
- (void)reset;
- (void)reset:(NSDictionary*)state;
- (NSDictionary*)get:(NSString*)widgetId;
- (NSDictionary*)getSettings:(NSString*)widgetId;
- (NSArray*)sortedWidgets;

@end
