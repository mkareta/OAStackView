//
//  OAStackView+Traversal.h
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import <OAStackView/OAStackView.h>

@interface OAStackView (Traversal)

- (UIView*)visibleViewBeforeIndex:(NSInteger)index;

- (NSInteger)visibleViewIndexAfterIndex:(NSInteger)index;
- (NSInteger)visibleViewIndexBeforeIndex:(NSInteger)index;

- (UIView*)visibleViewAfterIndex:(NSInteger)index;

- (void)iterateViews:(void (^) (UIView *view, UIView *previousView))block;

- (NSLayoutConstraint*)firstViewConstraint;
- (NSLayoutConstraint*)lastViewConstraint;

@end
