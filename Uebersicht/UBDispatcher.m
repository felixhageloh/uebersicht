//
//  UBDispatcher.m
//  
//
//  Created by Felix Hageloh on 11/1/16.
//
//

#import "UBDispatcher.h"


@implementation UBDispatcher {
    NSMutableArray* queuedMessages;
    SRWebSocket* ws;
}

+ (id)sharedDispatcher {
    static UBDispatcher* sharedDispatcher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDispatcher = [[self alloc] init];
    });
    return sharedDispatcher;
}

- (id)init {

    if (self = [super init]) {
        ws = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest
            requestWithURL:[NSURL URLWithString:@"ws://127.0.0.1:8080"]]
        ];
        ws.delegate = self;
        [ws open];
        
        queuedMessages = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)dispatch:(NSString*)type withPayload:(id)payload
{
    NSDictionary* message = @{ @"type": type, @"payload": payload };
    if (ws.readyState == SR_OPEN) {
        NSError* error;
        NSData* jsonData = [NSJSONSerialization
            dataWithJSONObject: message
            options: 0
            error: &error
        ];
        
        if (!jsonData) {
            NSLog(@"err: %@", error);
            return;
        }
    
        [ws
            send: [[NSString alloc]
                initWithData:jsonData
                encoding:NSUTF8StringEncoding
            ]
        ];
    } else {
        [queuedMessages addObject: message];
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    for (NSDictionary* message in queuedMessages) {
        [self dispatch:message[@"type"] withPayload:message[@"payload"]];
    }
    
    [queuedMessages removeAllObjects];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{

}


@end
