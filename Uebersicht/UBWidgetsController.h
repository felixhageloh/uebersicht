//
//  UBWidgetsController.h
//  
//
//  Created by Felix Hageloh on 2/12/15.
//
//

#import <Cocoa/Cocoa.h>
@class UBScreensController;

@interface UBWidgetsController : NSController

- (id)initWithMenu:(NSMenu*)menu
           screens:(UBScreensController*)screens
      settingsPath:(NSURL*)settingsPath
           baseUrl:(NSString*)url;

- (void)addWidget:(NSString*)widget;
- (void)removeWidget:(NSString*)widget;
- (void)screensChanged:(id)sender;
@end
