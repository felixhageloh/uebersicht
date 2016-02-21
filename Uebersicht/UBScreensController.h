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
@property NSArray* sortedScreens;

- (id)initWithChangeListener:(id)target;
- (void)screensChanged:(id)sender;
- (NSRect)screenRect:(NSNumber*)screenId;

@end
