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
}

- (id)init
{
    self = [super init];

    
    if (self) {
        widgets = [[NSMutableDictionary alloc] init];
        settings = [[NSMutableDictionary alloc] init];
        listener = [[UBListener alloc] init];
        
        [listener on:@"WIDGET_ADDED" do:^(NSDictionary* data) {
            [self addWidget:data];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_SETTINGS_CHANGED" do:^(NSDictionary* details) {
            NSMutableDictionary* sett = [self getOrAddSettings:details[@"id"]];
            [sett addEntriesFromDictionary:details[@"settings"]];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_REMOVED" do:^(NSString* widgetId) {
            if (widgets[widgetId]) {
                [self removeWidget:widgetId];
                [self notifyChange];
            }
        }];
        
        [listener on:@"WIDGET_WAS_PINNED" do:^(NSString* widgetId) {
            NSMutableDictionary* sett = [self getOrAddSettings:widgetId];
            [sett setObject:@YES forKey:@"pinned"];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_WAS_UNPINNED" do:^(NSString* widgetId) {
            NSMutableDictionary* sett = [self getOrAddSettings:widgetId];
            [sett setObject:@NO forKey:@"pinned"];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_DID_CHANGE_SCREEN" do:^(NSDictionary* data) {
            NSMutableDictionary* sett = [self getOrAddSettings:data[@"id"]];
            sett[@"screenId"] = data[@"screenId"];
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
    BOOL alreadyExists = !!widgets[@"id"];
    widgets[widget[@"id"]] = widget;
    if (!alreadyExists) {
        sortedWidgets = [widgets.allKeys
            sortedArrayUsingSelector:@selector(compare:)
        ];
    }
    
    return widget;
}

- (NSMutableDictionary*)getOrAddSettings:(NSString*)widgetId
{
    if (!settings[widgetId]) {
        settings[widgetId] = [[NSMutableDictionary alloc] init];
    }
    
    return settings[widgetId];
}

- (void)removeWidget:(NSString*)widgetId
{
    [widgets removeObjectForKey:widgetId];
    
    sortedWidgets = [widgets.allKeys
        sortedArrayUsingSelector:@selector(compare:)
    ];
}


@end
