//
//  OpenCVWrapper.h
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/7/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject
-(NSString *) openCVVersionString;
+ (UIImage *)floodFill:(UIImage*)inputImage point:(CGPoint)point replacementColor:(UIColor*)replacementColor;
+ (UIImage *) scanImage:(UIImage *)image;
@end
