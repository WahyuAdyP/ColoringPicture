//
//  GradientObject.m
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/23/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

#import "GradientObject.h"

@implementation GradientObject

-(instancetype) initWithNormlizeImage: (UIImage*) image withArea: (CGRect) newArea {
    self = [super init];
    if (self) {
        self.normalizeImage = image;
        self.area = newArea;    
    }
    return self;
}

@end
