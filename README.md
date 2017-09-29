# Shape-Detection-in-AR

Detect the shape of drawing objects (classes - triangle, rectangle, circle) and draw in Augmented Reality.
 
Basic Steps : (just concept : work in progress)

(1) Take the image from ARFrame 

(2) Do Edge Detection

(3) Do Regression on pixel informations for better result.

(4) convert the pixel positions into real world positions.

(5) draw it in ARView with real-world coordinates and shape specifications (like arm length value for triangle, rectangle etc.)



-----------------------------------------------------------
Create an Edge Detection CoreML model 
-----------------------------------------------------------

Original Caffe Model : http://vcl.ucsd.edu/hed/hed_pretrained_bsds.caffemodel

The Github project is : https://github.com/s9xie/hed

Download Edge_detection CoreML model(58MB) from : https://drive.google.com/drive/folders/0B0QC-w3ZqaT1ZEtpSG5HOE5VWEk  which contains 6 different type of Outputs. 

I am using the Side-out of original model (dsn3 output) only to reduce the space complexity. 

(virtualenv2.7) C02QP68UG8WP:CoreML creation ashis.laha$ python mlmodel_converter.py 

================= Starting Conversion from Caffe to CoreML ======================

Layer 0: Type: 'Input', Name: 'input'. Output(s): 'data'.

Ignoring batch size and retaining only the trailing 3 dimensions for conversion. 

Layer 1: Type: 'Convolution', Name: 'conv1_1'. Input(s): 'data'. Output(s): 'conv1_1'.

Layer 2: Type: 'ReLU', Name: 'relu1_1'. Input(s): 'conv1_1'. Output(s): 'conv1_1'.

Layer 3: Type: 'Convolution', Name: 'conv1_2'. Input(s): 'conv1_1'. Output(s): 'conv1_2'.

Layer 4: Type: 'ReLU', Name: 'relu1_2'. Input(s): 'conv1_2'. Output(s): 'conv1_2'.

Layer 5: Type: 'Pooling', Name: 'pool1'. Input(s): 'conv1_2'. Output(s): 'pool1'.

Layer 6: Type: 'Convolution', Name: 'conv2_1'. Input(s): 'pool1'. Output(s): 'conv2_1'.

Layer 7: Type: 'ReLU', Name: 'relu2_1'. Input(s): 'conv2_1'. Output(s): 'conv2_1'.

Layer 8: Type: 'Convolution', Name: 'conv2_2'. Input(s): 'conv2_1'. Output(s): 'conv2_2'.

Layer 9: Type: 'ReLU', Name: 'relu2_2'. Input(s): 'conv2_2'. Output(s): 'conv2_2'.

Layer 10: Type: 'Pooling', Name: 'pool2'. Input(s): 'conv2_2'. Output(s): 'pool2'.

Layer 11: Type: 'Convolution', Name: 'conv3_1'. Input(s): 'pool2'. Output(s): 'conv3_1'.

Layer 12: Type: 'ReLU', Name: 'relu3_1'. Input(s): 'conv3_1'. Output(s): 'conv3_1'.

Layer 13: Type: 'Convolution', Name: 'conv3_2'. Input(s): 'conv3_1'. Output(s): 'conv3_2'.

Layer 14: Type: 'ReLU', Name: 'relu3_2'. Input(s): 'conv3_2'. Output(s): 'conv3_2'.

Layer 15: Type: 'Convolution', Name: 'conv3_3'. Input(s): 'conv3_2'. Output(s): 'conv3_3'.

Layer 16: Type: 'ReLU', Name: 'relu3_3'. Input(s): 'conv3_3'. Output(s): 'conv3_3'.

Layer 17: Type: 'Convolution', Name: 'score-dsn3'. Input(s): 'conv3_3'. Output(s): 'score-dsn3'.

Layer 18: Type: 'Deconvolution', Name: 'upsample_4'. Input(s): 'score-dsn3'. Output(s): 'score-dsn3-up'.

Layer 19: Type: 'Crop', Name: 'crop'. Input(s): 'score-dsn3-up', 'data'. Output(s): 'upscore-dsn3'.


================= Summary of the conversion: ===================================
Detected input(s) and shape(s) (ignoring batch size):

'data' : 3, 500, 500

Network Input name(s): 'data'.

Network Output name(s): 'upscore-dsn3'.

input {
  name: "data"
  shortDescription: "Input image to be edge-detected. Must be exactly 500x500 pixels."
  type {
    imageType {
      width: 500
      height: 500
      colorSpace: BGR
    }
  }
}

output {
  name: "upscore-dsn3"
  type {
    multiArrayType {
      dataType: DOUBLE
    }
  }
}

metadata {
  shortDescription: "Holistically-Nested Edge Detection. https://github.com/s9xie/hed "
  author: "Original paper: Xie, Saining and Tu, Zhuowen. Caffe implementation: Yangqing Jia. CoreML port: Ashis Laha"
  license: "Unknown"
}

--------------------------------------------------------------------------
### Use the CoreML Model for detecting Edge of ARFrame captured Camera Image

![img_0086](https://user-images.githubusercontent.com/10649284/30848427-c1cdc94a-a2bc-11e7-827f-767a1ced4cea.PNG) 

![img_0085](https://user-images.githubusercontent.com/10649284/30851681-f14290ac-a2c6-11e7-9f4b-1af02cde4908.JPG)


 NEXT TASK : Convert the coordinates from Image view into real-coordinates.
 

 ### Open CV framework added : 

# step 1 : create pod file with : pod 'OpenCV'

# step 2 : Create a bridging header 
	Create an objective-c file from “Cocoa-touch class”
	name it - OpenCVWrapper 
	Xcode is smart and proposes to create a bridging header. Click on Create Bridging Header.

# step 3 : Configure the bridging header ($project_name-Bridging-Header.h)
	#import "OpenCVWrapper.h" in the bridging header 

# step 4 : Change to Objective-c++ 
	change from OpenCVWrapper.m to OpenCVWrapper.mm

# step 5 : Importing opencv
	#import <opencv2/opencv.hpp>
	#import "OpenCVWrapper.h"
	into OpenCVWrapper.mm file. 
	
NOTED : You will get ERROR : enum { NO, FEATHER, MULTI_BAND }; because of “NO” enum name. #import <opencv2/opencv.hpp> above all other imports will resolve the issue.

# Step 6 : Write a test code 
	
	In OpenCVWrapper.h —> -(void) isOpenCVWorking;
	In OpenCVWrapper.mm —>  @Implementation 

		-(void) isOpenCVWorking {
    			NSLog(@"It's working");
		}

	@end

AND call this from Swift class like :
	
	let openCVWrapper = OpenCVWrapper()
    	openCVWrapper.isOpenCVWorking()

It will generate Output :  "It's working”


# Finding Shape :

## step1 : convert image into CV Matrix 

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


## step 2 : apply Morphology Transformations

## step 3 : Find Contour from Image 

## step 4 : Calculate Approximate points from Contour 

## step 5 : Based on Approximation size, define the shape 

## step 6 : Retrieve the Positions (co-ordinates), Radius, Center of Circle & other shapes 

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
                } else {
                    for (int j = 0; j < approx.size(); j++) {
                        NSDictionary * dict = @{ @"x":[NSNumber numberWithInt:approx[j].x], @"y":[NSNumber numberWithInt:approx[j].y]};
                        [positions addObject:dict];
                    }
                }
                
                [self.shapesResults addObject:@{shape:positions}]; // update the dictionary
            }
        }
    }
    return cameraFeed;
}

## step 7 : Convert cv::Matrix into UIImage again 

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


## Step 8 : Save the result for Visualization 

![img_0196](https://user-images.githubusercontent.com/10649284/31007762-3faa72aa-a51f-11e7-918e-191d55bde391.JPG)
![img_0197](https://user-images.githubusercontent.com/10649284/31007763-3fcaea76-a51f-11e7-9c5f-a1ad51ee0467.JPG)

    cv::Mat cameraFeed = [self shapeDetection:image];
    UIImage * result = [OpenCVWrapper ImageFromCVMat:cameraFeed];
    
    // save it into photo-galary
    UIImage * rotatedImage = [[UIImage alloc] initWithCGImage:[result CGImage] scale:1.0 orientation:UIImageOrientationRight];
    UIImageWriteToSavedPhotosAlbum(rotatedImage, self, nil, nil);
    

