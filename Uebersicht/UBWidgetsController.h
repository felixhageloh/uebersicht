//
//  UBWidgetsController.h
//  
//
//  Created by Felix Hageloh on 2/12/15.
//
//

#import <Cocoa/Cocoa.h>
@class UBScreensController;
@class UBWidgetsStore;

@interface UBWidgetsController : NSController

- (id)initWithMenu:(NSMenu*)menu
           widgets:(UBWidgetsStore*)theWidgets
           screens:(UBScreensController*)screens;
- (void)render;
@end
