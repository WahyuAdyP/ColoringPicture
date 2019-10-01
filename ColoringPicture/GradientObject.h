//
//  GradientObject.h
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/23/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface GradientObject : NSObject
@property (nonatomic) UIImage* normalizeImage;
@property (nonatomic) CGRect area;
@property (nonatomic) unsigned char *imgData;

-(instancetype) initWithNormlizeImage: (UIImage*) image withArea: (CGRect) newArea;
@end
