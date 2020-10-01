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
- (void)syncScreens:(id)sender;
- (void)showDebugConsoleForScreen:(NSNumber*)screenId;

@end
