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


- (void)addWidget:(NSString*)widget toMenu:(NSMenu*)menu
{
    NSMenuItem* newItem = [[NSMenuItem alloc] init];
    
    [newItem setTitle:widget];
    [newItem setRepresentedObject:@"widget"];
    
    NSMenu* widgetMenu = [[NSMenu alloc] init];
    [screensController
        addScreensToMenu:widgetMenu
                 atIndex:0
              withAction:nil
               andTarget:self];
    [newItem setSubmenu:widgetMenu];
    [menu insertItem:newItem atIndex:currentIndex];
}

- (void)removeWidget:(NSString*)widget FromMenu:(NSMenu*)menu
{
    [menu removeItem:[menu itemWithTitle:widget]];
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

- (void)fetchWidgets:(NSURLRequest*)request
{
    [[[NSURLSession sharedSession]
        dataTaskWithRequest:request
        completionHandler:^(NSData* data, NSURLResponse* res, NSError* err){
            
            if (err) {
                return NSLog(
                    @"Error requesting widgets json: %@",
                    err.localizedDescription
                );
            }
            
            NSError* parseError = nil;
            NSDictionary *dictionary = [NSJSONSerialization
                JSONObjectWithData:data
                           options:0
                             error:&parseError];
            
            
            if (parseError) {
                NSLog(
                    @"Error parsing widgets json: %@",
                    parseError.localizedDescription
                );
            } else {
                NSLog(@"Response: %@", dictionary);
            }

        }] resume];
}

@end
