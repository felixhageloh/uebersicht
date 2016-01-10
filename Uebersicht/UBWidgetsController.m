//
//  UBWidgetsController.m
//  
//
//  Created by Felix Hageloh on 2/12/15.
//
//

#import "UBWidgetsController.h"
#import "UBScreensController.h"
#import <SocketRocket/SRWebSocket.h>

@implementation UBWidgetsController {
    UBScreensController* screensController;
    NSMenu* mainMenu;
    NSInteger currentIndex;
    NSURL* backendUrl;
    NSMutableDictionary* widgets;
    SRWebSocket* ws;
}

- (id)initWithMenu:(NSMenu*)menu
           screens:(UBScreensController*)screens
      settingsPath:(NSURL*)settingsPath
           baseUrl:(NSURL*)url
{
    self = [super init];
    
    
    if (self) {
        widgets = [[NSMutableDictionary alloc] init];
        mainMenu = menu;
        screensController = screens;
        
        currentIndex = [self indexOfWidgetMenuItems:menu];
        NSMenuItem* newItem = [NSMenuItem separatorItem];
        [menu insertItem:newItem atIndex:currentIndex];
        currentIndex++;
        newItem = [NSMenuItem separatorItem];
        [menu insertItem:newItem atIndex:currentIndex];
        
        
        ws = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest
            requestWithURL:[NSURL URLWithString:@"ws://127.0.0.1:8080"]]
        ];
        
        ws.delegate = self;
        [ws open];
        
        backendUrl = [url
            URLByAppendingPathComponent:@"widget"
        ];
    }
    
    return self;
}

- (void)addWidget:(NSDictionary*)widget
{
    NSString* widgetId = widget[@"id"];
    if (!widgets[widgetId]) {
        widgets[widgetId] = [[NSMutableDictionary alloc]
            initWithDictionary:widget[@"settings"]
        ];
    }
    [self addWidget:widgetId toMenu:mainMenu];
}


- (void)removeWidget:(NSString*)widgetId
{
    if (widgets[widgetId]) {
        [widgets removeObjectForKey:widgetId];
    }
    [self removeWidget:widgetId FromMenu:mainMenu];
}


- (void)addWidget:(NSString*)widgetId toMenu:(NSMenu*)menu
{
    NSMenuItem* newItem = [[NSMenuItem alloc] init];
    
    [newItem setTitle:widgetId];
    [newItem setRepresentedObject:@"widget"];
    [newItem bind:@"value"
         toObject:widgets[widgetId]
      withKeyPath:@"hidden"
          options:@{
            NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName
          }
    ];
    
    NSRect imageAlignment = NSMakeRect(0, -1, 22, 22);
    NSImage* statusImage = [NSImage imageNamed:NSImageNameStatusAvailable];
    [statusImage setAlignmentRect:imageAlignment];
    [newItem setOnStateImage:statusImage];
    
    statusImage = [NSImage imageNamed:NSImageNameStatusNone];
    [statusImage setAlignmentRect:imageAlignment];
    [newItem setOffStateImage:statusImage];
    
    NSMenu* widgetMenu = [[NSMenu alloc] init];
    NSMenuItem* hide = [[NSMenuItem alloc]
        initWithTitle:@"Hidden"
        action:@selector(toggleHidden:)
        keyEquivalent:@""
    ];
    [hide setRepresentedObject:widgetId];
    [hide setTarget:self];
    [hide bind:@"value" toObject:widgets[widgetId] withKeyPath:@"hidden" options:nil];
    
    [widgetMenu insertItem:hide atIndex:0];
    [self addScreens:[screensController screens] toWidgetMenu:widgetMenu];
    
    [newItem setSubmenu:widgetMenu];
    [menu insertItem:newItem atIndex:currentIndex];
}

- (void)removeWidget:(NSString*)widgetId FromMenu:(NSMenu*)menu
{
    [menu removeItem:[menu itemWithTitle:widgetId]];
}

- (void)screensChanged:(NSDictionary*)screens
{
    for (NSMenuItem *item in [mainMenu itemArray]) {
    
        if ([item.representedObject isEqualToString:@"widget"]) {
            [self removeScreensFromMenu:item.submenu];
            [self addScreens:screens toWidgetMenu:item.submenu];
        }
    }
}

- (void)addScreens:(NSDictionary*)screens toWidgetMenu:(NSMenu*)menu
{
    NSString *title;
    NSMenuItem *newItem;
    NSString *name;
    
    newItem = [NSMenuItem separatorItem];
    [newItem setRepresentedObject:@"screen"];
    [menu insertItem:newItem atIndex:0];

    
    int i = 0;
    for(NSNumber* screenId in screens) {
        name = screens[screenId];
        title = [NSString stringWithFormat:@"Show on %@", name];
        newItem = [[NSMenuItem alloc]
            initWithTitle:title
                   action:@selector(screenWasSelected:)
            keyEquivalent:@""
        ];
        [newItem setTarget:self];
        [newItem setTag:[screenId unsignedIntValue]];
        [newItem setRepresentedObject:@"screen"];
        [menu insertItem:newItem atIndex:i];
        i++;
    }
}


- (void)removeScreensFromMenu:(NSMenu*)menu
{
    for (NSMenuItem *item in [menu itemArray]){
        if ([item.representedObject isEqualToString:@"screen"]) {
            [menu removeItem:item];
        }
    }
}

// could probably use bindings for this
- (void)markScreen:(CGDirectDisplayID)screenId inMenu:(NSMenu*)menu
{
    for (NSMenuItem *item in [menu itemArray]){
        if (![item.representedObject isEqualToString:@"screen"])
            continue;
        
        [item setState:(item.tag == screenId ? NSOnState : NSOffState)];
    }
}

-(NSInteger)indexOfWidgetMenuItems:(NSMenu*)menu
{
    return [menu indexOfItem:[menu itemWithTitle:@"Check for Updates..."]] + 2;
}


- (void)toggleHidden:(id)sender
{
    NSString* widgetId = [(NSMenuItem*)sender representedObject];
    BOOL isHidden = ![widgets[widgetId][@"hidden"] boolValue];
    
    [ws send: [NSString
            stringWithFormat:@"{\"type\": \"%@\", \"payload\": \"%@\"}",
            isHidden ? @"WIDGET_DID_HIDE" : @"WIDGET_DID_UNHIDE",
            widgetId
        ]
    ];
}



- (void)screenWasSelected:(id)sender
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{

    NSDictionary* parsedMessage = [NSJSONSerialization
        JSONObjectWithData: [message dataUsingEncoding:NSUTF8StringEncoding]
        options: 0
        error: nil
    ];
    
    if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_ADDED"]) {
        [self addWidget:parsedMessage[@"payload"]];
    } else if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_REMOVED"]) {
        [self removeWidget:parsedMessage[@"payload"]];
    } else if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_DID_HIDE"]) {
        [widgets[parsedMessage[@"payload"]] setObject:@YES forKey:@"hidden"];
    } else if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_DID_UNHIDE"]) {
        [widgets[parsedMessage[@"payload"]] setObject:@NO forKey:@"hidden"];
    } else {
        NSLog(@"unhandled event: %@", parsedMessage[@"type"]);
    }

}

@end
