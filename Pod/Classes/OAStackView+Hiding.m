//
//  OAStackView+Hiding.m
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import "OAStackView+Hiding.h"

@implementation OAStackView (Hiding)

#pragma mark subviews

- (void)willRemoveSubview:(UIView *)subview {
  [super willRemoveSubview:subview];
  if ([self.arrangedSubviews containsObject:subview]) {
    [self removeArrangedSubview:subview];
  }
}

@end
