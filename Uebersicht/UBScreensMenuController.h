//
//  UBScreensMenuController.h
//  
//
//  Created by Felix Hageloh on 8/11/15.
//
//

#import <Foundation/Foundation.h>

@interface UBScreensMenuController : NSObject

- (id)initWithMaxDisplays:(int)max;
- (void)addScreensToMenu:(NSMenu*)aMenu action:(SEL)selectAction target:(id)target;
- (void)removeScreensFromMenu:(NSMenu*)aMenu;
- (void)markScreen:(CGDirectDisplayID)screenId inMenu:(NSMenu*)menu;

@end
