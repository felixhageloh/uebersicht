//
//  UBPreferencesController.h
//  Übersicht
//
//  Created by Felix Hageloh on 20/3/14.
//  Copyright (c) 2014 Felix Hageloh.
//
//  Released under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version. See <http://www.gnu.org/licenses/> for
//  details.

#import <Cocoa/Cocoa.h>

@interface UBPreferencesController : NSWindowController

@property (weak) IBOutlet NSPopUpButton *filePicker;
@property BOOL startAtLogin;
@property BOOL compatibilityMode;
@property NSURL* widgetDir;
@property BOOL loginShell;
@property BOOL enableInteraction;
@property BOOL alwaysOnTop;

- (IBAction)showFilePicker:(id)sender;

@end
