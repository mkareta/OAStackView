//
//  OAStackView+Traversal.m
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import "OAStackView+Traversal.h"

@interface OAStackView ()

- (NSMutableArray *)mutableArrangedSubviews;

@end


@implementation OAStackView (Traversal)

- (NSInteger)visibleViewIndexAfterIndex:(NSInteger)index {
  for (NSInteger i = index + 1; i < self.mutableArrangedSubviews.count; i++) {
    UIView *theView = self.mutableArrangedSubviews[i];
    if (!theView.hidden) {
        return i;
    }
  }

  return NSNotFound;
}

- (NSInteger)visibleViewIndexBeforeIndex:(NSInteger)index {
  for (NSInteger i = index - 1; i >= 0; i--) {
    UIView *theView = self.mutableArrangedSubviews[i];
    if (!theView.hidden) {
      return i;
    }
  }
  return NSNotFound;
}


- (UIView*)visibleViewAfterIndex:(NSInteger)index {
  for (NSInteger i = index + 1; i < self.mutableArrangedSubviews.count; i++) {
    UIView *theView = self.mutableArrangedSubviews[i];
    if (!theView.hidden) {
      return theView;
    }
  }
  
  return nil;
}

- (UIView*)visibleViewBeforeIndex:(NSInteger)index {
  for (NSInteger i = index - 1; i >= 0; i--) {
    UIView *theView = self.mutableArrangedSubviews[i];
    if (!theView.hidden) {
      return theView;
    }
  }
  
  return nil;
}

- (void)iterateViews:(void (^) (UIView *view, UIView *previousView))block {
  
  id previousView;
  for (UIView *view in self.mutableArrangedSubviews) {
    block(view, previousView);
    previousView = view;
  }
}

- (NSLayoutConstraint*)lastViewConstraint {
  for (NSLayoutConstraint *constraint in self.constraints) {
    
    if (self.axis == UILayoutConstraintAxisVertical) {
      if ( (constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeBottom) ||
          (constraint.secondItem == self && constraint.secondAttribute == NSLayoutAttributeBottom)) {
        return constraint;
      }
    } else {
      if ( (constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeTrailing) ||
          (constraint.secondItem == self && constraint.secondAttribute == NSLayoutAttributeTrailing)) {
        return constraint;
      }
    }
    
  }
  return nil;
}

- (NSLayoutConstraint*)firstViewConstraint {
  for (NSLayoutConstraint *constraint in self.constraints) {
    
    if (self.axis == UILayoutConstraintAxisVertical) {
      if ( (constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeTop) ||
          (constraint.secondItem == self && constraint.secondAttribute == NSLayoutAttributeTop)) {
        return constraint;
      }
    } else {
      if ( (constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeLeading) ||
          (constraint.secondItem == self && constraint.secondAttribute == NSLayoutAttributeLeading)) {
        return constraint;
      }
    }
    
  }
  return nil;
}

@end
