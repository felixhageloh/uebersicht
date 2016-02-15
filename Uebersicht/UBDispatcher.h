//
//  UBDispatcher.h
//  
//
//  Created by Felix Hageloh on 11/1/16.
//
//

#import <Foundation/Foundation.h>


@interface UBDispatcher : NSObject

- (void)dispatch:(NSString*)type withPayload:(id)payload;

@end
