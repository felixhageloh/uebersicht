//
//  UBListener.h
//  
//
//  Created by Felix Hageloh on 24/1/16.
//
//

#import <Foundation/Foundation.h>

@interface UBListener : NSObject

- (void)on:(NSString*)type do:(void (^)(id))callback;

@end
