//
//  RadGradientLayer.m
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/18/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

#import "RadGradientLayer.h"

@interface RadGradientLayer()
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat radius;
@property (nonatomic) NSMutableArray* colors;
@end

@implementation RadGradientLayer
@synthesize center;
@synthesize radius;
@synthesize colors;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setNeedsDisplayOnBoundsChange:YES];
    }
    return self;
}

-(instancetype) initWithCenter: (CGPoint) point withRadius: (CGFloat) myRadius withColors: (NSMutableArray*) myColors {
    
    [self setPoint:point];
    [self setRadius:myRadius];
    [self setColors:myColors];
    
    self = [super init];
    if (self) {
        [self setNeedsDisplay];
    }
    return self;
}

-(void) setPoint: (CGPoint) point {
    center = point;
//    [self setNeedsDisplay];
}

-(void) setRadius:(CGFloat)newRadius {
    radius = newRadius;
//    [self setNeedsDisplay];
}

-(void) setColors:(NSMutableArray *)newColors {
    colors = newColors;
//    [self setNeedsDisplay];
}

-(void) drawInContext:(CGContextRef)ctx {
    CGContextSaveGState(ctx);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGFloat locations[2];
    locations[0] = 0.0;
    locations[1] = 1.0;
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef) self.colors, locations);
    
    CGContextDrawRadialGradient(ctx, gradient, self.center, 0.0f, self.center, self.radius, kCGGradientDrawsAfterEndLocation);
}


@end
