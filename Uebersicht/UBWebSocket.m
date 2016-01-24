//
//  UBWebSocket.m
//  
//
//  Created by Felix Hageloh on 24/1/16.
//
//

#import "UBWebSocket.h"

@implementation UBWebSocket {
    NSMutableArray* listeners;
    NSMutableArray* queuedMessages;
    SRWebSocket* ws;
}


+ (id)sharedSocket {
    static UBWebSocket* sharedSocket = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSocket = [[self alloc] init];
    });
    return sharedSocket;
}

- (id)init {

    if (self = [super init]) {
        ws = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest
            requestWithURL:[NSURL URLWithString:@"ws://127.0.0.1:8080"]]
        ];
        ws.delegate = self;
        [ws open];
        
        listeners = [[NSMutableArray alloc] init];
        queuedMessages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)send:(id)message
{
    if (ws.readyState == SR_OPEN) {
        [ws send:message];
    } else {
        [queuedMessages addObject: message];
    }
}

- (void)listen:(void (^)(id))listener
{
    [listeners addObject:listener];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    for (id message in queuedMessages) {
        [ws send:message];
    }
    
    [queuedMessages removeAllObjects];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    for (void (^listener)(id) in listeners) {
        listener(message);
    }
}

@end
