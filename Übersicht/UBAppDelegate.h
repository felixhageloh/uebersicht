//
//  UBAppDelegate.h
//  Übersicht
//
//  Created by Felix Hageloh on 20/9/13.
//  Copyright (c) 2013 tracesOf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class UBWindow;

@interface UBAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet WebView *mainView;
@property (weak) IBOutlet NSMenu *statusBarMenu;

- (void)widgetDirDidChange;
- (IBAction)showPreferences:(id)sender;
- (IBAction)openWidgetDir:(id)sender;
- (IBAction)showDebugConsole:(id)sender;

@end
