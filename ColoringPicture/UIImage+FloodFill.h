//
//  UIImage+FloodFill.h
//  ImageFloodFilleDemo
//
//  Created by chintan on 15/07/13.
//  Copyright (c) 2013 ZWT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RadGradientLayer.h"
#import "GradientObject.h"
#import "LinkedListStack.h"

@interface UIImage (FloodFill)

- (UIImage *) floodFillFromPoint:(CGPoint)startPoint withColor:(UIColor *)newColor andTolerance:(NSInteger)tolerance andActionTap:(BOOL) isTap sameImage: (void (^)(BOOL))checkBlock;
- (UIImage *) floodFillFromPoint:(CGPoint)startPoint withColor:(UIColor *)newColor andTolerance:(NSInteger)tolerance  andActionTap:(BOOL) isTap useAntiAlias:(BOOL)antiAlias sameImage: (void (^)(BOOL))checkBlock;
- (UIImage *) floodFillFromPoint:(CGPoint)startPoint withGradientColor:(NSMutableArray *)newGradientColor andTolerance:(NSInteger)tolerance andActionTap:(BOOL) isTap sameImage: (void (^)(BOOL))checkBlock;
- (UIImage *) floodFillFromPoint:(CGPoint)startPoint withGradientColor:(NSMutableArray *)newGradientColor andTolerance:(NSInteger)tolerance andActionTap:(BOOL) isTap useAntiAlias:(BOOL)antiAlias sameImage: (void (^)(BOOL))checkBlock;
-(UIImage *) testes: (CGSize)size withPoint: (CGPoint)point withGradient: (NSMutableArray*) gradientColors withTolerance: (NSInteger)tolerance andTap: (BOOL) isTap;

@end
