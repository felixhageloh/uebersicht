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
    NSMutableDictionary* widgets;
    NSArray* sortedWidgets;
    SRWebSocket* ws;
    NSImage* statusIconVisible;
    NSImage* statusIconHidden;

}

static NSInteger const WIDGET_MENU_ITEM_TAG = 42;

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
        [menu insertItem:[NSMenuItem separatorItem] atIndex:currentIndex];
        currentIndex++;
        NSMenuItem* header = [[NSMenuItem alloc] init];
        [header setTitle:@"Widgets"];
        [header setState:0];
        [mainMenu insertItem:header atIndex:currentIndex];
        currentIndex++;
        [menu insertItem:[NSMenuItem separatorItem] atIndex:currentIndex];
        
        
        ws = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest
            requestWithURL:[NSURL URLWithString:@"ws://127.0.0.1:8080"]]
        ];
        
        ws.delegate = self;
        [ws open];
        
        statusIconVisible = [[NSBundle mainBundle]
            imageForResource:@"widget-status-visible"
        ];
        [statusIconVisible setTemplate:YES];
        
        statusIconHidden = [[NSBundle mainBundle]
            imageForResource:@"widget-status-hidden"
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
    
    sortedWidgets = [widgets.allKeys
        sortedArrayUsingSelector:@selector(compare:)
    ];
}


- (void)removeWidget:(NSString*)widgetId
{
    if (widgets[widgetId]) {
        [widgets removeObjectForKey:widgetId];
    }
    
    sortedWidgets = [widgets.allKeys
        sortedArrayUsingSelector:@selector(compare:)
    ];
}

- (void)renderWidgetMenu
{
     for (NSMenuItem *item in [mainMenu itemArray]) {
        if (item.tag == WIDGET_MENU_ITEM_TAG) {
            [mainMenu removeItem: item];
        }
    }
    
    for (NSInteger i = sortedWidgets.count - 1; i >= 0; i--) {
        [self renderWidget:sortedWidgets[i] inMenu:mainMenu];
    }
}


- (void)renderWidget:(NSString*)widgetId inMenu:(NSMenu*)menu
{
    NSMenuItem* newItem = [[NSMenuItem alloc] init];
    
    [newItem setTitle:widgetId];
    [newItem setRepresentedObject:widgetId];
    [newItem setTag:WIDGET_MENU_ITEM_TAG];
    
    [newItem
        setImage:[self isWidgetVisible:widgetId]
            ? statusIconVisible
            : statusIconHidden
    ];
    
    
    NSMenu* widgetMenu = [[NSMenu alloc] init];
    [self addHideToggleToMenu:widgetMenu forWidget:widgetId];
    [widgetMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
    [self addPinnedToggleToMenu:widgetMenu forWidget:widgetId];
    [self
        addScreens: [screensController screens]
        toWidgetMenu: widgetMenu
        forWidget: widgetId
    ];
    
    
    [newItem setSubmenu:widgetMenu];
    [menu insertItem:newItem atIndex:currentIndex];
}

- (void)addHideToggleToMenu:(NSMenu*)menu forWidget:(NSString*)widgetId
{
    NSMenuItem* hide = [[NSMenuItem alloc]
        initWithTitle: @"Hidden"
        action: @selector(toggleHidden:)
        keyEquivalent: @""
    ];
    [hide setRepresentedObject:widgetId];
    [hide setTarget:self];
    [hide setState:[widgets[widgetId][@"hidden"] boolValue]];
    [menu insertItem:hide atIndex:0];
}

- (void)addPinnedToggleToMenu:(NSMenu*)menu forWidget:(NSString*)widgetId
{
    NSMenuItem* pin = [[NSMenuItem alloc]
        initWithTitle: @"Hide when screen is unavailable"
        action: @selector(togglePinned:)
        keyEquivalent: @""
    ];
    [pin setTarget:self];
    [pin setRepresentedObject:widgetId];
    [pin setState:[widgets[widgetId][@"pinned"] boolValue]];
    [menu insertItem:pin atIndex:0];
}

- (void)removeWidget:(NSString*)widgetId FromMenu:(NSMenu*)menu
{
    [menu removeItem:[menu itemWithTitle:widgetId]];
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
    [menu insertItem:newItem atIndex:0];
    
    int i = 0;
    for(NSNumber* screenId in screensController.sortedScreens) {
        name = screensController.screens[screenId];
        title = [NSString stringWithFormat:@"Show on %@", name];
        newItem = [[NSMenuItem alloc]
            initWithTitle: title
            action: @selector(screenWasSelected:)
            keyEquivalent: @""
        ];
        
        [newItem setTarget:self];
        [newItem
            setRepresentedObject: @{
                @"screenId": screenId,
                @"widgetId": widgetId
            }
        ];
        
        if (widgetScreenId &&
            [screenId isEqualToNumber:widgetScreenId]) {
            [newItem setState:YES];
        }
        [menu insertItem:newItem atIndex:i];
        i++;
    }
}

- (BOOL)isWidgetVisible:(NSString*)widgetId
{
    NSDictionary* widget = widgets[widgetId];
    BOOL screenUnavailable = !screensController.screens[widget[@"screenId"]];
    return (
        ![widget[@"hidden"] boolValue] &&
        !([widget[@"pinned"] boolValue] && screenUnavailable)
    );
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

- (void)togglePinned:(id)sender
{
    NSString* widgetId = [(NSMenuItem*)sender representedObject];
    BOOL isPinned = ![widgets[widgetId][@"pinned"] boolValue];
    
    [[UBDispatcher sharedDispatcher]
        dispatch: isPinned ? @"WIDGET_WAS_PINNED" : @"WIDGET_WAS_UNPINNED"
        withPayload: widgetId
    ];
}

- (void)screenWasSelected:(id)sender
{
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    NSDictionary* data = [menuItem representedObject];
    NSNumber* screenId = data[@"screenId"];

    [[UBDispatcher sharedDispatcher]
        dispatch: @"WIDGET_DID_CHANGE_SCREEN"
        withPayload: @{
            @"id": data[@"widgetId"],
            @"screenId": screenId
        }
    ];
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
        [self renderWidgetMenu];
    } else if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_REMOVED"]) {
        [self removeWidget:parsedMessage[@"payload"]];
        [self renderWidgetMenu];
    } else if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_DID_HIDE"]) {
        [widgets[parsedMessage[@"payload"]] setObject:@YES forKey:@"hidden"];
        [self renderWidgetMenu];
    } else if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_DID_UNHIDE"]) {
        [widgets[parsedMessage[@"payload"]] setObject:@NO forKey:@"hidden"];
        [self renderWidgetMenu];
    } else if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_WAS_PINNED"]) {
        [widgets[parsedMessage[@"payload"]] setObject:@YES forKey:@"pinned"];
        [self renderWidgetMenu];
    } else if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_WAS_UNPINNED"]) {
        [widgets[parsedMessage[@"payload"]] setObject:@NO forKey:@"pinned"];
        [self renderWidgetMenu];
    } else if ([parsedMessage[@"type"] isEqualToString:@"WIDGET_DID_CHANGE_SCREEN"]) {
        NSDictionary* data = parsedMessage[@"payload"];
        widgets[data[@"id"]][@"screenId"] = data[@"screenId"];
        [self renderWidgetMenu];
    } else if ([parsedMessage[@"type"] isEqualToString:@"SCREENS_DID_CHANGE"]) {
        [self renderWidgetMenu];
    }
}


@end
