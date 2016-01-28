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
    NSArray* sortedWidgets;
    void (^changeHandler)(NSDictionary*);
}

- (id)init
{
    self = [super init];

    
    if (self) {
        widgets = [[NSMutableDictionary alloc] init];
        listener = [[UBListener alloc] init];
        
        [listener on:@"WIDGET_ADDED" do:^(NSDictionary* widget) {
            [self addWidget:widget];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_REMOVED" do:^(NSString* widgetId) {
            [self removeWidget:widgetId];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_DID_HIDE" do:^(NSString* widgetId) {
            [widgets[widgetId] setObject:@YES forKey:@"hidden"];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_DID_UNHIDE" do:^(NSString* widgetId) {
            [widgets[widgetId] setObject:@NO forKey:@"hidden"];
            [self notifyChange];
        }];
        
        
        [listener on:@"WIDGET_WAS_PINNED" do:^(NSString* widgetId) {
            [widgets[widgetId] setObject:@YES forKey:@"pinned"];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_WAS_PINNED" do:^(NSString* widgetId) {
            [widgets[widgetId] setObject:@NO forKey:@"pinned"];
            [self notifyChange];
        }];
        
        [listener on:@"WIDGET_DID_CHANGE_SCREEN" do:^(NSDictionary* data) {
            widgets[data[@"id"]][@"screenId"] = data[@"screenId"];
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
    return widgets[widgetId];
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


- (void)addWidget:(NSDictionary*)widget
{
    NSString* widgetId = widget[@"id"];
    if (!widgets[widgetId]) {
        widgets[widgetId] = [[NSMutableDictionary alloc]
            initWithDictionary:widget[@"settings"]
        ];
        
        [widgets[widgetId]
            setObject: widget[@"filePath"]
            forKey: @"filePath"
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


@end
