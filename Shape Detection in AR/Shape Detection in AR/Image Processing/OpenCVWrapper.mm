//
//  OpenCVWrapper.m
//  Shape Detection in AR
//
//  Created by Ashis Laha on 27/09/17.
//  Copyright © 2017 Ashis Laha. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.h"
#import <UIKit/UIKit.h>

@implementation OpenCVWrapper

-(void) shapeIdentify :(UIImage *)image {
    self.shapesResults = [[NSMutableArray alloc] init];
    cv::Mat cameraFeed = [self shapeDetection:image];
    UIImage * result = [OpenCVWrapper ImageFromCVMat:cameraFeed];
    
    // save it into photo-galary
    UIImage * rotatedImage = [[UIImage alloc] initWithCGImage:[result CGImage] scale:1.0 orientation:UIImageOrientationRight];
    UIImageWriteToSavedPhotosAlbum(rotatedImage, self, nil, nil);
}

-(cv::Mat) shapeDetection :(UIImage *)image { // image is the result of Edge detection, it's in gray scale.
    
    /*
     // Convert to grayscale
     cv::Mat gray;
     cv::cvtColor(src, gray, CV_BGR2GRAY);
     // Convert to binary image using Canny
     cv::Mat bw;
     cv::Canny(gray, bw, 0, 50, 5);
     imageView.image = [UIImage fromCVMat:gray];
     */
    
    cv::Mat cameraFeed =  [OpenCVWrapper CVMatFromImage:image];
    std::vector< std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    
    // before applying contour finding, apply Morphology Transformations
    
    // Closing the image (Method-1)
    cv:: Mat bw2;
    cv:: Mat erodedBW2;
    cv:: Mat se = getStructuringElement(0, cv::Size(5,5));
    cv::dilate(cameraFeed, bw2, se);
    cv::erode(bw2, erodedBW2, se);
    
    // Closing the image (Method-2)
    cv::morphologyEx(cameraFeed, erodedBW2, cv::MORPH_CLOSE, se);
    
    // Find contour
    findContours( cameraFeed, contours, hierarchy, CV_RETR_EXTERNAL,  CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    
    bool objectFound = false;
    if (hierarchy.size() > 0) {
        
        for (int index = 0; index >= 0; index = hierarchy[index][0]) {
            cv::Moments moment = moments((cv::Mat)contours[index]);
            double area = moment.m00;
            objectFound = (area > 100)? true : false;
        }
        //let user know you found an object
        if(objectFound ==true){
            for(int i=0; i < contours.size() ; i++) {
                cv::drawContours(cameraFeed,contours,i,cvScalar(80,255,255),CV_FILLED);
            }
        }
        
        // let's infer the shape from contours , calculate approx length of contours
        std::vector<cv::Point> approx;
        for(int i = 0; i < contours.size(); i++) {
            cv::approxPolyDP(cv::Mat(contours[i]), approx, cv::arcLength(cv::Mat(contours[i]), true)*0.02, true);
            
            // Skip small
            if (!(std::fabs(cv::contourArea(contours[i])) < 100)) { // && cv::isContourConvex(approx)
                
                printf("\n\n\n .......Area : %.0f\t", std::fabs(cv::contourArea(contours[i])));
                
                cv::Point2f center;
                float radius = 0.0;
                NSString * shape = @"";
                
                switch (approx.size()) {
                    case 3: // Triangle
                        printf("Triangle");
                        shape = @"triangle";
                        break;
                    case 4: // Rectangle
                        printf("Rectangle");
                        shape = @"rectangle";
                        break;
                    case 5: // Pentagon
                        printf("Pentagon");
                        shape = @"pentagon";
                        break;
                    default: // circle
                        printf("circle \t");
                        shape = @"circle";
                        cv::minEnclosingCircle(cv::Mat(contours[i]), center, radius);
                        printf("Approx size : %ld , radius = %.1f",approx.size(),radius);
                }
                
                NSMutableArray * positions = [[NSMutableArray alloc] init];
                
                if ([shape isEqual:@"circle"]) {
                    NSDictionary * dict = @{    @"radius":  [NSNumber numberWithFloat:radius],
                                                @"center.x":[NSNumber numberWithFloat:center.x],
                                                @"center.y":[NSNumber numberWithFloat:center.y]
                                                };
                    [positions addObject:dict];
                }
                for (int j = 0; j < approx.size(); j++) {
                    NSDictionary * dict = @{ @"x":[NSNumber numberWithInt:approx[j].x], @"y":[NSNumber numberWithInt:approx[j].y]};
                    [positions addObject:dict];
                }
                [self.shapesResults addObject:@{shape:positions}]; // update the dictionary
            }
        }
    }
    return cameraFeed;
}


/*
     int cosine = getAngleABC(approx[j], approx[(j+2)%approx.size()], approx[(j+1)%approx.size()]);
     printf("\nCosine : %d ",cosine);
     printf("\tPosition :%d , %d ", approx[j].x, approx[j].y);
     cv::circle(cameraFeed, approx[j], 10, cv::Scalar(0, 0, 255), cv::FILLED);
 */

//MARK:- Get Angle from 3 points
int getAngleABC( cv::Point a, cv::Point b, cv::Point c ) {
    double abx = b.x - a.x;
    double aby = b.y - a.y;
    double cbx = b.x - c.x;
    double cby = b.y - c.y;
    
    float dot = (abx * cbx + aby * cby); // dot product
    float cross = (abx * cby - aby * cbx); // cross product
    float alpha = atan2(cross, dot);
    
    return (int) floor(alpha * 180.0 / CV_PI + 0.5);
}

//MARK:- Image to CV matrix
+(cv::Mat)CVMatFromImage:(UIImage *)image {
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    size_t numberOfComponents = CGColorSpaceGetNumberOfComponents(colorSpace);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
    
    // check whether the UIImage is greyscale already
    if (numberOfComponents == 1){
        cvMat = cv::Mat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
        bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    }
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    bitmapInfo);                // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

//MARK:- CV matrix to Image
+(UIImage *)ImageFromCVMat:(cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    CGBitmapInfo bitmapInfo;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
        bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGBitmapByteOrder32Little | (cvMat.elemSize() == 3? kCGImageAlphaNone : kCGImageAlphaNoneSkipFirst);
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(
                                        cvMat.cols,                 //width
                                        cvMat.rows,                 //height
                                        8,                          //bits per component
                                        8 * cvMat.elemSize(),       //bits per pixel
                                        cvMat.step[0],              //bytesPerRow
                                        colorSpace,                 //colorspace
                                        bitmapInfo,                 //bitmap info
                                        provider,                   //CGDataProviderRef
                                        NULL,                       //decode
                                        false,                      //should interpolate
                                        kCGRenderingIntentDefault   //intent
                                        );
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


@end
