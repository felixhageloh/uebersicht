//
//  U_bersichtTests.m
//  ÜbersichtTests
//
//  Created by Felix Hageloh on 20/9/13.
//  Copyright (c) 2013 Felix Hageloh. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UBAppDelegate.h"
#import "UBWindow.h"

@interface ÜbersichtTests : XCTestCase
@end

@implementation ÜbersichtTests {
    UBAppDelegate* deletgate;
}

- (void)setUp
{
    [super setUp];
    deletgate = [[NSApplication sharedApplication] delegate];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testWindowIsFullscreen
{
    XCTAssertNotNil(deletgate.window);
    
    // view should occupy the entire screen minus the menubar
    NSRect windowFrame       = [deletgate.window frame];
    NSRect screenFrame       = [[NSScreen mainScreen] frame];
    screenFrame.size.height -= [[NSApp mainMenu] menuBarHeight];
    
    XCTAssertEqual(windowFrame.size.width, screenFrame.size.width);
    XCTAssertEqual(windowFrame.size.height, screenFrame.size.height);
    XCTAssertEqual(windowFrame.origin.x, screenFrame.origin.x);
    XCTAssertEqual(windowFrame.origin.y, screenFrame.origin.y);
}

- (void)testServerTask
{
    NSTask* serverTask = [deletgate valueForKey:@"widgetServer"];
    XCTAssertNotNil(serverTask);
    XCTAssert([serverTask isRunning]);
}

- (void)testMenuItem
{
    NSStatusItem* statusBarItem = [deletgate valueForKey:@"statusBarItem"];
    XCTAssertNotNil(deletgate.statusBarMenu);
    XCTAssertNotNil(statusBarItem);
    XCTAssertEqual([statusBarItem menu], deletgate.statusBarMenu);
}

- (void)testMainMenu
{
    NSMenu* mainMenu = deletgate.statusBarMenu;
    
    XCTAssertEqual([[mainMenu itemAtIndex:3] action], @selector(openWidgetDir:));
    XCTAssert([deletgate respondsToSelector:@selector(openWidgetDir:)]);
    
    XCTAssertEqual([[mainMenu itemAtIndex:4] action], @selector(showDebugConsole:));
    XCTAssert([deletgate respondsToSelector:@selector(showDebugConsole:)]);
}

@end
