//
//  UBScreensMenuController.h
//  
//
//  Created by Felix Hageloh on 8/11/15.
//
//

#import <Foundation/Foundation.h>

@interface UBScreensController : NSObject

@property NSMutableDictionary* screens;

- (id)initWithChangeListener:(id)target;
- (NSRect)screenRect:(NSNumber*)screenId;

@end
