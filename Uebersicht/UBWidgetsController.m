//
//  UBWidgetsController.m
//  
//
//  Created by Felix Hageloh on 2/12/15.
//
//

#import "UBWidgetsController.h"
#import "UBScreensMenuController.h"

@implementation UBWidgetsController {
    UBScreensMenuController* screensController;
    NSMenu* mainMenu;
    NSInteger currentIndex;
    NSURL* backendUrl;
    NSMutableDictionary* widgets;
}

- (id)initWithMenu:(NSMenu*)menu andSettingsPath:(NSURL*)settingsPath
{
    self = [super init];
    
    
    if (self) {
        widgets = [self readSettings:
            [settingsPath URLByAppendingPathComponent:@"WidgetSettings.json"]
        ];
    
        mainMenu = menu;
        screensController = [[UBScreensMenuController alloc] init];
        
        currentIndex = [self indexOfWidgetMenuItems:menu];
        NSMenuItem* newItem = [NSMenuItem separatorItem];
        [menu insertItem:newItem atIndex:currentIndex];
        currentIndex++;
        newItem = [NSMenuItem separatorItem];
        [menu insertItem:newItem atIndex:currentIndex];
        
        
        backendUrl = [NSURL URLWithString:@"http://127.0.0.1:41416/widget/"];
    }
    
    return self;
}

- (void)addWidget:(NSString*)widgetId
{
    if (!widgets[widgetId]) {
        widgets[widgetId] = [[NSMutableDictionary alloc] init];
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
        action:@selector(hideWidget:)
        keyEquivalent:@""
    ];
    [hide setRepresentedObject:widgetId];
    [hide setTarget:self];
    [hide bind:@"value" toObject:widgets[widgetId] withKeyPath:@"hidden" options:nil];
    
    [widgetMenu insertItem:hide atIndex:0];
    
    [screensController
        addScreensToMenu:widgetMenu
                 atIndex:0
              withAction:nil
               andTarget:self];
    [newItem setSubmenu:widgetMenu];
    [menu insertItem:newItem atIndex:currentIndex];
}

- (void)removeWidget:(NSString*)widgetId FromMenu:(NSMenu*)menu
{
    [menu removeItem:[menu itemWithTitle:widgetId]];
}

- (void)screensChanged:(id)sender
{
    for (NSMenuItem *item in [mainMenu itemArray]){
        if ([item.representedObject isEqualToString:@"widget"]) {
            [screensController removeScreensFromMenu:item.submenu];
            [screensController
                addScreensToMenu:item.submenu
                         atIndex:0
                      withAction:nil
                       andTarget:self];
        }
    }
}

-(NSInteger)indexOfWidgetMenuItems:(NSMenu*)menu
{
    return [menu indexOfItem:[menu itemWithTitle:@"Check for Updates..."]] + 2;
}

- (void)syncWidget:(NSString*)widgetId updates:(NSDictionary*)updates
{
    NSMutableDictionary* newState = [[NSMutableDictionary alloc] init];
    [newState addEntriesFromDictionary:widgets[widgetId]];
    [newState addEntriesFromDictionary:updates];
    
    NSMutableURLRequest* request = [self
        buildSyncRequest:widgetId
               widthData:newState
    ];
    
    NSURLSessionDataTask* task = [[NSURLSession sharedSession]
        dataTaskWithRequest:request
        completionHandler:^(NSData* data, NSURLResponse* res, NSError* err){
            if (err) {
                return NSLog(
                    @"Error syncing widget: %@",
                    err.localizedDescription
                );
            }
            
            [widgets[widgetId] addEntriesFromDictionary:updates];
        }
    ];
    
    [task resume];
}

- (NSMutableURLRequest*)buildSyncRequest:(NSString*)widgetId widthData:(NSDictionary*)data
{
    NSMutableURLRequest* request = [NSMutableURLRequest
        requestWithURL: [backendUrl URLByAppendingPathComponent:widgetId]
    ];
    
    NSString* jsonBody = [NSString
        stringWithFormat:@"{\"hidden\": %@}",
        [data[@"hidden"] boolValue] ? @"true" : @"false"
    ];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:[jsonBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    return request;
}


- (void)hideWidget:(id)sender
{
    NSString* widgetId = [(NSMenuItem*)sender representedObject];
    [self syncWidget:widgetId
             updates:@{ @"hidden": @(![widgets[widgetId][@"hidden"] boolValue]) }];
}

- (NSMutableDictionary*)readSettings:(NSURL*)file
{
    NSMutableDictionary* settings;
    NSError* err;
    NSString *jsonString = [[NSString alloc]
        initWithContentsOfFile:[file path]
                      encoding:NSUTF8StringEncoding
                         error:&err
    ];
    
    if (!err) {
        settings = [NSJSONSerialization
            JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                       options:NSJSONReadingMutableContainers
                         error:&err
        ];
    } else {
        settings = [[NSMutableDictionary alloc] init];
    }
    
    return settings;
}

@end
