//
//  UBWidgetsController.h
//  
//
//  Created by Felix Hageloh on 2/12/15.
//
//

#import <Cocoa/Cocoa.h>

@interface UBWidgetsController : NSController

- (id)initWithMenu:(NSMenu*)menu andSettingsPath:(NSURL*)settingsPath;
- (void)addWidget:(NSString*)widget;
- (void)removeWidget:(NSString*)widget;
- (void)screensChanged:(id)sender;
@end
