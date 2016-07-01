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

@interface UBWindow : NSWindow

- (id)init;
- (void)loadUrl:(NSURL*)url;
- (void)reload;
- (void)sendToDesktop;
- (void)comeToFront;
- (BOOL)isInFront;
- (void)workspaceChanged;
- (void)wallpaperChanged;

@end
