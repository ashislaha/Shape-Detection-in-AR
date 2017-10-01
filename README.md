# Shape-Detection-in-AR

Detect the shape of drawing objects (classes - line, triangle, rectangle, pentagon, Hexagon, circle) and draw in Augmented Reality.

# Input Image : 
![img_2662](https://user-images.githubusercontent.com/10649284/31043178-4a9bf024-a5d5-11e7-849d-e88e00c9f7a5.JPG)

# Edge Detected Image : 
![img_0225](https://user-images.githubusercontent.com/10649284/31043244-59f29ebe-a5d6-11e7-87a6-6ca9209d961f.JPG)

# Find Contour & Fill it for visualization :
![img_0226](https://user-images.githubusercontent.com/10649284/31043257-8855e70c-a5d6-11e7-8a16-c2a4afee93a9.JPG)

# Create Scene graph :
![img_4427d21af932-1](https://user-images.githubusercontent.com/10649284/31043182-53017ad6-a5d5-11e7-9067-3100c58808c2.jpeg)

# Example : 
![2](https://user-images.githubusercontent.com/10649284/31055884-634d54ce-a6e7-11e7-91b8-59fd820321f3.JPG)
![3](https://user-images.githubusercontent.com/10649284/31055872-51e50f88-a6e7-11e7-9de1-c8054ff37e53.PNG)
 
## Basic Steps : 

## step 1 : Create a mlmodel for Edge Detection (Generic type) 

## step 2 : Take the image from ARFrame & idenfify edges using edge_detection.mlmodel

## step 3 : Find out the Contours in the edge_detected image & calculate the approximation points using openCV.

## step 4 : Figure the Shapes with it's image co-ordinates from Approximation points 

## step 5 : Map the image co-ordinates of shapes into AR-world co-ordinates

## step 6 : Render Scene Graph 

# In the project, pod is not installed, So please do, "$pod install" before running the project.

-----------------------------------------------------------
# Create an Edge Detection CoreML model 
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

![img_2662](https://user-images.githubusercontent.com/10649284/31043178-4a9bf024-a5d5-11e7-849d-e88e00c9f7a5.JPG)

![img_0225](https://user-images.githubusercontent.com/10649284/31043244-59f29ebe-a5d6-11e7-87a6-6ca9209d961f.JPG)

# Open CV framework added : 

## step 1 : create pod file with : pod 'OpenCV'

## step 2 : Create a bridging header 
	Create an objective-c file from “Cocoa-touch class”
	name it - OpenCVWrapper 
	Xcode is smart and proposes to create a bridging header. Click on Create Bridging Header.

## step 3 : Configure the bridging header ($project_name-Bridging-Header.h)
	#import "OpenCVWrapper.h" in the bridging header 

## step 4 : Change to Objective-c++ 
	change from OpenCVWrapper.m to OpenCVWrapper.mm

## step 5 : Importing opencv
	#import <opencv2/opencv.hpp>
	#import "OpenCVWrapper.h"
	into OpenCVWrapper.mm file. 
	
### NOTED : You will get ERROR : enum { NO, FEATHER, MULTI_BAND }; because of “NO” enum name. #import <opencv2/opencv.hpp> above all other imports will resolve the issue.

## Step 6 : Write a test code 

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

![img_0197](https://user-images.githubusercontent.com/10649284/31007763-3fcaea76-a51f-11e7-9c5f-a1ad51ee0467.JPG)
![img_0196](https://user-images.githubusercontent.com/10649284/31007762-3faa72aa-a51f-11e7-918e-191d55bde391.JPG)

    cv::Mat cameraFeed = [self shapeDetection:image];
    UIImage * result = [OpenCVWrapper ImageFromCVMat:cameraFeed];
    
    // save it into photo-galary
    UIImage * rotatedImage = [[UIImage alloc] initWithCGImage:[result CGImage] scale:1.0 orientation:UIImageOrientationRight];
    UIImageWriteToSavedPhotosAlbum(rotatedImage, self, nil, nil);
    

# Co-ordinate Mapping & SCNNode Create :

![img_4427d21af932-1](https://user-images.githubusercontent.com/10649284/31042288-ff9c0d1a-a5c1-11e7-80f5-f7e638ddaafa.jpeg)

## step 1 : Create A Straight Line : 

    class func createline(from : SCNVector3 , to : SCNVector3) -> SCNNode { // Z is static
        // calculate Angle
        let dx = from.x - to.x
        let dy = (from.y - to.y)
        var theta = atan(Double(dy/dx))
        if theta == .nan {
            theta = 3.14159265358979 / 2 // 90 Degree
        }
        
        //Create Node
        let width = CGFloat(sqrt( dx*dx + dy*dy ))
        let height : CGFloat = 0.01
        let length : CGFloat = 0.08
        let chamferRadius : CGFloat = 0.01
        let route = SCNBox(width: width, height: height, length: length, chamferRadius: chamferRadius)
        route.firstMaterial?.diffuse.contents = UIColor.getRandomColor()
        let midPosition = SCNVector3Make((from.x+to.x)/2, (from.y+to.y)/2,0)
        let node = SCNNode(geometry: route)
        node.position = midPosition
        node.rotation = SCNVector4Make(0, 0, 1, Float(theta)) // along Z axis
        return node
    }

## step 2 : Create A Circle :

    class func createCircle(center : SCNVector3, radius : CGFloat) -> SCNNode {
        var geometry : SCNGeometry!
        geometry = SCNCylinder(radius: radius, height: 0.01)
        geometry.firstMaterial?.diffuse.contents = UIColor.getRandomColor()
        geometry.firstMaterial?.specular.contents = UIColor.getRandomColor()
        let node = SCNNode(geometry: geometry)
        node.position = center
        node.rotation = SCNVector4Make(1, 0, 0, Float(Double.pi/2)) // along X axis
        return node
    }

## Step 3 : Create a Boundary : 

	class func boundaryNode() -> SCNNode {
        	let node = SCNNode()
        	let points : [(Float,Float)] = [(0.0,0.0),(0.5,0.0), (0.5,0.5), (0.0,0.5)]
        
        	for i in 0..<4 {
          	  	let x1 = points[i].0
            		let y1 = points[i].1
            		let x2 = points[(i+1)%points.count].0
            		let y2 = points[(i+1)%points.count].1
            
            		let from = SCNVector3Make(x1,y1,0)
            		let to = SCNVector3Make(x2,y2,0)
            		node.addChildNode(SceneNodeCreator.createline(from: from, to: to))
        	}
      	   return node
    	}

## Step 4 : Map from Image Co-ordinates into AR-Cordinates :

The Image Co-ordinates looks like : 

	.......Area : 9656	Triangle
	 .......Area : 17871	Rectangle
	 .......Area : 9368	circle 	Approx size : 8 , radius = 76.6
 	.......Area : 3100	Rectangle

	Shape : triangle Values : (
        	{ x = 198; y = 255; },
        	{ x = 119; y = 373; },
        	{ x = 208; y = 485; })


	Shape : rectangle Values : (
        { x = 303; y = 128; },
        { x = 231; y = 162; },
        { x = 247; y = 367; },
        { x = 330; y = 349; })


	Shape : circle Values : (
        { "center.x" = 151; "center.y" = "106.5523"; radius = "76.61115"; },
        { x = 148; y = 30; },
        { x = 115;  y = 77; },
        { x = 112; y = 118; },
        { x = 127; y = 169; },
        { x = 156; y = 183; },
        { x = 183; y = 152; },
        { x = 191; y = 95;  },
        { x = 186; y = 60;  })


	Shape : rectangle Values : (
        { x = 499; y = 0; },
        { x = 2; y = 0; },
        { x = 0; y = 499; },
        { x = 5; y = 8; })

The convertion function :

	class func getSceneNode(shapreResults : [[String : Any]] ) -> SCNScene { // input is array of dictionary
        let scene = SCNScene()
        let convertionRatio : Float = 1000.0
        let imageWidth : Int = 499
        
        for eachShape in shapreResults {
            if let dictionary = eachShape.first {
                
                let values = dictionary.value as! [[String : Any]]
                switch dictionary.key {
                case "circle" :
                    
                    // check for values if approx.points is more than 7 then circle.
                    if values.count > 7 { // draw circle
                        if let circleParams = values.first as? [String : Float] {
                            let x = circleParams["center.x"] ?? 0.0
                            let y = circleParams["center.y"] ?? 0.0
                            let radius = circleParams["radius"] ?? 0.0
                            let center = SCNVector3Make(Float(Float(imageWidth)-y)/convertionRatio, Float(Float(imageWidth)-x)/convertionRatio, 0)
                            scene.rootNode.addChildNode(SceneNodeCreator.createCircle(center: center, radius: CGFloat(radius/convertionRatio*2.0)))
                        }
                    } else { // draw lines between points
                        for i in 1..<values.count { // connect all points usning straight lines (basic)
                            let x1 = values[i]["x"] as! Int
                            let y1 = values[i]["y"] as! Int
                            let next = (i == values.count-1) ?  (i+2) : (i+1)
                            let x2 = values[next%values.count]["x"] as! Int
                            let y2 = values[next%values.count]["y"] as! Int
                            
                            let from = SCNVector3Make(Float(imageWidth-y1)/convertionRatio, Float(imageWidth-x1)/convertionRatio, 0)
                            let to = SCNVector3Make(Float(imageWidth-y2)/convertionRatio, Float(imageWidth-x2)/convertionRatio, 0)
                            scene.rootNode.addChildNode(SceneNodeCreator.createline(from: from, to: to))
                        }
                    }
                case "triangle", "rectangle","pentagon" :
                    for i in 0..<values.count { // connect all points usning straight lines (basic)
                        let x1 = values[i]["x"] as! Int
                        let y1 = values[i]["y"] as! Int
                        let x2 = values[(i+1)%values.count]["x"] as! Int
                        let y2 = values[(i+1)%values.count]["y"] as! Int
                        
                        // skip the boundary Rectangle here
                        if x1>10 && x1<490 {
                        let from = SCNVector3Make(Float(imageWidth-y1)/convertionRatio, Float(imageWidth-x1)/convertionRatio, 0)
                        let to = SCNVector3Make(Float(imageWidth-y2)/convertionRatio, Float(imageWidth-x2)/convertionRatio, 0)
                        scene.rootNode.addChildNode(SceneNodeCreator.createline(from: from, to: to))
                        }
                    }
                default :
                    print("This is default for Drawing node ")
                }
            }
        }
        // add boundary
        scene.rootNode.addChildNode(SceneNodeCreator.boundaryNode())
        return scene
    }
    }

![2](https://user-images.githubusercontent.com/10649284/31055884-634d54ce-a6e7-11e7-91b8-59fd820321f3.JPG)
![3](https://user-images.githubusercontent.com/10649284/31055872-51e50f88-a6e7-11e7-9de1-c8054ff37e53.PNG)
