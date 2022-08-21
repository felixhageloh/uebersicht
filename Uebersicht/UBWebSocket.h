//
//  UBWebSocket.h
//  
//
//  Created by Felix Hageloh on 24/1/16.
//
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@interface UBWebSocket : NSObject <SRWebSocketDelegate>

+ (id)sharedSocket;
- (void)open:(NSURL*)aUrl
       token:(NSString*)aToken;
- (void)close;
- (void)send:(id)message;
- (void)listen:(void (^)(id))listener;

@end
