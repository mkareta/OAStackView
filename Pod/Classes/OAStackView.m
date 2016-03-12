//
//  OAStackView.m
//  OAStackView
//
//  Created by Omar Abdelhafith on 14/06/2015.
//  Copyright © 2015 Omar Abdelhafith. All rights reserved.
//

#import "OAStackView.h"
#import "OAStackView+Constraint.h"
#import "OAStackView+Hiding.h"
#import "OAStackView+Traversal.h"
#import "OAStackViewAlignmentStrategy.h"
#import "OAStackViewDistributionStrategy.h"
#import "OATransformLayer.h"
#import <objc/runtime.h>

@interface UIView(OAHidden)

- (BOOL)oa_isHidden;
- (BOOL)oa_original_isHidden;

- (void)oa_setHidden:(BOOL)hidden;
- (void)oa_original_setHidden:(BOOL)hidden;

//+ (void)_setupAnimationWithDuration:(double)arg1 delay:(double)arg2 view:(id)arg3 options:(unsigned int)arg4 factory:(id)arg5 animations:(id /* block */)arg6 start:(id /* block */)arg7 animationStateGenerator:(id /* block */)arg8 completion:(id /* block */)arg9;

+ (void)oa_setupAnimationWithArg1:(double)arg1 arg2:(double)arg2 arg3:(id)arg3 arg4:(unsigned int)arg4 arg5:(id)arg5 arg6:(void (^)(void))arg6 arg7:(id)arg7 arg8:(id)arg8 completion:(void (^)(BOOL arg))completion;
+ (void)oa_original_setupAnimationWithArg1:(double)arg1 arg2:(double)arg2 arg3:(id)arg3 arg4:(unsigned int)arg4 arg5:(id)arg5 arg6:(void (^)(void))arg6 arg7:(id)arg7 arg8:(id)arg8 completion:(void (^)(BOOL arg))completion;

@end

@interface OAStackView ()
@property(nonatomic, strong) NSMutableArray *mutableArrangedSubviews;
@property(nonatomic) OAStackViewAlignmentStrategy *alignmentStrategy;
@property(nonatomic) OAStackViewDistributionStrategy *distributionStrategy;

// Not implemented but needed for backward compatibility with UIStackView
@property(nonatomic,getter=isBaselineRelativeArrangement) BOOL baselineRelativeArrangement;
@end

@implementation OAStackView

+ (Class)layerClass {
  return [OATransformLayer class];
}

#pragma mark - Initialization

+ (void)prepareRuntime {
  Method originalMethod = class_getInstanceMethod([UIView class], @selector(setHidden:));
  Method alternativeMethod = class_getInstanceMethod([UIView class], @selector(oa_setHidden:));
  class_replaceMethod([UIView class], @selector(oa_original_setHidden:), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
  class_replaceMethod([UIView class], @selector(setHidden:), method_getImplementation(alternativeMethod), method_getTypeEncoding(alternativeMethod));
  
  originalMethod = class_getInstanceMethod([UIView class], @selector(isHidden));
  alternativeMethod = class_getInstanceMethod([UIView class], @selector(oa_isHidden));
  class_replaceMethod([UIView class], @selector(oa_original_isHidden), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
  class_replaceMethod([UIView class], @selector(isHidden), method_getImplementation(alternativeMethod), method_getTypeEncoding(alternativeMethod));
  
  //+ (void)_setupAnimationWithDuration:(double)arg1 delay:(double)arg2 view:(id)arg3 options:(unsigned int)arg4 factory:(id)arg5 animations:(id /* block */)arg6 start:(id /* block */)arg7 animationStateGenerator:(id /* block */)arg8 completion:(id /* block */)arg9;
  NSData *selectorData = [[NSData alloc] initWithBase64EncodedString:@"X3NldHVwQW5pbWF0aW9uV2l0aER1cmF0aW9uOmRlbGF5OnZpZXc6b3B0aW9uczpmYWN0b3J5OmFuaW1hdGlvbnM6c3RhcnQ6YW5pbWF0aW9uU3RhdGVHZW5lcmF0b3I6Y29tcGxldGlvbjo=" options:0];
  NSString *selectorString = [[NSString alloc] initWithData:selectorData encoding:NSUTF8StringEncoding];
  SEL originalAnimationSelector = NSSelectorFromString(selectorString);
  
  originalMethod = class_getClassMethod([UIView class], originalAnimationSelector);
  alternativeMethod = class_getClassMethod([UIView class], @selector(oa_setupAnimationWithArg1:arg2:arg3:arg4:arg5:arg6:arg7:arg8:completion:));
  class_replaceMethod(object_getClass([UIView class]), @selector(oa_original_setupAnimationWithArg1:arg2:arg3:arg4:arg5:arg6:arg7:arg8:completion:), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
  class_replaceMethod(object_getClass([UIView class]), originalAnimationSelector, method_getImplementation(alternativeMethod), method_getTypeEncoding(alternativeMethod));
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super initWithCoder:decoder];

  if (self) {
    [self commonInitWithInitalSubviews:@[]];

    if ([NSStringFromClass([self class]) isEqualToString:@"UIStackView"]) {
      self.axis = [decoder decodeIntegerForKey:@"UIStackViewAxis"];
      self.distribution = [decoder decodeIntegerForKey:@"UIStackViewDistribution"];
      self.alignment = [decoder decodeIntegerForKey:@"UIStackViewAlignment"];
      self.spacing = [decoder decodeDoubleForKey:@"UIStackViewSpacing"];
      self.baselineRelativeArrangement = [decoder decodeBoolForKey:@"UIStackViewBaselineRelative"];
      self.layoutMarginsRelativeArrangement = [decoder decodeBoolForKey:@"UIStackViewLayoutMarginsRelative"];
    }

    [self layoutArrangedViews];
  }

  return self;
}

- (instancetype)initWithArrangedSubviews:(NSArray<__kindof UIView *> *)views {
  self = [super initWithFrame:CGRectZero];

  if (self) {
    [self commonInitWithInitalSubviews:views];
    [self layoutArrangedViews];
  }

  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  return [self initWithArrangedSubviews:@[]];
}

- (void)commonInitWithInitalSubviews:(NSArray *)initialSubviews {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [[self class] prepareRuntime];
  });
  
  _mutableArrangedSubviews = [initialSubviews mutableCopy];
  [self addViewsAsSubviews:initialSubviews];

  _axis = UILayoutConstraintAxisHorizontal;
  _alignment = OAStackViewAlignmentFill;
  _distribution = OAStackViewDistributionFill;

  _layoutMargins = UIEdgeInsetsMake(0, 8, 0, 8);
  _layoutMarginsRelativeArrangement = NO;

  self.alignmentStrategy = [OAStackViewAlignmentStrategy strategyWithStackView:self];
  self.distributionStrategy = [OAStackViewDistributionStrategy strategyWithStackView:self];
}

#pragma mark - Properties

- (NSArray *)arrangedSubviews {
  return self.mutableArrangedSubviews.copy;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
  // Does not have any effect because `CATransformLayer` is not rendered.
}

- (void)setOpaque:(BOOL)opaque {
  // Does not have any effect because `CATransformLayer` is not rendered.
}

- (void)setClipsToBounds:(BOOL)clipsToBounds {
  // Does not have any effect because `CATransformLayer` is not rendered.
}

- (void)setSpacing:(CGFloat)spacing {
  if (_spacing == spacing) { return; }

  _spacing = spacing;

  for (NSLayoutConstraint *constraint in self.constraints) {
    BOOL isWidthOrHeight =
    (constraint.firstAttribute == NSLayoutAttributeWidth) ||
    (constraint.firstAttribute == NSLayoutAttributeHeight);

    if ([self.subviews containsObject:constraint.firstItem] &&
        [self.subviews containsObject:constraint.secondItem] &&
        !isWidthOrHeight) {
      constraint.constant = spacing;
    }
  }
}

- (void)setAxis:(UILayoutConstraintAxis)axis {
  if (_axis == axis) { return; }
  _axis = axis;
  [self layoutArrangedViews];
}

- (void)setAxisValue:(NSInteger)axisValue {
  _axisValue = axisValue;
  self.axis = self.axisValue;
}

- (void)setAlignment:(OAStackViewAlignment)alignment {
  if (_alignment == alignment) { return; }

  _alignment = alignment;
  [self setAlignmentConstraints];
}

- (void)setAlignmentConstraints {
  self.alignmentStrategy = [OAStackViewAlignmentStrategy strategyWithStackView:self];

  [self.alignmentStrategy alignFirstView:self.subviews.firstObject];

  [self iterateViews:^(UIView *view, UIView *previousView) {
    [self.alignmentStrategy addConstraintsOnOtherAxis:view];
    [self.alignmentStrategy alignView:view withPreviousView:previousView];
  }];
  for (id view in self.mutableArrangedSubviews) {
    if ([view isHidden]) {
      [self hideView:view];
    } else {
      [self unHideView:view];
    }
  }
  
  [self.alignmentStrategy alignLastView:self.subviews.lastObject];
}

- (void)setAlignmentStrategy:(OAStackViewAlignmentStrategy *)alignmentStrategy {
  if ([_alignmentStrategy isEqual:alignmentStrategy]) {
    return;
  }

  [_alignmentStrategy removeAddedConstraints];
  _alignmentStrategy = alignmentStrategy;
}

- (void)setDistributionStrategy:(OAStackViewDistributionStrategy *)distributionStrategy {
  if ([_distributionStrategy isEqual:distributionStrategy]) {
    return;
  }

  [_distributionStrategy removeAddedConstraints];
  _distributionStrategy = distributionStrategy;
}

- (void)removeConstraint:(NSLayoutConstraint *)constraint {
  [super removeConstraint:constraint];
}

- (void)removeConstraints:(NSArray<__kindof NSLayoutConstraint *> *)constraints {
  [super removeConstraints:constraints];
}

- (void)updateConstraints {
  [super updateConstraints];
}

- (void)layoutSubviews {
  [super layoutSubviews];
}

- (void)setAlignmentValue:(NSInteger)alignmentValue {
  _alignmentValue = alignmentValue;
  self.alignment = alignmentValue;
}

- (void)setDistribution:(OAStackViewDistribution)distribution {
  if (_distribution == distribution) { return; }

  _distribution = distribution;
  [self layoutArrangedViews];
}

- (void)setDistributionConstraints {
  self.distributionStrategy = [OAStackViewDistributionStrategy strategyWithStackView:self];

  [self iterateViews:^(UIView *view, UIView *previousView) {
    [self.distributionStrategy alignView:view afterView:previousView];
  }];
  for (id view in self.mutableArrangedSubviews) {
    if ([view isHidden]) {
      [self hideView:view];
    } else {
      [self unHideView:view];
    }
  }

  [self.distributionStrategy alignView:nil afterView:self.mutableArrangedSubviews.lastObject];
}

- (void)setDistributionValue:(NSInteger)distributionValue {
  _distributionValue = distributionValue;
  self.distribution = distributionValue;
}

- (void)setLayoutMargins:(UIEdgeInsets)layoutMargins {
  _layoutMargins = layoutMargins;
  [self layoutArrangedViews];
}

- (void)setLayoutMarginsRelativeArrangement:(BOOL)layoutMarginsRelativeArrangement {
  _layoutMarginsRelativeArrangement = layoutMarginsRelativeArrangement;
  [self layoutArrangedViews];
}

#pragma mark - Overriden methods

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
  [self layoutArrangedViews];
}

#pragma mark - Adding and removing

- (void)addArrangedSubview:(UIView *)view {
  [self insertArrangedSubview:view atIndex:self.subviews.count];
}

- (void)removeArrangedSubview:(UIView *)view {
  [self removeViewFromArrangedViews:view];
}

- (void)insertArrangedSubview:(UIView *)view atIndex:(NSUInteger)stackIndex {
  if ([self.arrangedSubviews containsObject:view]) {
    [self removeArrangedSubview:view];
    [view removeFromSuperview];
  }
  
  view.translatesAutoresizingMaskIntoConstraints = NO;
  
  id previousView, nextView;
  BOOL isAppending = stackIndex == self.subviews.count;
  
  if (isAppending) {
    //Appending a new item
    
    previousView = [self.mutableArrangedSubviews lastObject];
    nextView = nil;
    
    NSArray<__kindof NSLayoutConstraint *> *constraints = [self lastConstraintAffectingView:self andView:previousView inAxis:self.axis];
    if (constraints) {
      [self removeConstraints:constraints];
    }
    
    [self.mutableArrangedSubviews addObject:view];
    [self addSubview:view];
    
  } else {
    //Item insertion
    
    previousView = stackIndex > 0 ? self.mutableArrangedSubviews[stackIndex - 1] : nil;
    nextView = stackIndex < self.mutableArrangedSubviews.count ? self.mutableArrangedSubviews[stackIndex] : nil;
    
    NSArray<__kindof NSLayoutConstraint *> *constraints = nil;
    BOOL isLastVisibleItem = nextView == nil;
    BOOL isFirstVisibleView = previousView == nil;
    BOOL isOnlyItem = previousView == nil && nextView == nil;
    
    if (isLastVisibleItem) {
      constraints = @[[self lastViewConstraint]];
    } else if(isOnlyItem) {
      constraints = [self constraintsBetweenView:previousView ?: self andView:nextView ?: self inAxis:self.axis];
    } else if(isFirstVisibleView) {
      constraints = @[[self firstViewConstraint]];
    } else {
      constraints = [self constraintsBetweenView:previousView ?: self andView:nextView ?: self inAxis:self.axis];
    }
    
    [self removeConstraints:constraints];
    
    [self.mutableArrangedSubviews insertObject:view atIndex:stackIndex];
    [self insertSubview:view atIndex:stackIndex];
  }
  
  [self.distributionStrategy alignView:view afterView:previousView];
  [self.alignmentStrategy alignView:view withPreviousView:previousView];
  [self.alignmentStrategy addConstraintsOnOtherAxis:view];
  [self.distributionStrategy alignView:nextView afterView:view];
  [self.alignmentStrategy alignView:nextView withPreviousView:view];
  
  if (view.isHidden) {
    [self hideView:view];
  } else {
    [self unHideView:view];
  }
}

- (void)removeViewFromArrangedViews:(UIView*)view {
  NSInteger index = [self.mutableArrangedSubviews indexOfObject:view];
  if (index == NSNotFound) { return; }

  id previousView = index > 0 ? self.mutableArrangedSubviews[index - 1] : nil;
  id nextView = index + 1 < self.mutableArrangedSubviews.count ? self.mutableArrangedSubviews[index + 1] : nil;
  
  [self.mutableArrangedSubviews removeObject:view];
  NSArray <__kindof NSLayoutConstraint *> *constraint = [self constraintsAffectingView:view];
  [self removeConstraints:constraint];

  if (nextView && previousView) {
    [self.distributionStrategy alignView:nextView afterView:previousView];
  } else if (nextView) {
    [self.distributionStrategy alignView:nextView afterView:nil];
  } else if (previousView) {
    [self.distributionStrategy alignView:nil afterView:previousView];
  }
}

#pragma mark - Hide and Unhide

- (void)setSpacingInRange:(NSRange)range spacing:(CGFloat)spacing {
  for (NSInteger index = range.location; index < NSMaxRange(range); index++) {
    NSArray *array = [self constraintsBetweenView:self.mutableArrangedSubviews[index] andView:self.mutableArrangedSubviews[index + 1] inAxis:self.axis includeReversed:YES];
    for (NSLayoutConstraint *constraint in array) {
      constraint.constant = spacing;
    }
  }
}

- (void)hideView:(UIView*)view {
    NSInteger viewIndex = [self.mutableArrangedSubviews indexOfObject:view];
    if (viewIndex == NSNotFound) { return; }

    NSLayoutConstraint *constraint = [[self class] constraintWithIdentifier:@"OAStackView-Hide" inView:view];
    if (!constraint) {
      NSLayoutAttribute attribute = self.axis == UILayoutConstraintAxisVertical ? NSLayoutAttributeHeight : NSLayoutAttributeWidth;
      constraint = [NSLayoutConstraint constraintWithItem:view attribute:attribute relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
        
      constraint.identifier = @"OAStackView-Hide";
      constraint.active = YES;
    }

    NSInteger previousViewIndex = [self visibleViewIndexBeforeIndex:viewIndex];
    NSInteger nextViewIndex = [self visibleViewIndexAfterIndex:viewIndex];

    if (NSNotFound == previousViewIndex && NSNotFound == nextViewIndex) {
      [self setSpacingInRange:NSMakeRange(0, self.mutableArrangedSubviews.count - 1) spacing:0];
    } else if (NSNotFound == previousViewIndex) {
      NSInteger index = viewIndex;
      NSInteger toIndex = nextViewIndex;
      [self setSpacingInRange:NSMakeRange(index, toIndex - index) spacing:0];
    } else if (NSNotFound == nextViewIndex) {
      NSInteger index = previousViewIndex;
      NSInteger toIndex = viewIndex;
      [self setSpacingInRange:NSMakeRange(index, toIndex - index) spacing:0];
    } else {
      NSInteger index = previousViewIndex;
      NSInteger toIndex = nextViewIndex;
      [self setSpacingInRange:NSMakeRange(index, toIndex - index) spacing:self.spacing / (toIndex - index)];
    }
}

- (void)unHideView:(UIView*)view {
  NSInteger viewIndex = [self.mutableArrangedSubviews indexOfObject:view];
  if (viewIndex == NSNotFound) { return; }
  NSLayoutConstraint *constraint = [[self class] constraintWithIdentifier:@"OAStackView-Hide" inView:view];
  if (constraint) {
    [view removeConstraint:constraint];
  }
  
  NSInteger previousViewIndex = [self visibleViewIndexBeforeIndex:viewIndex];
  NSInteger nextViewIndex = [self visibleViewIndexAfterIndex:viewIndex];
  if (NSNotFound != previousViewIndex) {
    NSInteger index = previousViewIndex;
    NSInteger toIndex = viewIndex;
    [self setSpacingInRange:NSMakeRange(index, toIndex - index) spacing:self.spacing / (toIndex - index)];
  }
  if (NSNotFound != nextViewIndex) {
    NSInteger index = viewIndex;
    NSInteger toIndex = nextViewIndex;
    [self setSpacingInRange:NSMakeRange(index, toIndex - index) spacing:self.spacing / (toIndex - index)];
  }
}

#pragma mark - Align View

- (void)layoutArrangedViews {
  NSMutableArray *constraints = [NSMutableArray array];
  [constraints addObjectsFromArray:self.alignmentStrategy.addedConstraints];
  [constraints addObjectsFromArray:self.distributionStrategy.addedConstraints];
  [self removeConstraints:constraints];

  [self setAlignmentConstraints];
  [self setDistributionConstraints];
}

- (void)addViewsAsSubviews:(NSArray*)views {
  for (UIView *view in views) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:view];
  }
}

@end

#pragma mark - Runtime Injection

// Constructors are called after all classes have been loaded.
__attribute__((constructor)) static void OAStackViewPatchEntry(void) {

  if (objc_getClass("UIStackView")) {
    return;
  }

  if (objc_getClass("OAStackViewDisableForwardToUIStackViewSentinel")) {
    return;
  }

  Class class = objc_allocateClassPair(OAStackView.class, "UIStackView", 0);
  if (class) {
    objc_registerClassPair(class);
  }
}

@implementation UIView(OAHidden)

static NSMutableArray *animationTimeStack = nil;

- (void)oa_setHiddenCount:(NSInteger)count {
  objc_setAssociatedObject(self, @selector(oa_hiddenCount), @(count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)oa_hiddenCount {
  return [objc_getAssociatedObject(self, @selector(oa_hiddenCount)) integerValue];
}

- (void)oa_setHidden:(BOOL)hidden {
  if ([self.superview isKindOfClass:[OAStackView class]]) {
    if (hidden) {
      [(OAStackView *)self.superview hideView:self];
    } else {
      [(OAStackView *)self.superview unHideView:self];
    }
    if (animationTimeStack.count > 0) {
      NSDictionary *animation = [animationTimeStack lastObject];
      [self oa_original_setHidden:NO];
      [self oa_setHiddenCount:[self oa_hiddenCount] + (hidden ? 1 : -1)];
      [UIView animateWithDuration:[animation[@"duration"] doubleValue] delay:[animation[@"delay"] doubleValue] options:UIViewAnimationOptionOverrideInheritedDuration animations:^{
        [[self superview] layoutIfNeeded];
      } completion:^(BOOL finished) {
        NSInteger count = [self oa_hiddenCount];
        count = count + (hidden ? -1 : 1);
        [self oa_setHiddenCount:count];
        if (count == 0) {
          [self oa_original_setHidden:hidden];
        }
      }];
    } else {
      [self oa_original_setHidden:hidden];
    }
  } else {
    [self oa_original_setHidden:hidden];
  }
}

- (void)oa_original_setHidden:(BOOL)hidden {
  
}

- (BOOL)oa_isHidden {
  return ([self oa_original_isHidden] || [self oa_hiddenCount] > 0);
}

- (BOOL)oa_original_isHidden {
  return YES;
}

+ (void)oa_setupAnimationWithArg1:(double)arg1 arg2:(double)arg2 arg3:(id)arg3 arg4:(unsigned int)arg4 arg5:(id)arg5 arg6:(void (^)(void))arg6 arg7:(id)arg7 arg8:(id)arg8 completion:(void (^)(BOOL arg))completion {
  //arg6 block signature "v8@?0"
  //completion block signature "v12@?0B8"
  if (nil == animationTimeStack) {
    animationTimeStack = [NSMutableArray array];
  }
  [animationTimeStack addObject:@{@"duration" : @(arg1), @"delay": @(arg2)}];
  [self oa_original_setupAnimationWithArg1:arg1 arg2:arg2 arg3:arg3 arg4:arg4 arg5:arg5 arg6:^() {
    if (arg6) { arg6();}
    [animationTimeStack removeLastObject];
  } arg7:arg7 arg8:arg8 completion:completion];
}

+ (void)oa_original_setupAnimationWithArg1:(double)arg1 arg2:(double)arg2 arg3:(id)arg3 arg4:(unsigned int)arg4 arg5:(id)arg5 arg6:(void (^)(void))arg6 arg7:(id)arg7 arg8:(id)arg8 completion:(void (^)(BOOL arg))completion {
}


@end

