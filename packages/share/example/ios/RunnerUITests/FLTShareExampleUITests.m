// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

static const NSInteger kSecondsToWaitWhenFindingElements = 30;

@interface FLTShareExampleUITests : XCTestCase

@end

@implementation FLTShareExampleUITests

- (void)setUp {
  self.continueAfterFailure = NO;
}

- (void)testShareWithEmptyOrigin {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  [app launch];

  XCUIElement* shareWithEmptyOriginButton = [app.buttons
      elementMatchingPredicate:[NSPredicate
                                   predicateWithFormat:@"label == %@", @"Share With Empty Origin"]];
  if (![shareWithEmptyOriginButton waitForExistenceWithTimeout:kSecondsToWaitWhenFindingElements]) {
    NSLog(@"%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find shareWithEmptyOriginButton with %@ seconds", @(kSecondsToWaitWhenFindingElements));
  }

  XCTAssertNotNil(shareWithEmptyOriginButton);
  [shareWithEmptyOriginButton tap];

  // Find the share popup.
  XCUIElement* activityListView = [app.otherElements
      elementMatchingPredicate:[NSPredicate
                                   predicateWithFormat:@"identifier == %@", @"ActivityListView"]];
  if (![activityListView waitForExistenceWithTimeout:kSecondsToWaitWhenFindingElements]) {
    NSLog(@"%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find activityListView with %@ seconds", @(kSecondsToWaitWhenFindingElements));
  }
  XCTAssertNotNil(activityListView);
}

@end
