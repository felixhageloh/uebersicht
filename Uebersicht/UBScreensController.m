//
//  UBScreensMenuController.m
//  
//
//  Created by Felix Hageloh on 8/11/15.
//
//

#import "UBScreensController.h"


int const MAX_DISPLAYS = 42;

@implementation UBScreensController {
    id listener;
}

@synthesize screens;

- (id)initWithChangeListener:(id)target;
{
    self = [super init];
    if (self) {
        screens = [[NSMutableDictionary alloc] initWithCapacity:MAX_DISPLAYS];
        listener = target;
        [self updateScreens];
        
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(screensChanged:)
                   name:NSApplicationDidChangeScreenParametersNotification
                 object:nil
        ];

    }
    
    return self;
}


- (void)updateScreens
{
    NSString *name;
    NSMutableDictionary *nameList = [[NSMutableDictionary alloc]
        initWithCapacity:MAX_DISPLAYS
    ];
    
    CGDirectDisplayID displays[MAX_DISPLAYS];
    uint32_t numDisplays;
    
    CGGetActiveDisplayList(MAX_DISPLAYS, displays, &numDisplays);
    
    [screens removeAllObjects];
    
    for(int i = 0; i < numDisplays; i++) {
        if (CGDisplayIsInMirrorSet(displays[i]))
            continue;
        
        name = [self screenNameForDisplay:displays[i]];
        if (!name)
            name = [NSString stringWithFormat:@"Display %i", i];
        
        NSNumber *count;
        if ((count = nameList[name])) {
            nameList[name] = [NSNumber numberWithInt:count.intValue+1];
            name = [name stringByAppendingString:[NSString
                stringWithFormat:@" (%i)", count.intValue+1]
            ];
        } else {
            nameList[name] = [NSNumber numberWithInt:1];
        }
        
        NSNumber* screenId = @(displays[i]);
        screens[screenId] = name;
    }

}

- (void)screensChanged:(id)sender
{
    [self updateScreens];
    [listener screensChanged:screens];
}


- (NSString*)screenNameForDisplay:(CGDirectDisplayID)displayID
{
    if (CGDisplayIsBuiltin(displayID)) {
        return @"Built-in Display";
    }
    
    CFDictionaryRef deviceInfo = getDisplayInfoDictionary(displayID);
    
    if (!deviceInfo) {
        return nil;
    }
    
    NSString *name = nil;
    NSDictionary *localizedNames = [(__bridge NSDictionary *)deviceInfo
        objectForKey:[NSString stringWithUTF8String:kDisplayProductName]
    ];
    if ([localizedNames count] > 0) {
        name = [localizedNames
            objectForKey:[[localizedNames allKeys] objectAtIndex:0]
        ];
    }
    CFRelease(deviceInfo);
    return name;
}


-(NSInteger)indexOfScreenMenuItems:(NSMenu*)menu
{
    return [menu indexOfItem:[menu itemWithTitle:@"Check for Updates..."]] + 2;
}

// can't belive you are making. me. do. this.
static CFDictionaryRef getDisplayInfoDictionary(CGDirectDisplayID displayID)
{
    CFDictionaryRef info = nil;
    io_iterator_t iter;
    io_service_t serv;
    
    CFMutableDictionaryRef matching = IOServiceMatching("IODisplayConnect");
    
    // releases matching for us
    kern_return_t err = IOServiceGetMatchingServices(
        kIOMasterPortDefault,
        matching,
        &iter
    );
    if (err) return nil;
    
    while ((serv = IOIteratorNext(iter)) != 0)
    {
        
        CFIndex vendorID, productID;
        CFNumberRef vendorIDRef, productIDRef;
        Boolean success;
        
        info = IODisplayCreateInfoDictionary(serv,kIODisplayOnlyPreferredName);
        
        vendorIDRef = CFDictionaryGetValue(info, CFSTR(kDisplayVendorID));
        productIDRef = CFDictionaryGetValue(info, CFSTR(kDisplayProductID));
        
        success = CFNumberGetValue(
            vendorIDRef,
            kCFNumberCFIndexType,
            &vendorID
        );
        
        success &= CFNumberGetValue(
            productIDRef,
            kCFNumberCFIndexType,
            &productID
        );
        
        if (!success || CGDisplayVendorNumber(displayID) != vendorID ||
            CGDisplayModelNumber(displayID)  != productID) {
            CFRelease(info);
            info = nil;
            continue;
        }
        
        break;
    }
    
    IOObjectRelease(serv);
    IOObjectRelease(iter);
    return info;
}


@end
