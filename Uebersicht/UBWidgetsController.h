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
           baseUrl:(NSURL*)url;

- (void)addWidget:(NSDictionary*)widget;
- (void)removeWidget:(NSString*)widget;
- (void)screensChanged:(id)sender;
@end
