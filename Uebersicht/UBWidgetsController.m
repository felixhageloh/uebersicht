//
//  UBWidgetsController.m
//  
//
//  Created by Felix Hageloh on 2/12/15.
//
//

#import "UBWidgetsController.h"
#import "UBWidgetsStore.h"
#import "UBScreensController.h"
#import "UBDispatcher.h"


@implementation UBWidgetsController {
    UBWidgetsStore* widgets;
    UBScreensController* screensController;
    NSMenu* mainMenu;
    NSInteger currentIndex;
    NSImage* statusIconVisible;
    NSImage* statusIconHidden;
    UBDispatcher* dispatcher;
}

static NSInteger const WIDGET_MENU_ITEM_TAG = 42;

- (id)initWithMenu:(NSMenu*)menu
           widgets:(UBWidgetsStore*)theWidgets
           screens:(UBScreensController*)screens
{
    self = [super init];
    
    
    if (self) {

        mainMenu = menu;
        widgets = theWidgets;
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
        
        dispatcher = [[UBDispatcher alloc] init];
       
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


- (void)render
{
     for (NSMenuItem *item in [mainMenu itemArray]) {
        if (item.tag == WIDGET_MENU_ITEM_TAG) {
            [mainMenu removeItem: item];
        }
    }
    
    NSString* widgetId;
    NSString* error;
    for (NSInteger i = widgets.sortedWidgets.count - 1; i >= 0; i--) {
        widgetId = widgets.sortedWidgets[i];
        [self renderWidget:widgetId inMenu:mainMenu];
        
        error = [widgets get:widgetId][@"error"];
        if (error) {
            [self notifyUser:error withTitle:@"Error"];
        }
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
    NSDictionary* settings = [widgets getSettings:widgetId];
    if ([settings[@"showOnSelectedScreens"] boolValue]) {
        [self
            addScreens: [screensController screens]
            toWidgetMenu: widgetMenu
            forWidget: widgetId
         ];
        [widgetMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
        [self addMainScreenOptionToMenu:widgetMenu forWidget:widgetId];
        [self addAllScreensOptionToMenu:widgetMenu forWidget:widgetId];
    } else if ([settings[@"showOnMainScreen"] boolValue]) {
        [self addSelectedScreensOptionToMenu:widgetMenu forWidget:widgetId];
        [self addAllScreensOptionToMenu:widgetMenu forWidget:widgetId];
    } else {
        [self addSelectedScreensOptionToMenu:widgetMenu forWidget:widgetId];
        [self addMainScreenOptionToMenu:widgetMenu forWidget:widgetId];
    }
    
    [self addEditMenuItemToMenu:widgetMenu forWidget:widgetId];
    [widgetMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
    
    
    [newItem setSubmenu:widgetMenu];
    [menu insertItem:newItem atIndex:currentIndex];
}

- (void)addEditMenuItemToMenu:(NSMenu*)menu forWidget:(NSString*)widgetId
{
    NSMenuItem* hide = [[NSMenuItem alloc]
        initWithTitle: @"Edit..."
        action: @selector(editWidget:)
        keyEquivalent: @""
    ];
    [hide setRepresentedObject:widgetId];
    [hide setTarget:self];
    [hide setState:[[widgets get:widgetId][@"hidden"] boolValue]];
    [menu insertItem:hide atIndex:0];

}

- (void)addMainScreenOptionToMenu:(NSMenu*)menu forWidget:(NSString*)widgetId
{
    NSMenuItem* pin = [[NSMenuItem alloc]
        initWithTitle: @"Show only on current main display"
        action: @selector(showOnMainScreen:)
        keyEquivalent: @""
    ];
    NSDictionary* settings = [widgets getSettings:widgetId];
    [pin setTarget:self];
    [pin setRepresentedObject:widgetId];
    [pin setState:[settings[@"showOnMainScreeen"] boolValue]];
    [menu insertItem:pin atIndex:0];
}


- (void)addAllScreensOptionToMenu:(NSMenu*)menu forWidget:(NSString*)widgetId
{
    NSMenuItem* pin = [[NSMenuItem alloc]
        initWithTitle: @"Show on all screens"
        action: @selector(showOnAllScreens:)
        keyEquivalent: @""
    ];
    NSDictionary* settings = [widgets getSettings:widgetId];
    [pin setTarget:self];
    [pin setRepresentedObject:widgetId];
    [pin setState:[settings[@"showOnAllScreens"] boolValue]];
    [menu insertItem:pin atIndex:0];
}

- (void)addSelectedScreensOptionToMenu:(NSMenu*)menu
                             forWidget:(NSString*)widgetId
{
    NSMenuItem* pin = [[NSMenuItem alloc]
        initWithTitle: @"Show only on selected screens"
        action: @selector(showOnSelectedScreens:)
        keyEquivalent: @""
    ];
    NSDictionary* settings = [widgets getSettings:widgetId];
    [pin setTarget:self];
    [pin setRepresentedObject:widgetId];
    [pin setState:[settings[@"showOnSelectedScreens"] boolValue]];
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
    NSArray* widgetScreens = [widgets getSettings:widgetId][@"screens"];
    
    newItem = [NSMenuItem separatorItem];
    [menu insertItem:newItem atIndex:0];
    
    int i = 0;
    for(NSNumber* screenId in screensController.sortedScreens) {
        name = screensController.screens[screenId];
        title = [NSString stringWithFormat:@"Show on %@", name];
        newItem = [[NSMenuItem alloc]
            initWithTitle: title
            action: @selector(toggleScreen:)
            keyEquivalent: @""
        ];
        
        [newItem setTarget:self];
        [newItem
            setRepresentedObject: @{
                @"screenId": screenId,
                @"widgetId": widgetId
            }
        ];
        
        if ([widgetScreens containsObject:screenId]) {
            [newItem setState:YES];
        }
        [menu insertItem:newItem atIndex:i];
        i++;
    }
}

- (BOOL)isWidgetVisible:(NSString*)widgetId
{
    NSDictionary* settings = [widgets getSettings:widgetId];
    BOOL isVisible = NO;
    
    if ([settings[@"showOnAllScreens"] boolValue]) {
        isVisible = YES;
    } else if ([settings[@"showOnMainScreen"] boolValue]) {
        isVisible = YES;
    } else if ([settings[@"showOnSelectedScreens"] boolValue]) {
        NSArray* screens = settings[@"screens"];
        isVisible = screens != nil && [screens count] > 0;
     }
    
    return isVisible;
}


-(NSInteger)indexOfWidgetMenuItems:(NSMenu*)menu
{
    return [menu indexOfItem:[menu itemWithTitle:@"Check for Updates..."]] + 2;
}


- (void)showOnAllScreens:(id)sender
{
    NSString* widgetId = [(NSMenuItem*)sender representedObject];
    
    [dispatcher
        dispatch: @"WIDGET_SET_TO_ALL_SCREENS"
        withPayload: widgetId
    ];
}

- (void)showOnSelectedScreens:(id)sender
{
    NSString* widgetId = [(NSMenuItem*)sender representedObject];
    
    [dispatcher
        dispatch: @"WIDGET_SET_TO_SELECTED_SCREENS"
        withPayload: widgetId
    ];
}

- (void)showOnMainScreen:(id)sender
{
    NSString* widgetId = [(NSMenuItem*)sender representedObject];
    
    [dispatcher
        dispatch: @"WIDGET_SET_TO_MAIN_SCREEN"
        withPayload: widgetId
    ];
}

- (void)toggleScreen:(id)sender
{
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    NSDictionary* data = [menuItem representedObject];
    NSNumber* screenId = data[@"screenId"];
    NSDictionary* widgetSettings = [widgets getSettings:data[@"widgetId"]];
    NSString* message;
    
    if ([(NSArray*)widgetSettings[@"screens"] containsObject:screenId]) {
        message = @"SCREEN_DESELECTED_FOR_WIDGET";
    } else {
        message = @"SCREEN_SELECTED_FOR_WIDGET";
    }

    [dispatcher
        dispatch: message
        withPayload: @{
            @"id": data[@"widgetId"],
            @"screenId": screenId
        }
    ];
}

- (void)editWidget:(id)sender
{
    NSString* widgetId = [(NSMenuItem*)sender representedObject];
    NSString* filePath = [widgets get:widgetId][@"filePath"];
    
    [[NSWorkspace sharedWorkspace] openFile:filePath];
}

- (void)notifyUser:(NSString*)message withTitle:(NSString*)title
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter]
        deliverNotification:notification
    ];
}


@end
