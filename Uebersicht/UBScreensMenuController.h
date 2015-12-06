//
//  UBScreensMenuController.h
//  
//
//  Created by Felix Hageloh on 8/11/15.
//
//

#import <Foundation/Foundation.h>

@interface UBScreensMenuController : NSObject

- (void)addScreensToMenu:(NSMenu*)menu atIndex:(NSInteger)index withAction:(SEL)action andTarget:(id)target;
- (void)removeScreensFromMenu:(NSMenu*)aMenu;
- (void)markScreen:(CGDirectDisplayID)screenId inMenu:(NSMenu*)menu;

@end
