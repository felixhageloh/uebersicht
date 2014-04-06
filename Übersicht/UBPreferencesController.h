//
//  UBPreferencesController.h
//  Übersicht
//
//  Created by Felix Hageloh on 20/3/14.
//  Copyright (c) 2014 tracesOf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UBPreferencesController : NSWindowController

@property (weak) IBOutlet NSToolbar* toolbar;
@property (weak) IBOutlet NSPopUpButton *filePicker;
@property BOOL startAtLogin;
@property NSURL* widgetDir;

- (IBAction)showFilePicker:(id)sender;

@end
