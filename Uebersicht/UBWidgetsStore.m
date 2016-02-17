//
//  UBWidgetsStore.m
//  
//
//  Created by Felix Hageloh on 26/1/16.
//
//

#import "UBWidgetsStore.h"
#import "UBListener.h"


@implementation UBWidgetsStore {
    UBListener* listener;
    NSMutableDictionary* widgets;
    NSMutableDictionary* settings;
    NSArray* sortedWidgets;
    void (^changeHandler)(NSDictionary*);
    NSDictionary* defaultSettings;
}

- (id)init
{
    self = [super init];

    
    if (self) {
        widgets = [[NSMutableDictionary alloc] init];
        settings = [[NSMutableDictionary alloc] init];
        listener = [[UBListener alloc] init];
        
        defaultSettings = @{
            @"showOnAllScreens": @YES,
            @"showOnSelectedScreens": @NO,
            @"screens": @[]
        };
        
        [listener on:@"WIDGET_ADDED" do:^(NSDictionary* data) {
            [self addWidget:data];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_SETTINGS_CHANGED" do:^(NSDictionary* details) {
            settings[details[@"id"]] = [[NSMutableDictionary alloc]
                initWithDictionary:details[@"settings"]
            ];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_REMOVED" do:^(NSString* widgetId) {
            if (widgets[widgetId]) {
                [self removeWidget:widgetId];
                [self notifyChange];
            }
        }];
        
        [listener on:@"WIDGET_SET_TO_SELECTED_SCREENS" do:^(NSString* widgetId) {
            [self updateSettings:widgetId withPatch:@{
                @"showOnAllScreens": @NO,
                @"showOnSelectedScreens": @YES,
                @"showOnMainScreen": @NO,
            }];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_SET_TO_ALL_SCREENS" do:^(NSString* widgetId) {
            [self updateSettings:widgetId withPatch:@{
                @"showOnAllScreens": @YES,
                @"showOnSelectedScreens": @NO,
                @"showOnMainScreen": @NO,
                @"screens": @[]
            }];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_SET_TO_MAIN_SCREEN" do:^(NSString* widgetId) {
            [self updateSettings:widgetId withPatch:@{
                @"showOnAllScreens": @NO,
                @"showOnSelectedScreens": @NO,
                @"showOnMainScreen": @YES,
                @"screens": @[]
            }];
            [self notifyChange];
        }];
        
        [listener on:@"SCREEN_SELECTED_FOR_WIDGET" do:^(NSDictionary* data) {
            [self selectScreen:data[@"screenId"] forWidget:data[@"id"]];
            [self notifyChange];
        }];
        
        [listener on:@"SCREEN_DESELECTED_FOR_WIDGET" do:^(NSDictionary* data) {
            [self deselectScreen:data[@"screenId"] forWidget:data[@"id"]];
            [self notifyChange];
        }];
        
        [listener on:@"SCREENS_DID_CHANGE" do:^(NSDictionary* data) {
            [self notifyChange];;
        }];
    }
    
    return self;
}

- (void)onChange:(void (^)(NSDictionary*))aChangeHandler
{
    changeHandler = aChangeHandler;
}

- (NSDictionary*)get:(NSString*)widgetId
{
    NSMutableDictionary* widget;
    
    if (widgets[widgetId]) {
        widget = [[NSMutableDictionary alloc]
            initWithDictionary:widgets[widgetId]
        ];
        
        widget[@"settings"] = settings[widgetId];
    }
    
    return widget;
}

- (NSDictionary*)getSettings:(NSString*)widgetId
{
    return widgets[widgetId] ? settings[widgetId] : NULL;
}

- (NSArray*)sortedWidgets
{
    return sortedWidgets;
}

- (void)notifyChange
{
    if (changeHandler) {
        changeHandler(widgets);
    }
}


- (NSDictionary*)addWidget:(NSDictionary*)widget
{
    BOOL alreadyExists = !!widgets[widget[@"id"]];
    widgets[widget[@"id"]] = widget;
    if (!alreadyExists) {
        sortedWidgets = [widgets.allKeys
            sortedArrayUsingSelector:@selector(compare:)
        ];
    }
    
    if (!settings[widget[@"id"]]) {
        settings[widget[@"id"]] = [[NSMutableDictionary alloc]
            initWithDictionary:defaultSettings
        ];
    }
    
    return widget;
}

- (void)updateSettings:(NSString*)widgetId withPatch:(NSDictionary*)patch
{
    if (!settings[widgetId]) {
        settings[widgetId] = [[NSMutableDictionary alloc]
            initWithDictionary:defaultSettings
        ];
    }
    
    [settings[widgetId] addEntriesFromDictionary:patch];
}

- (void)removeWidget:(NSString*)widgetId
{
    [widgets removeObjectForKey:widgetId];
    
    sortedWidgets = [widgets.allKeys
        sortedArrayUsingSelector:@selector(compare:)
    ];
}

- (void)selectScreen:(NSNumber*)screenId forWidget:(NSString*)widgetId
{
    NSArray* screens = settings[widgetId][@"screens"];
    
    if (![screens containsObject:screenId]) {
        settings[widgetId][@"screens"] = [screens arrayByAddingObject:screenId];
    }
}

- (void)deselectScreen:(NSNumber*)screenId forWidget:(NSString*)widgetId
{
    NSArray* screens = settings[widgetId][@"screens"];
    NSPredicate *withoutScreen = [NSPredicate
        predicateWithBlock: ^BOOL(id s, NSDictionary * _) {
            return s != screenId;
        }
    ];
    
    settings[widgetId][@"screens"] = [screens
        filteredArrayUsingPredicate: withoutScreen
    ];
}


@end
