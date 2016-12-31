//
//  UBAppDelegate.h
//  Übersicht
//
//  Created by Felix Hageloh on 20/9/13.
//  Copyright (c) 2013 Felix Hageloh.
//
//  Released under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version. See <http://www.gnu.org/licenses/> for
//  details.

#import <Cocoa/Cocoa.h>
#import "UBScreenChangeListener.h"

@interface UBAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, UBScreenChangeListener>

@property (weak) IBOutlet NSMenu *statusBarMenu;

- (void)widgetDirDidChange;
- (void)compatibilityModeDidChange;
- (void)screensChanged:(NSDictionary*)screens;
- (IBAction)showPreferences:(id)sender;
- (IBAction)openWidgetDir:(id)sender;
- (IBAction)showDebugConsole:(id)sender;
- (IBAction)refreshWidgets:(id)sender;

@end
