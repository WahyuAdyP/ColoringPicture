//
//  RadGradientLayer.h
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/18/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface RadGradientLayer : CALayer
-(instancetype) initWithCenter: (CGPoint) point withRadius: (CGFloat) radius withColors: (NSMutableArray*) colors;
@end
