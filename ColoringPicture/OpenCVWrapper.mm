//
//  OpenCVWrapper.m
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/7/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"

using namespace cv;
using namespace std;


@implementation OpenCVWrapper : NSObject
-(NSString *) openCVVersionString {
    return [NSString stringWithFormat:@"OpenCV version %s", CV_VERSION];
}

+ (UIImage *)floodFill:(UIImage*)inputImage point:(CGPoint)point replacementColor:(UIColor*)replacementColor {
    cv::Mat cvImage;
    UIImageToMat(inputImage, cvImage);
    
    if (cvImage.channels() == 4) {
        cv::cvtColor(cvImage, cvImage, CV_RGBA2RGB);
    }
    switch (cvImage.channels()) {
        case 4:
            cv::cvtColor(cvImage, cvImage, CV_RGBA2RGB);
            break;
        case 1:
            cv::cvtColor(cvImage, cvImage, CV_GRAY2RGB);
            break;
        default:
            break;
    }
    assert(cvImage.channels() == 3);
    CGFloat r = 0;
    CGFloat g = 0;
    CGFloat b = 0;
    [replacementColor getRed:&r green:&g blue:&b alpha:nil];
    
//    assert(r != 0);
    
    Mat mask = Mat::zeros(cvImage.rows + 2, cvImage.cols + 2, CV_8UC1);
    floodFill(cvImage, cv::Point(point.x, point.y), Scalar(UInt8(r*255), UInt8(g*255),UInt8(b*255)), 0, Scalar(0, 0, 0), Scalar(0, 0, 0));
    
    return MatToUIImage(cvImage);
}

+ (UIImage *) scanImage:(UIImage *)image {
    Mat imageMat;
    UIImageToMat(image, imageMat);
    if (imageMat.channels() == 4) {
        cv::cvtColor(imageMat, imageMat, CV_RGBA2RGB);
    }
    switch (imageMat.channels()) {
        case 4:
            cv::cvtColor(imageMat, imageMat, CV_RGBA2RGB);
            break;
        case 1:
            cv::cvtColor(imageMat, imageMat, CV_GRAY2RGB);
            break;
        default:
            break;
    }
    
    Mat gray = [self gray:imageMat];
    Mat threshold = [self threshold:gray];
    Mat countour = [self countours:threshold];
    
//    Mat mask = [self mask:imageMat :countour];
    
    if (countour.channels() == 4) {
        cv::cvtColor(countour, countour, CV_RGBA2RGB);
    }
    switch (countour.channels()) {
        case 4:
            cv::cvtColor(countour, countour, CV_RGBA2RGB);
            break;
        case 1:
            cv::cvtColor(countour, countour, CV_GRAY2RGB);
            break;
        default:
            break;
    }
    
    floodFill(countour, cv::Point(0, 0), Scalar(UInt8(255), UInt8(255),UInt8(255)), 0, Scalar(0, 0, 0), Scalar(0, 0, 0));
    
    return MatToUIImage(countour);
}

+ (Mat) gray:(Mat)image {
    Mat grayMat;
    cvtColor(image, grayMat, CV_RGB2GRAY);
    return grayMat;
}

+ (Mat) threshold:(Mat)image {
    Mat thresholdMat;
    // 53, 8
    // 75, 25
    // 999, 20
    adaptiveThreshold(image, thresholdMat, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, 75, 20);
    bitwise_not(thresholdMat, thresholdMat);
    return thresholdMat;
}

+ (Mat) countours:(Mat)image {
    Mat output = image.clone();
    vector<vector<cv::Point>> mContours;
    Mat hierarchy;
    
    vector< Vec4i > aHierarchy;
    
    findContours(output, mContours, hierarchy, RETR_LIST, CHAIN_APPROX_SIMPLE);
    
//    findContours( output, mContours, aHierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE );
    
    Mat mask = Mat::zeros(output.rows, output.cols, CV_8UC1);
    Scalar scalar = Scalar(255, 255, 0);
    drawContours(mask, mContours, -1, scalar, -1);
    
//    for( int i = 0; i< mContours.size(); i=aHierarchy[i][0] ) {
//        Point2f points[4];
//        Point2f center;
//        float radius;
//        cv::Rect rect;
//        RotatedRect rotate_rect;
//        
//        //compute the bounding rect, rotated bounding rect, minum enclosing circle.
//        rect = boundingRect(mContours[i]);
//        rotate_rect = minAreaRect(mContours[i]);
//        minEnclosingCircle(mContours[i], center, radius);
//        
//        rotate_rect.points(points);
//        
//        vector< vector< cv::Point> > polylines;
//        polylines.resize(1);
//        for(int j = 0; j < 4; ++j)
//            polylines[0].push_back(points[j]);
    
        //draw them on the bounding image.
//        if(aHierarchy[i][2] >= 0)
//            cv::rectangle(output, rect, Scalar(0,0,255), 2);
//    }
    
    return output;
}

+ (Mat) mask:(Mat)image: (Mat)countourImage {
    Scalar scalar = Scalar(255, 255, 255);
    Mat foreground(image.rows, image.cols, CV_8UC3, scalar);
    image.copyTo(foreground, countourImage);
    return foreground;
}

@end
