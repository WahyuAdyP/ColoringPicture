//
//  UIImage+FloodFill.m
//  ImageFloodFilleDemo
//
//  Created by chintan on 15/07/13.
//  Copyright (c) 2013 ZWT. All rights reserved.
//

#import "UIImage+FloodFill.h"

#define DEBUG_ANTIALIASING 0

@implementation UIImage (FloodFill)
/*
    startPoint : Point from where you want to color. Generaly this is touch point.
                 This is important because color at start point will be replaced with other.
    
    newColor   : This color will be apply at point where the match on startPoint color found.
 
    tolerance  : If Tolerance is 0 than it will search for exact match of color 
                 other wise it will take range according to tolerance value.
            
                 If You dont want to use tolerance and want to incress performance Than you can change
                 compareColor(ocolor, color, tolerance) with just ocolor==color which reduse function call.
*/

- (UIImage *) floodFillFromPoint:(CGPoint)startPoint withColor:(UIColor *)newColor andTolerance:(NSInteger)tolerance andActionTap:(BOOL) isTap sameImage: (void (^)(BOOL))checkBlock {
    NSMutableArray *arrayColor = [[NSMutableArray alloc] init];
    [arrayColor addObject:(id) newColor.CGColor];
    [arrayColor addObject:(id) newColor.CGColor];
    return [self floodFillFromPoint:startPoint withGradientColor:arrayColor andTolerance:tolerance andActionTap:isTap sameImage: checkBlock];
}

- (UIImage *) floodFillFromPoint:(CGPoint)startPoint withColor:(UIColor *)newColor andTolerance:(NSInteger)tolerance andActionTap:(BOOL) isTap useAntiAlias:(BOOL)antiAlias sameImage: (void (^)(BOOL))checkBlock {
    NSMutableArray *arrayColor = [[NSMutableArray alloc] init];
    [arrayColor addObject:(id) newColor.CGColor];
    [arrayColor addObject:(id) newColor.CGColor];
    return [self floodFillFromPoint:startPoint withGradientColor:arrayColor andTolerance:tolerance andActionTap:isTap useAntiAlias:antiAlias sameImage: checkBlock];
}

- (UIImage *) floodFillFromPoint:(CGPoint)startPoint withGradientColor:(NSMutableArray *)newGradientColor andTolerance:(NSInteger)tolerance andActionTap:(BOOL) isTap sameImage: (void (^)(BOOL))checkBlock
{
    return [self floodFillFromPoint:startPoint withGradientColor:newGradientColor andTolerance:tolerance andActionTap:isTap useAntiAlias:YES sameImage: checkBlock];
}

- (UIImage *) floodFillFromPoint:(CGPoint)startPoint withGradientColor:(NSMutableArray *)newGradientColor andTolerance:(NSInteger)tolerance andActionTap:(BOOL) isTap useAntiAlias:(BOOL)antiAlias sameImage: (void (^)(BOOL))checkBlock
{
    @try
    {
        /*
            First We create rowData from UIImage.
            We require this conversation so that we can use detail at pixel like color at pixel.
            You can get some discussion about this topic here:
            http://stackoverflow.com/questions/448125/how-to-get-pixel-data-from-a-uiimage-cocoa-touch-or-cgimage-core-graphics
        */
        
        //Gradient
        GradientObject *gradientObject = gradientColor(self.size, startPoint, self, newGradientColor, tolerance, isTap);
        unsigned char *grad = gradientObject.imgData;
        UIImage *normalizeImg = gradientObject.normalizeImage;
        
        if (CGRectEqualToRect(gradientObject.area, CGRectZero)) {
            free(gradientObject.imgData);
            checkBlock(YES);
            return self;
        }
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGImageRef imageRef = [normalizeImg CGImage];
        
        NSUInteger width = CGImageGetWidth(imageRef);
        NSUInteger height = CGImageGetHeight(imageRef);
        
        unsigned char *imageData = malloc(height * width * 4);
        
        NSUInteger bytesPerPixel = CGImageGetBitsPerPixel(imageRef) / 8;
        NSUInteger bytesPerRow = CGImageGetBytesPerRow(imageRef);
        NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
        
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
        if (kCGImageAlphaLast == (uint32_t)bitmapInfo || kCGImageAlphaFirst == (uint32_t)bitmapInfo) {
            bitmapInfo = (uint32_t)kCGImageAlphaPremultipliedLast;
        }
        
        CGContextRef context = CGBitmapContextCreate(imageData,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpace,
                                                     bitmapInfo);
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        
        //Get color at start point 
		NSUInteger byteIndex = (bytesPerRow * roundf(startPoint.y)) + roundf(startPoint.x) * bytesPerPixel;
        
        NSUInteger ocolor = getColorCode(byteIndex, imageData);
        
        NSUInteger bkColor = getColorCodeFromUIColor([UIColor blackColor], kCGBitmapByteOrderDefault);
        
        if (compareColor(ocolor, 0, 0)) {
            return nil;
        }
        
        //Convert newColor to RGBA value so we can save it to image.
        NSInteger newRed, newGreen, newBlue, newAlpha;
        
        UIColor *newColor = [UIColor colorWithCGColor:(__bridge CGColorRef _Nonnull)(newGradientColor[1])];
        const CGFloat *components = CGColorGetComponents(newColor.CGColor);
        
        /*
            If you are not getting why I use CGColorGetNumberOfComponents than read following link:
            http://stackoverflow.com/questions/9238743/is-there-an-issue-with-cgcolorgetcomponents
        */
        
        if(CGColorGetNumberOfComponents(newColor.CGColor) == 2)
        {
            newRed   = newGreen = newBlue = components[0] * 255;
            newAlpha = components[1] * 255;
        }
        else if (CGColorGetNumberOfComponents(newColor.CGColor) == 4)
        {
            if ((bitmapInfo&kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Little)
            {
                newRed   = components[2] * 255;
                newGreen = components[1] * 255;
                newBlue  = components[0] * 255;
                newAlpha = 255;
            }
            else
            {
                newRed   = components[0] * 255;
                newGreen = components[1] * 255;
                newBlue  = components[2] * 255;
                newAlpha = 255;
            }
        }
        
        NSUInteger ncolor = (newRed << 24) | (newGreen << 16) | (newBlue << 8) | newAlpha;
        
        /*
            We are using stack to store point.
            Stack is implemented by LinkList.
            To incress speed I have used NSMutableData insted of NSMutableArray.
            To see Detail Of This implementation visit following leink.
            http://iwantmyreal.name/blog/2012/09/29/a-faster-array-in-objective-c/
        */
        
        LinkedListStack *points = [[LinkedListStack alloc] initWithCapacity:500 incrementSize:500 andMultiplier:height];
        LinkedListStack *antiAliasingPoints = [[LinkedListStack alloc] initWithCapacity:500 incrementSize:500 andMultiplier:height];
        
        NSInteger x = roundf(startPoint.x);
        NSInteger y = roundf(startPoint.y);
        
        [points pushFrontX:x andY:y];
        
        /*
            This algorithem is prety simple though it llook odd in Objective C syntex.
            To get familer with this algorithm visit following link.
            http://lodev.org/cgtutor/floodfill.html
            You can read hole artical for knowledge. 
            If you are familer with flood fill than got to Scanline Floodfill Algorithm With Stack (floodFillScanlineStack)
        */
        
        NSUInteger color;
        BOOL spanLeft,spanRight;
        
        while ([points popFront:&x andY:&y] != INVALID_NODE_CONTENT)
        {
            byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
            
            color = getColorCode(byteIndex, imageData);
            
            while(y >= 0 && !compareColor(bkColor, color, tolerance))
            {
                y--;
                
                if(y >= 0)
                {
                    byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
                
                    color = getColorCode(byteIndex, imageData);
                }
            }
            
            // Add the top most point on the antialiasing list
            if(y >= 0 && !compareColor(bkColor, color, tolerance))
            {
                [antiAliasingPoints pushFrontX:x andY:y];
            }

            y++;
            
            spanLeft = spanRight = NO;
            
            byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
            
            color = getColorCode(byteIndex, imageData);
            
            newRed = grad[byteIndex];
            newGreen = grad[byteIndex + 1];
            newBlue = grad[byteIndex + 2];
            newAlpha = grad[byteIndex + 3];
            ncolor = (newRed << 24) | (newGreen << 16) | (newBlue << 8) | newAlpha;
            
            while (y < height && !compareColor(bkColor, color, tolerance) && color != ncolor)
            {
                
                imageData[byteIndex + 0] = newRed;
                imageData[byteIndex + 1] = newGreen;
                imageData[byteIndex + 2] = newBlue;
                imageData[byteIndex + 3] = newAlpha;
                
                newRed = grad[byteIndex];
                newGreen = grad[byteIndex + 1];
                newBlue = grad[byteIndex + 2];
                newAlpha = grad[byteIndex + 3];
                
                if(x > 0)
                {
                    byteIndex = (bytesPerRow * roundf(y)) + roundf(x - 1) * bytesPerPixel;
                    
                    color = getColorCode(byteIndex, imageData);

                    if(!spanLeft && x > 0 && !compareColor(bkColor, color, tolerance))
                    {
                        [points pushFrontX:(x - 1) andY:y];
                    
                        spanLeft = YES;
                    }
                    else if(spanLeft && x > 0 && compareColor(bkColor, color, tolerance))
                    {
                        spanLeft = NO;
                    }
                    
                    // we can't go left. Add the point on the antialiasing list
                    if(!spanLeft && x > 0 && !compareColor(bkColor, color, tolerance) && compareColor(ncolor, color, tolerance))
                    {
                        [antiAliasingPoints pushFrontX:(x - 1) andY:y];
                    }
                }

                if(x < width - 1)
                {
                    byteIndex = (bytesPerRow * roundf(y)) + roundf(x + 1) * bytesPerPixel;;
                    
                    color = getColorCode(byteIndex, imageData);
                    
                    if(!spanRight && !compareColor(bkColor, color, tolerance))
                    {
                        [points pushFrontX:(x + 1) andY:y];
                        
                        spanRight = YES;
                    }
                    else if(spanRight && compareColor(bkColor, color, tolerance))
                    {
                        spanRight = NO;
                    }
                    
                    // we can't go right. Add the point on the antialiasing list
                    if(!spanRight && !compareColor(bkColor, color, tolerance) && compareColor(ncolor, color, tolerance))
                    {
                        [antiAliasingPoints pushFrontX:(x + 1) andY:y];
                    }
                }
                
                y++;
                
                if(y < height)
                {
                    byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
                
                    color = getColorCode(byteIndex, imageData);
                }
            }
            
            if (y<height)
            {
                
                byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
                color = getColorCode(byteIndex, imageData);
                
                // Add the bottom point on the antialiasing list
                if (!compareColor(bkColor, color, tolerance))
                    [antiAliasingPoints pushFrontX:x andY:y];
            }
        }
        
        //Convert Flood filled image row data back to UIImage object.
        
        CGImageRef newCGImage = CGBitmapContextCreateImage(context);
        
        UIImage *result = [UIImage imageWithCGImage:newCGImage scale:[self scale] orientation:UIImageOrientationUp];
        
        CGImageRelease(newCGImage);
        
        CGContextRelease(context);
    
        free(imageData);
        
        free(gradientObject.imgData);
        
        checkBlock(NO);
        return result;
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception : %@", exception);
    }
}

GradientObject* gradientAreaFromPoint(CGPoint startPoint, UIImage* image, NSMutableArray* gradientColors, NSInteger tolerance, BOOL isTap)
{
    @try
    {
        /*
         First We create rowData from UIImage.
         We require this conversation so that we can use detail at pixel like color at pixel.
         You can get some discussion about this topic here:
         http://stackoverflow.com/questions/448125/how-to-get-pixel-data-from-a-uiimage-cocoa-touch-or-cgimage-core-graphics
         */
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGImageRef imageRef = [image CGImage];
        
        NSUInteger width = CGImageGetWidth(imageRef);
        NSUInteger height = CGImageGetHeight(imageRef);
        
        unsigned char *imageData = malloc(height * width * 4);
        
        NSUInteger bytesPerPixel = CGImageGetBitsPerPixel(imageRef) / 8;
        NSUInteger bytesPerRow = CGImageGetBytesPerRow(imageRef);
        NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
        
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
        if (kCGImageAlphaLast == (uint32_t)bitmapInfo || kCGImageAlphaFirst == (uint32_t)bitmapInfo) {
            bitmapInfo = (uint32_t)kCGImageAlphaPremultipliedLast;
        }
        
        CGContextRef context = CGBitmapContextCreate(imageData,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpace,
                                                     bitmapInfo);
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        
        unsigned char *oriImageData = malloc(height * width * 4);
        
        CGContextRef oriContext = CGBitmapContextCreate(oriImageData,
                                                        width,
                                                        height,
                                                        bitsPerComponent,
                                                        bytesPerRow,
                                                        colorSpace,
                                                        bitmapInfo);
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawImage(oriContext, CGRectMake(0, 0, width, height), imageRef);
        
        //Get color at start point
        NSUInteger byteIndex = (bytesPerRow * roundf(startPoint.y)) + roundf(startPoint.x) * bytesPerPixel;
        
        NSUInteger ocolor = getColorCode(byteIndex, imageData);
        
        NSUInteger bkColor = getColorCodeFromUIColor([UIColor blackColor], kCGBitmapByteOrderDefault);
        
        if (compareColor(ocolor, 0, 0)) {
            return [[GradientObject alloc] initWithNormlizeImage:nil withArea:CGRectZero];
        }
        
        //Convert newColor to RGBA value so we can save it to image.
        NSInteger newRed, newGreen, newBlue, newAlpha;
        
        UIColor *newColor = [UIColor whiteColor];
        
        if (compareColor(ocolor, getColorCodeFromUIColor(newColor, kCGBitmapByteOrderDefault), tolerance)) {
            newColor = [UIColor blueColor];
        }
        
        const CGFloat *components = CGColorGetComponents(newColor.CGColor);
        
        /*
         If you are not getting why I use CGColorGetNumberOfComponents than read following link:
         http://stackoverflow.com/questions/9238743/is-there-an-issue-with-cgcolorgetcomponents
         */
        
        if(CGColorGetNumberOfComponents(newColor.CGColor) == 2)
        {
            newRed   = newGreen = newBlue = components[0] * 255;
            newAlpha = components[1] * 255;
        }
        else if (CGColorGetNumberOfComponents(newColor.CGColor) == 4)
        {
            if ((bitmapInfo&kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Little)
            {
                newRed   = components[2] * 255;
                newGreen = components[1] * 255;
                newBlue  = components[0] * 255;
                newAlpha = 255;
            }
            else
            {
                newRed   = components[0] * 255;
                newGreen = components[1] * 255;
                newBlue  = components[2] * 255;
                newAlpha = 255;
            }
        }
        
        NSUInteger ncolor = (newRed << 24) | (newGreen << 16) | (newBlue << 8) | newAlpha;
        
        /*
         We are using stack to store point.
         Stack is implemented by LinkList.
         To incress speed I have used NSMutableData insted of NSMutableArray.
         To see Detail Of This implementation visit following leink.
         http://iwantmyreal.name/blog/2012/09/29/a-faster-array-in-objective-c/
         */
        
        LinkedListStack *points = [[LinkedListStack alloc] initWithCapacity:500 incrementSize:500 andMultiplier:height];
        LinkedListStack *antiAliasingPoints = [[LinkedListStack alloc] initWithCapacity:500 incrementSize:500 andMultiplier:height];
        
        NSInteger x = roundf(startPoint.x);
        NSInteger y = roundf(startPoint.y);
        
        [points pushFrontX:x andY:y];
        
        /*
         This algorithem is prety simple though it llook odd in Objective C syntex.
         To get familer with this algorithm visit following link.
         http://lodev.org/cgtutor/floodfill.html
         You can read hole artical for knowledge.
         If you are familer with flood fill than got to Scanline Floodfill Algorithm With Stack (floodFillScanlineStack)
         */
        
        NSUInteger color;
        BOOL spanLeft,spanRight;
        
        BOOL isFirstColorSame = false;
        BOOL isSecondColorSame = false;
        NSUInteger firstGradColor = getColorCodeFromUIColor([UIColor colorWithCGColor:(__bridge CGColorRef _Nonnull)(gradientColors[0])], kCGBitmapByteOrderDefault);
        NSUInteger secondGradColor = getColorCodeFromUIColor([UIColor colorWithCGColor:(__bridge CGColorRef _Nonnull)(gradientColors[1])], kCGBitmapByteOrderDefault);
        
        NSUInteger firstColor = 0;
        NSUInteger secondColor = 0;
        
        NSInteger minY = height, maxY = 0;
        NSInteger minX = width, maxX = 0;
        NSInteger minXCoordY, maxXCoordY;
        NSInteger minYCoordX, maxYCoordX;
        
        while ([points popFront:&x andY:&y] != INVALID_NODE_CONTENT)
        {
            byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
            
            color = getColorCode(byteIndex, imageData);
            
            while(y >= 0 && !compareColor(bkColor, color, tolerance))
            {
                y--;
                
                if(y >= 0)
                {
                    byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
                    
                    color = getColorCode(byteIndex, imageData);
                }
            }
            
            // Add the top most point on the antialiasing list
            if(y >= 0 && !compareColor(bkColor, color, 0))
            {
                [antiAliasingPoints pushFrontX:x andY:y];
            }
            
            y++;
            
            spanLeft = spanRight = NO;
            
            byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
            
            color = getColorCode(byteIndex, imageData);
            
            while (y < height && !compareColor(bkColor, color, tolerance) && ncolor != color)
            {
                if (firstColor == 0) {
                    firstColor = getColorCode(byteIndex, imageData);
                }
                if (secondColor == 0 || !compareColor(firstColor, getColorCode(byteIndex, imageData), tolerance)) {
                    secondColor = getColorCode(byteIndex, imageData);
                }
                
                imageData[byteIndex + 0] = newRed;
                imageData[byteIndex + 1] = newGreen;
                imageData[byteIndex + 2] = newBlue;
                imageData[byteIndex + 3] = newAlpha;
                
                if(x > 0)
                {
                    byteIndex = (bytesPerRow * roundf(y)) + roundf(x - 1) * bytesPerPixel;
                    
                    color = getColorCode(byteIndex, imageData);
                    
                    if (!isFirstColorSame) {
                        isFirstColorSame = compareColor(firstGradColor, getColorCode(byteIndex, imageData), tolerance);
                    }
                    if (!isSecondColorSame) {
                        isSecondColorSame = compareColor(secondGradColor, getColorCode(byteIndex, imageData), tolerance);
                    }
                    
                    if(!spanLeft && x > 0 && !compareColor(bkColor, color, tolerance))
                    {
                        [points pushFrontX:(x - 1) andY:y];
                        
                        spanLeft = YES;
                    }
                    else if(spanLeft && x > 0 && compareColor(bkColor, color, tolerance))
                    {
                        spanLeft = NO;
                    }
                    
                    // we can't go left. Add the point on the antialiasing list
                    if(!spanLeft && x > 0 && !compareColor(bkColor, color, tolerance) && !compareColor(ncolor, color, tolerance))
                    {
                        [antiAliasingPoints pushFrontX:(x - 1) andY:y];
                    }
                }
                
                if(x < width - 1)
                {
                    byteIndex = (bytesPerRow * roundf(y)) + roundf(x + 1) * bytesPerPixel;;
                    
                    color = getColorCode(byteIndex, imageData);
                    
                    if (!isFirstColorSame) {
                        isFirstColorSame = compareColor(firstGradColor, getColorCode(byteIndex, imageData), tolerance);
                    }
                    if (!isSecondColorSame) {
                        isSecondColorSame = compareColor(secondGradColor, getColorCode(byteIndex, imageData), tolerance);
                    }
                    
                    if(!spanRight && !compareColor(bkColor, color, tolerance))
                    {
                        [points pushFrontX:(x + 1) andY:y];
                        
                        spanRight = YES;
                    }
                    else if(spanRight && compareColor(bkColor, color, tolerance))
                    {
                        spanRight = NO;
                    }
                    
                    // we can't go right. Add the point on the antialiasing list
                    if(!spanRight && !compareColor(bkColor, color, tolerance) && !compareColor(ncolor, color, tolerance))
                    {
                        [antiAliasingPoints pushFrontX:(x + 1) andY:y];
                    }
                }
                
                y++;
                
                if(y < height)
                {
                    byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
                    
                    color = getColorCode(byteIndex, imageData);
                }
                
                minXCoordY = x < minX ? y : minXCoordY;
                maxXCoordY = x > maxX ? y : maxXCoordY;
                minYCoordX = y < minY ? x : minYCoordX;
                maxYCoordX = y > maxY ? x : maxYCoordX;
                
                minY = MIN(minY, y);
                maxY = MAX(maxY, y);
                minX = MIN(minX, x);
                maxX = MAX(maxX, x);
            }
            
            if (y<height)
            {
                
                byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
                color = getColorCode(byteIndex, imageData);
                
                // Add the bottom point on the antialiasing list
                if (!compareColor(bkColor, color, 0))
                    [antiAliasingPoints pushFrontX:x andY:y];
            }
        }
        
//        CGPoint newPoint = CGPointMake(startPoint.x - minX, startPoint.y - minY - 1);
//        NSInteger coordY = newPoint.x > ((maxX - minX + 1) - newPoint.x) ? minXCoordY + 1 : maxXCoordY - 1;
//        NSInteger coordX = newPoint.y > ((maxY - minY + 1) - newPoint.y) ? minYCoordX + 1 : maxYCoordX - 1;
//        NSInteger farX = newPoint.x + 1 > ((maxX - minX + 1) - newPoint.x) - 1 ? minX + 1 : maxX - 1;
//        NSInteger farY = newPoint.y + 1 > ((maxY - minY + 1) - newPoint.y) - 1 ? minY + 1 : maxY - 1;
//        
//        NSUInteger currentByteIndex;
//        NSUInteger currentColor;
//        
//        if (farY > farX) {
//            currentByteIndex = (bytesPerRow * roundf(farY)) + roundf(coordX) * bytesPerPixel;
//            currentColor = getColorCode(currentByteIndex, oriImageData);
//        } else {
//            currentByteIndex = (bytesPerRow * roundf(coordY)) + roundf(farX) * bytesPerPixel;
//            currentColor = getColorCode(currentByteIndex, oriImageData);
//        }
//        
//        NSUInteger outerColor = getColorCodeFromUIColor([UIColor colorWithCGColor:(__bridge CGColorRef _Nonnull)(gradientColors[1])], kCGBitmapByteOrderDefault);
        
        BOOL isSolid = compareColor(firstGradColor, secondGradColor, tolerance);
        BOOL isCompareSolid = compareColor(firstColor, secondColor, tolerance);
        BOOL isSame = (isSolid && isCompareSolid) || (!isSolid && !isCompareSolid);
        
        if (isFirstColorSame && isSecondColorSame && !isTap && isSame) {
            CGContextRelease(context);
            
            free(imageData);
            
            CGContextRelease(oriContext);
            
            free(oriImageData);
            
            return [[GradientObject alloc] initWithNormlizeImage:image withArea:CGRectZero];
        }
        
        CGImageRef newCGImage = CGBitmapContextCreateImage(context);
        
        UIImage *result = [UIImage imageWithCGImage:newCGImage scale:[image scale] orientation:UIImageOrientationUp];
        
        CGImageRelease(newCGImage);
        
        CGContextRelease(context);
        
        free(imageData);
        
        CGContextRelease(oriContext);
        
        free(oriImageData);
        
        return [[GradientObject alloc] initWithNormlizeImage:result withArea:CGRectMake(minX, minY - 1, maxX - minX + 1, maxY - minY)];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception : %@", exception);
    }
}

-(UIImage *) testes: (CGSize)size withPoint: (CGPoint)point withGradient: (NSMutableArray*) gradientColors withTolerance: (NSInteger)tolerance andTap: (BOOL) isTap {
    GradientObject* gradientObject = gradientAreaFromPoint(point, self, gradientColors, tolerance, isTap);
    CGRect gradientArea = gradientObject.area;
    
    CAShapeLayer *caLayer = [CAShapeLayer layer];
    caLayer.bounds = CGRectMake(0, 0, self.size.width, self.size.height);;
    caLayer.fillColor = [UIColor redColor].CGColor;
    caLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    CGPoint newPoint = CGPointMake(point.x - gradientArea.origin.x, point.y - gradientArea.origin.y);
    RadGradientLayer *radLayer = [[RadGradientLayer alloc] initWithCenter:newPoint withRadius:MIN(gradientArea.size.width, gradientArea.size.height)/2 withColors:gradientColors];
    radLayer.frame = gradientArea;
    
    [caLayer addSublayer:radLayer];
    
    UIGraphicsBeginImageContext(self.size);
    [caLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef imageRef = [image CGImage];
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    unsigned char *imageData = malloc(height * width * 4);
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    if (kCGImageAlphaLast == (uint32_t)bitmapInfo || kCGImageAlphaFirst == (uint32_t)bitmapInfo) {
        bitmapInfo = (uint32_t)kCGImageAlphaPremultipliedLast;
    }
    
    CGContextRef context = CGBitmapContextCreate(imageData,
                                                 width,
                                                 height,
                                                 8,
                                                 width * 4,
                                                 colorSpace,
                                                 (uint32_t)kCGImageAlphaPremultipliedLast);
    
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    
    UIImage *result = [UIImage imageWithCGImage:newCGImage scale:[self scale] orientation:UIImageOrientationUp];
    
    CGImageRelease(newCGImage);
    
    CGContextRelease(context);
    
    free(imageData);
    
    return result;
}

GradientObject *gradientColor(CGSize size, CGPoint point, UIImage* newImage, NSMutableArray* gradientColors, NSInteger tolorance, BOOL isTap) {
    GradientObject* gradientObject = gradientAreaFromPoint(point, newImage, gradientColors, tolorance, isTap);
    CGRect gradientArea = gradientObject.area;
    
    CAShapeLayer *caLayer = [CAShapeLayer layer];
    caLayer.bounds = CGRectMake(0, 0, size.width, size.height);;
    caLayer.fillColor = [UIColor redColor].CGColor;
    
    CGPoint newPoint = CGPointMake(point.x - gradientArea.origin.x, point.y - gradientArea.origin.y);
    RadGradientLayer *radLayer = [[RadGradientLayer alloc] initWithCenter:newPoint withRadius:MIN(gradientArea.size.width, gradientArea.size.height)/2 withColors:gradientColors];
    radLayer.frame = gradientArea;
    
    [caLayer addSublayer:radLayer];
    
    UIGraphicsBeginImageContext(size);
    [caLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef imageRef = [image CGImage];
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    unsigned char *imageData = malloc(height * width * 4);
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    if (kCGImageAlphaLast == (uint32_t)bitmapInfo || kCGImageAlphaFirst == (uint32_t)bitmapInfo) {
        bitmapInfo = (uint32_t)kCGImageAlphaPremultipliedLast;
    }
    
    CGContextRef context = CGBitmapContextCreate(imageData,
                                                 width,
                                                 height,
                                                 8,
                                                 width * 4,
                                                 colorSpace,
                                                 (uint32_t)kCGImageAlphaPremultipliedLast);
    
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    gradientObject.imgData = imageData;
    
    CGContextRelease(context);
    
//    free(imageData);
    
    return gradientObject;
}

/*
    I have used pure C function because it is said than C function is faster than Objective - C method in call.
    This two function are called most of time so it require that calling this work in speed.
    I have not verified this performance so I like to here comment on this.
*/
/*
    This function extract color from image and convert it to integer represent.
 
    Converting to integer make comperation easy.
*/
NSUInteger getColorCode (NSUInteger byteIndex, unsigned char *imageData)
{
    NSUInteger red   = imageData[byteIndex];
    NSUInteger green = imageData[byteIndex + 1];
    NSUInteger blue  = imageData[byteIndex + 2];
    NSUInteger alpha = imageData[byteIndex + 3];
    
    return (red << 24) | (green << 16) | (blue << 8) | alpha;
}

/*
    This function compare two color with counting tolerance value.
 
    If color is between tolerance rancge than it return true other wise false.
*/
bool compareColor (NSUInteger color1, NSUInteger color2, NSInteger tolorance)
{
    if(color1 == color2)
        return true;
    
    NSInteger red1   = ((0xff000000 & color1) >> 24);
    NSInteger green1 = ((0x00ff0000 & color1) >> 16);
    NSInteger blue1  = ((0x0000ff00 & color1) >> 8);
    NSInteger alpha1 =  (0x000000ff & color1);
    
    NSInteger red2   = ((0xff000000 & color2) >> 24);
    NSInteger green2 = ((0x00ff0000 & color2) >> 16);
    NSInteger blue2  = ((0x0000ff00 & color2) >> 8);
    NSInteger alpha2 =  (0x000000ff & color2);
    
    NSInteger diffRed   = labs(red2   - red1);
    NSInteger diffGreen = labs(green2 - green1);
    NSInteger diffBlue  = labs(blue2  - blue1);
    NSInteger diffAlpha = labs(alpha2 - alpha1);
    
    if( diffRed   > tolorance ||
        diffGreen > tolorance ||
        diffBlue  > tolorance ||
        diffAlpha > tolorance  )
    {
        return false;
    }
    
    return true;
}

NSUInteger getColorCodeFromUIColor(UIColor *color, CGBitmapInfo orderMask)
{
    //Convert newColor to RGBA value so we can save it to image.
    NSInteger newRed, newGreen, newBlue, newAlpha;
    
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    /*
     If you are not getting why I use CGColorGetNumberOfComponents than read following link:
     http://stackoverflow.com/questions/9238743/is-there-an-issue-with-cgcolorgetcomponents
     */
    
    if(CGColorGetNumberOfComponents(color.CGColor) == 2)
    {
        newRed   = newGreen = newBlue = components[0] * 255;
        newAlpha = components[1] * 255;
    }
    else if (CGColorGetNumberOfComponents(color.CGColor) == 4)
    {
        if (orderMask == kCGBitmapByteOrder32Little)
        {
            newRed   = components[2] * 255;
            newGreen = components[1] * 255;
            newBlue  = components[0] * 255;
            newAlpha = 255;
        }
        else
        {
            newRed   = components[0] * 255;
            newGreen = components[1] * 255;
            newBlue  = components[2] * 255;
            newAlpha = 255;
        }
    }
    else
    {
        newRed   = newGreen = newBlue = 0;
        newAlpha = 255;
    }
    
    NSUInteger ncolor = (newRed << 24) | (newGreen << 16) | (newBlue << 8) | newAlpha;

    return ncolor;
}

@end
