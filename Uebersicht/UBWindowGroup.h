//
//  UBWindowGroup.h
//  Uebersicht
//
//  Created by Felix Hageloh on 05/10/2020.
//  Copyright © 2020 tracesOf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UBWindow.h"

NS_ASSUME_NONNULL_BEGIN

@interface UBWindowGroup : NSObject

@property (readonly, strong) UBWindow* foreground;
@property (readonly, strong) UBWindow* background;

- (id)initWithInteractionEnabled:(BOOL)interactionEnabled;
- (void)loadUrl:(NSURL*)Url;
- (void)setToken:(NSString*)token;
- (void)reload;
- (void)close;
- (void)setFrame:(NSRect)frame display:(BOOL)flag;
- (void)workspaceChanged;
- (void)wallpaperChanged;

@end

NS_ASSUME_NONNULL_END
