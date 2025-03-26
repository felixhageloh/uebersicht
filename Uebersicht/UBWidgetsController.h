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
@class UBPreferencesController;

@interface UBWidgetsController : NSController

- (id)initWithMenu:(NSMenu*)menu
           widgets:(UBWidgetsStore*)theWidgets
           screens:(UBScreensController*)screens
       preferences:(UBPreferencesController*)preferences;
- (void)render;
- (NSArray*)widgetsForScripting;
- (void)reloadWidget:(NSString*)widgetId;

@end
