//
//  UBDispatcher.m
//  
//
//  Created by Felix Hageloh on 11/1/16.
//
//

#import "UBDispatcher.h"
#import "UBWebSocket.h"

@implementation UBDispatcher


- (void)dispatch:(NSString*)type withPayload:(id)payload
{
    NSDictionary* message = @{ @"type": type, @"payload": payload };

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

    [[UBWebSocket sharedSocket]
        send: [[NSString alloc]
            initWithData:jsonData
            encoding:NSUTF8StringEncoding
        ]
    ];
}


@end
