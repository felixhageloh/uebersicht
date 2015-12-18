//
//  UBMouseHandler.h
//  
//
//  Created by Felix Hageloh on 23/11/15.
//
//

#import <Foundation/Foundation.h>
@class UBWindow;
@class UBPreferencesController;


@interface UBKeyHandler : NSObject

- (id)initWithPreferences:(UBPreferencesController*)thePreferences
                 listener:(id)aListener;

@end
