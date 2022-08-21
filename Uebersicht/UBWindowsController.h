//
//  UBWindowsController.h
//  Uebersicht
//
//  Created by Felix Hageloh on 30/09/2020.
//  Copyright © 2020 tracesOf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface UBWindowsController : NSObject


- (void)updateWindows:(NSDictionary*)screens
              baseUrl:(NSURL*)baseUrl
                token:(NSString*)token
   interactionEnabled:(Boolean)interactionEnabled
         forceRefresh:(Boolean)forceRefresh;

- (void)reloadAll;
- (void)closeAll;
- (void)workspaceChanged;
- (void)wallpaperChanged;
- (void)showDebugConsolesForScreen:(NSNumber*)screenId;

@end

NS_ASSUME_NONNULL_END
