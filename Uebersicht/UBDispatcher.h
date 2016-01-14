//
//  UBDispatcher.h
//  
//
//  Created by Felix Hageloh on 11/1/16.
//
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@interface UBDispatcher : NSObject <SRWebSocketDelegate>

+ (id)sharedDispatcher;
- (void)dispatch:(NSString*)type withPayload:(id)payload;

@end
