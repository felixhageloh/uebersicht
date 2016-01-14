//
//  UBWidgetsController.m
//  
//
//  Created by Felix Hageloh on 2/12/15.
//
//

#import "UBWidgetsController.h"
#import "UBScreensController.h"
#import "UBDispatcher.h"
#import <SocketRocket/SRWebSocket.h>

@implementation UBWidgetsController {
    UBScreensController* screensController;
    NSMenu* mainMenu;
    NSInteger currentIndex;
    NSURL* backendUrl;
    NSMutableDictionary* widgets;
    SRWebSocket* ws;
}

static NSInteger const WIDGET_MENU_ITEM_TAG = 42;
static NSInteger const SCREEN_MENU_ITEM_TAG = 43;

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
    [newItem setRepresentedObject:widgetId];
    [newItem setTag:WIDGET_MENU_ITEM_TAG];
    [newItem
        bind: @"value"
        toObject: widgets[widgetId]
        withKeyPath: @"hidden"
        options: @{
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
    [hide
        bind: @"value"
        toObject: widgets[widgetId]
        withKeyPath: @"hidden"
        options: nil
    ];
    
    [widgetMenu insertItem:hide atIndex:0];
    [self
        addScreens: [screensController screens]
        toWidgetMenu: widgetMenu
        forWidget: widgetId
    ];
    
    
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
    
        if (item.tag == WIDGET_MENU_ITEM_TAG) {
            [self removeScreensFromMenu:item.submenu];
            [self
                addScreens: screens
                toWidgetMenu: item.submenu
                forWidget: item.representedObject
            ];
        }
    }
    
    
}

- (void)addScreens:(NSDictionary*)screens
      toWidgetMenu:(NSMenu*)menu
      forWidget:(NSString*)widgetId
{
    NSString *title;
    NSMenuItem *newItem;
    NSString *name;
    NSNumber* widgetScreenId = widgets[widgetId][@"screenId"];
    
    newItem = [NSMenuItem separatorItem];
    [newItem setTag:SCREEN_MENU_ITEM_TAG];
    [menu insertItem:newItem atIndex:0];
    
    int i = 0;
    for(NSNumber* screenId in screens) {
        name = screens[screenId];
        title = [NSString stringWithFormat:@"Pin to %@", name];
        newItem = [[NSMenuItem alloc]
            initWithTitle: title
            action: @selector(screenWasSelected:)
            keyEquivalent: @""
        ];
        
        [newItem setTarget:self];
        [newItem setTag:SCREEN_MENU_ITEM_TAG];
        [newItem
            setRepresentedObject: @{
                @"screenId": screenId,
                @"widgetId": widgetId
            }
        ];
        
        if (widgetScreenId && (id)widgetScreenId != [NSNull null] &&
            [screenId isEqualToNumber:widgetScreenId]) {
            [newItem setState:YES];
        }
        [menu insertItem:newItem atIndex:i];
        i++;
    }
    
        newItem = [[NSMenuItem alloc]
        initWithTitle: @"Show on current main display"
        action: @selector(screenWasSelected:)
        keyEquivalent: @""
    ];
    
    [newItem setTarget:self];
    [newItem setTag:SCREEN_MENU_ITEM_TAG];
    [newItem
        setRepresentedObject: @{
            @"widgetId": widgetId
        }
    ];
    [menu insertItem:newItem atIndex:0];
    [newItem setState:(!widgetScreenId || (id)widgetScreenId == [NSNull null])];
}


- (void)removeScreensFromMenu:(NSMenu*)menu
{
    for (NSMenuItem *item in [menu itemArray]){
        if (item.tag == SCREEN_MENU_ITEM_TAG) {
            [menu removeItem:item];
        }
    }
}

- (void)markScreen:(NSNumber*)screenId inMenu:(NSMenu*)menu
{
     for (NSMenuItem *item in [menu itemArray]){
        if (item.tag != SCREEN_MENU_ITEM_TAG) {
            continue;
        }
        
        NSDictionary* data = item.representedObject;
        NSNumber* itemScreenId = data ? data[@"screenId"] : nil;
        screenId = (id)screenId == [NSNull null] ? nil : screenId;
        
        BOOL isSelected = (
            screenId &&
            itemScreenId &&
            [screenId isEqualToNumber:itemScreenId]
        );
        
        isSelected = isSelected || (!screenId && !itemScreenId);
        [item setState:isSelected];
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
    
    [[UBDispatcher sharedDispatcher]
        dispatch: isHidden ? @"WIDGET_DID_HIDE" : @"WIDGET_DID_UNHIDE"
        withPayload: widgetId
    ];
}


- (void)screenWasSelected:(id)sender
{
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    NSDictionary* data = [menuItem representedObject];
    NSNumber* screenId = data[@"screenId"];
    
    if (screenId) {
        widgets[data[@"widgetId"]][@"screenId"] = screenId;
    } else {
        [widgets[data[@"widgetId"]] removeObjectForKey:@"screenId"];
    }
    
    [[UBDispatcher sharedDispatcher]
        dispatch: @"WIDGET_DID_CHANGE_SCREEN"
        withPayload: @{
            @"id": data[@"widgetId"],
            @"screenId": screenId ? screenId : [NSNull null]
        }
    
    ];
    
    [self markScreen:screenId inMenu:menuItem.menu];
    
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
    }

}

@end
