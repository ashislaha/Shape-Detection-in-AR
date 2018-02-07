//
//  Classification.swift
//  Shape Detection in AR
//
//  Created by Ashis Laha on 25/09/17.
//  Copyright © 2017 Ashis Laha. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import SceneKit


// Initialize the model once
let mlModel = edge_detection().fritz()


class EdgeDetectionUtil {
    
    //MARK:- Classification
    class func classify(image : CVPixelBuffer , row : Int = 500, column : Int = 500) -> UIImage? {

        // retrieve features
        let featureProvider: MLFeatureProvider = try! mlModel.prediction(data: image)
        
        // Retrieve results ( specified in model evalution parameters )
        guard let outputFeatures = featureProvider.featureValue(for: "upscore-dsn3")?.multiArrayValue  else { fatalError("Couldn't retrieve features") }
        
        // Calculate total buffer size by multiplying shape tensor's dimensions
        let bufferSize = outputFeatures.shape.lazy.map { $0.intValue }.reduce(1, { $0 * $1 })
        
        // Get data pointer to the buffer
        let dataPointer = UnsafeMutableBufferPointer(start: outputFeatures.dataPointer.assumingMemoryBound(to: Double.self),count: bufferSize)
        
        // Prepare buffer for single-channel image result
        var imgData = [UInt8](repeating: 0, count: bufferSize)
        
        // Normalize result features by applying sigmoid to every pixel and convert to UInt8
        let inputW = column
        let inputH = row
        for i in 0..<inputW {
            for j in 0..<inputH {
                let idx = i * inputW + j
                let value = dataPointer[idx]
                
                let sigmoid = { (input: Double) -> Double in
                    return 1 / (1 + exp(-input))
                }
                
                let result = sigmoid(value)
                imgData[idx] = UInt8(result * 255)
            }
        }
        
        // Create a gray-scale image out of our freshly-created buffer
        let cfbuffer = CFDataCreate(nil, &imgData, bufferSize)!
        let dataProvider = CGDataProvider(data: cfbuffer)!
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let cgImage = CGImage(width: inputW, height: inputH, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: inputW, space: colorSpace, bitmapInfo: [], provider: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        let resultImage = UIImage(cgImage: cgImage!)
        return resultImage
    }
    
    //MARK:- Open CV helping methods
    class func getShapes(edgeDetectedImage : UIImage) -> SCNScene {
        let openCVWrapper = OpenCVWrapper()
        openCVWrapper.shapeIdentify(edgeDetectedImage)
        
        // get the updates of shapes and positions in shapesResults dictionary
        if let shapesArr = openCVWrapper.shapesResults as? [[String : Any]] {
            // printing
            for each in shapesArr {
                if let dictionary = each.first {
                     print("\n\nShape : \(dictionary.key) Values : \(dictionary.value)")
                }
            }
            // retrieve shapes
            return SceneNodeCreator.getSceneNode(shapreResults: shapesArr)
        }
        return SCNScene()
    }
}

//MARK:- Operations on UIImage
public extension UIImage {
    
    //pixel buffer convert
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        guard let context = CGContext(data: pixelData,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            else {
                return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    //resize image
    public func resized(width: Int, height: Int) -> UIImage {
        guard width > 0 && height > 0 else {
            fatalError("Dimensions must be over 0.")
        }
        
        let newSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}


