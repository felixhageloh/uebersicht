//
//  UBWidgetsController.m
//  
//
//  Created by Felix Hageloh on 2/12/15.
//
//

#import "UBWidgetsController.h"

@implementation UBWidgetsController {
    NSMenu* mainMenu;
    NSInteger currentIndex;
}

- (id)initWithMenu:(NSMenu*)menu
{
    self = [super init];
    
    
    if (self) {
        mainMenu = menu;
        
        currentIndex = [self indexOfWidgetMenuItems:menu];
        NSMenuItem* newItem = [NSMenuItem separatorItem];
        [newItem setRepresentedObject:@"widget"];
        [menu insertItem:newItem atIndex:currentIndex];
        currentIndex++;
        newItem = [NSMenuItem separatorItem];
        [newItem setRepresentedObject:@"widget"];
        [menu insertItem:newItem atIndex:currentIndex];
        
    }
    
    return self;
}

- (void)addWidget:(NSString*)widget
{
    [self addWidget:widget ToMenu:mainMenu action:nil target:self];
}


- (void)removeWidget:(NSString*)widget
{
    [self removeWidget:widget FromMenu:mainMenu];
}


- (void)addWidget:(NSString*)widget ToMenu:(NSMenu*)menu action:(SEL)action target:(id)target
{
    NSMenuItem* newItem = [[NSMenuItem alloc]
        initWithTitle:widget
        action:action
        keyEquivalent:@""];
    
    [newItem setRepresentedObject:@"widget"];
    [menu insertItem:newItem atIndex:currentIndex];
}

- (void)removeWidget:(NSString*)widget FromMenu:(NSMenu*)menu
{
    [menu removeItem:[menu itemWithTitle:widget]];
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
