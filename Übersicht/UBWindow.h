//
//  UBWindow.h
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
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <CoreLocation/CoreLocation.h>

@interface UBWindow : NSWindow <CLLocationManagerDelegate>

@property (weak) IBOutlet WebView *webView;

- (void)loadUrl:(NSString*)url;
- (void)reload;
- (void)fillScreen:(CGDirectDisplayID)screenId;
- (void)sendToDesktop;
- (void)comeToFront;
- (BOOL)isInFront;

@end
