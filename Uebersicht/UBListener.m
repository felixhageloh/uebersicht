//
//  UBListener.m
//  
//
//  Created by Felix Hageloh on 24/1/16.
//
//

#import "UBListener.h"
#import "UBWebSocket.h"

@implementation UBListener {
    NSMutableDictionary* listeners;
}

- (id)init
{
    self = [super init];
    if (self) {
        listeners = [[NSMutableDictionary alloc] init];
        
        [[UBWebSocket sharedSocket] listen:^(id message) {
            [self handleMessage:message];
        }];
    }
    return self;
}

- (void)on:(NSString*)type do:(void (^)(id))callback
{
    if (!listeners[type]) {
        listeners[type] = [[NSMutableArray alloc] init];
    }
    
    [listeners[type] addObject:callback];
}

- (void)handleMessage:(id)message
{
    NSDictionary* parsedMessage = [NSJSONSerialization
        JSONObjectWithData: [message dataUsingEncoding:NSUTF8StringEncoding]
        options: 0
        error: nil
    ];
    
    NSString* type = parsedMessage[@"type"];
    if (!listeners[type]) {
        return;
    }
    
    for (void (^listener)(id) in listeners[type]) {
        listener(parsedMessage[@"payload"]);
    }
}

@end
