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
}

- (id)initWithMenu:(NSMenu*)menu
{
    self = [super init];
    
    
    if (self) {
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

- (void)addWidget:(NSString*)widget
{
    [self addWidget:widget toMenu:mainMenu];
}


- (void)removeWidget:(NSString*)widget
{
    [self removeWidget:widget FromMenu:mainMenu];
}


- (void)addWidget:(NSString*)widgetId toMenu:(NSMenu*)menu
{
    NSMenuItem* newItem = [[NSMenuItem alloc] init];
    
    [newItem setTitle:widgetId];
    [newItem setRepresentedObject:@"widget"];
    
    NSMenu* widgetMenu = [[NSMenu alloc] init];
    NSMenuItem* hide = [[NSMenuItem alloc]
        initWithTitle:@"hide"
        action:@selector(hideWidget:)
        keyEquivalent:@""
    ];
    [hide setRepresentedObject:widgetId];
    [hide setTarget:self];
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

- (void)updateWidget:(NSString*)widgetId
{
    NSMutableURLRequest* request = [NSMutableURLRequest
        requestWithURL: [backendUrl URLByAppendingPathComponent:widgetId]
    ];
    
    [request setHTTPMethod:@"PUT"];
    
    NSURLSessionDataTask* task = [[NSURLSession sharedSession]
        dataTaskWithRequest:request
        completionHandler:^(NSData* data, NSURLResponse* res, NSError* err){
            if (err) {
                return NSLog(
                    @"Error updating widget: %@",
                    err.localizedDescription
                );
            }
        }
    ];
    
    [task resume];
}


- (void)hideWidget:(id)sender
{
    [self updateWidget:[(NSMenuItem*)sender representedObject]];
}

@end
