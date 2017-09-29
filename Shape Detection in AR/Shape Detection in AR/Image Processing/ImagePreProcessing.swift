//
//  ImagePreProcessing.swift
//  Handwritten Recognition
//
//  Created by Ashis Laha on 07/03/17.
//  Copyright © 2017 Ashis Laha. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

/*
 Image Preprocessing :
 
 1. Normalize Aspect ratio with respect to N*M dimension
 2. Edge detection of the image
 3. Reduce the noise from image
 */


struct ImageProcessingConstants {
    static let maxDimension : CGFloat  = 120
    static let optimalDimensionX : Int = 50
    static let optimalDimensionY : Int = 50
    // For Edge Detection
    static let intensityThreshold : Double = 80
}

struct PixelData {
    var r : UInt8 = 0
    var g : UInt8 = 0
    var b : UInt8 = 0
    var a : UInt8 = 0
}

// Crop the picture 10 %
private extension UIImage {
    
    func crop( rect: CGRect) -> UIImage {
        var rect = rect
        rect.origin.x*=self.scale
        rect.origin.y*=self.scale
        rect.size.width*=self.scale
        rect.size.height*=self.scale
        
        let imageRef = self.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
}


class ImagePreProcessing {
    
    static let shared = ImagePreProcessing()
    private init() { }
    
    var optimalPixelMatrix = [[Double]]()
    var pixelData = [[PixelData]]()
    
    private func mask8( x : UInt32) -> UInt32 { return x & 0xFF }
    private func R(x : UInt32) -> UInt32 { return mask8(x: x) }
    private func G(x : UInt32) -> UInt32 { return mask8(x: x >> 8 )}
    private func B(x : UInt32) -> UInt32 { return mask8(x: x >> 16)}
    private func alphaComponent(x : UInt32) -> UInt32 { return mask8(x: x>>24)}
    private func RGBAlphaMake( r : UInt32, g : UInt32, b : UInt32, alpha : UInt32 ) -> UInt32 { return mask8(x: r) | mask8(x: g<<8) | mask8(x: b<<16) | mask8(x: alpha<<24)}
    
    //MARK:- Process The Image
    
    public func preProcessImage(image : UIImage) ->  [[Double]] {
        
        var grayScalePixels : [[Double]] = []
        // Resize the image
        let smallSizeImage = resizeImage(image: image, targetSize: CGSize(width: 2 * 50.0, height: 2 * 50.0))
        
        // Make it Gray
        if let grayImage = grayScaleImage(image : smallSizeImage) {
            // Compute Pixel Information
            grayScalePixels = normalizedIntensityMatrix(image: grayImage)
        }
        return  grayScalePixels
    }
    
    // MARK:- Crop the image 10% around
    
    private func cropImage(image : UIImage ) -> UIImage {
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let cropWidth = imageWidth * 0.8
        let cropHeight = imageWidth * 0.8
        
        let origin = CGPoint(x: (imageWidth - cropWidth)/2, y: (imageHeight-cropHeight)/2)
        let size = CGSize(width: cropWidth, height: cropHeight)
        
        return image.crop(rect: CGRect(origin: origin, size: size))
    }
    
    
    //MARK:- Resize Image
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio < heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        guard let scaledImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    //MARK:- GrayScale Image
    
    private func grayScaleImage(image : UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, true, 1.0)
        let rect = CGRect(origin: CGPoint.zero, size: image.size)
        image.draw(in: rect, blendMode: .luminosity, alpha: 1.0)
        let returnImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return returnImage
    }
    
    //MARK:- Normalized Image
    
    private func normalizedIntensityMatrix(image: UIImage) -> [[Double]] {
        let logMatrix = logPixelOfImage(image: image)
        //let suppressedMatrix = suppression(inputMatrix: logMatrix, intensityThreshold: ImageProcessingConstants.intensityThreshold)
        let edgeDetection = cannyEdgeDetectionOperator(inputMatrix: logMatrix)
        printMatrix(inputMatrix: edgeDetection)
        return edgeDetection
    }
    
    //MARK:- Log Pixel image
    
    private func logPixelOfImage(image : UIImage) -> [[Double]] {
        guard let coreImageRef = image.cgImage else { return [] }
        let height = coreImageRef.height
        let width = coreImageRef.width
        
        let bytesPerPixel = coreImageRef.bitsPerPixel / 8 // 1 byte = 8 bits
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = coreImageRef.bitsPerComponent
        
        let pixels  = UnsafeMutablePointer<UInt32>.allocate(capacity: height * width)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixels, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace,bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(coreImageRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var pixelMatrix = [[Double]]()
        var tempPixels = pixels
        
        for i in 0..<height {
            var rowData = [Double]()
            var rowPixel = [PixelData]()
            
            for j in 0..<width {
                if i < ImageProcessingConstants.optimalDimensionX && j < ImageProcessingConstants.optimalDimensionY {
                    let color = tempPixels[j + i * width]
                    let doubleValue = Double(R(x: color)+G(x: color)+B(x: color))/3.0
                    rowData.append(doubleValue)
                    
                    // pixel data collection
                    rowPixel.append(PixelData(r: UInt8(R(x: color)), g: UInt8(G(x: color)), b: UInt8(B(x: color)), a: UInt8(alphaComponent(x : color))))
                }
                // increment the pointer
                tempPixels = tempPixels + 1
            }
            
            if rowData.count > 0  {  pixelMatrix.append(rowData) }
            if rowPixel.count > 0 {  pixelData.append(rowPixel) }
        }
        free(pixels)
        return pixelMatrix
    }
    
   //MARK:- Print Matrix
    
    private func printMatrix(inputMatrix : [[Double]], height : Int = ImageProcessingConstants.optimalDimensionX, width : Int = ImageProcessingConstants.optimalDimensionY, name : String = "") {
        
        print("\n\n *********** PRINT MATRIX : \(name) ********** \n\n")
        for i in 0..<height {
            for j in 0..<width {
                let string = String(format: "%4.0f", inputMatrix[i][j])
                print(string, terminator : "")
            }
            print("")
        }
    }
}


extension ImagePreProcessing {
    
    //MARK:- Canny Edge Dectection Algo.
    
    private func cannyEdgeDetectionOperator(inputMatrix : [[Double]]) -> [[Double]] {
        
        // apply gaussian filter to remove noise
        let gaussainOutput  = gaussianFilter(inputMatrix:inputMatrix)
        printMatrix(inputMatrix: gaussainOutput, name : "Gaussain Output")
        
        // Find the intensity gradients of the image (apply sobel operator)
        let sobelOutput = sobelOperator(inputMatrix: gaussainOutput)
        printMatrix(inputMatrix: sobelOutput, name : "Sobel Output")
        
        // Apply non-maximum suppression to get rid of spurious response to edge detection
        let suppressedMatrix = suppression(inputMatrix: sobelOutput, intensityThreshold: ImageProcessingConstants.intensityThreshold)
        printMatrix(inputMatrix: suppressedMatrix, name : "Supression")
        
        return suppressedMatrix
    }
    
    //MARK:- Remove noise from Image
    
    func gaussianFilter(inputMatrix : [[Double]]) -> [[Double]] { // use 5*5 filter
        
        let gaussainMatrix = [
            [ 2.0, 4.0, 5.0, 4.0, 2.0 ],
            [ 4.0, 9.0, 12.0, 9.0, 4.0],
            [ 5.0, 12.0, 15.0, 12.0, 5.0],
            [ 4.0, 9.0, 12.0, 9.0, 4.0],
            [ 2.0, 4.0, 5.0, 4.0, 2.0 ]
        ]
        var filteredMatrix = [[Double]]()
        
        // intialize filteredMatrix
        
        for _ in 0..<ImageProcessingConstants.optimalDimensionX {
            var temp = [Double]()
            for _ in 0..<ImageProcessingConstants.optimalDimensionY {
                temp.append(0.0)
            }
            filteredMatrix.append(temp)
        }
        
        // compute
        
        for x in 2..<ImageProcessingConstants.optimalDimensionX-2 {
            for y in 2..<ImageProcessingConstants.optimalDimensionY-2 {
                
                var totalIntensity = 0.0
                
                var xDelta = -2
                for i in 0..<5 {
                    var yDelta = -2
                    for j in 0..<5 {
                        totalIntensity += gaussainMatrix[i][j] * inputMatrix[x+xDelta][y+yDelta]
                        yDelta += 1
                    }
                    xDelta += 1
                }
                
                filteredMatrix[x][y] = totalIntensity / 159.0
            }
        }
        return filteredMatrix
    }
    
    
    //MARK:- Edge Detection Technique ( Sobel operator ) on optimalPixelMatrix
    
    private func sobelOperator(inputMatrix : [[Double]]) -> [[Double]] {
        
        var filteredOutput = [[Double]]()
        
        // Initialize all elements with Zero elements
        
        for _ in 0..<ImageProcessingConstants.optimalDimensionX {
            var tempArr = [Double]()
            for _ in 0..<ImageProcessingConstants.optimalDimensionY {
                tempArr.append(0)
            }
            filteredOutput.append(tempArr)
        }
        
        // Calculate with Sobel fileter (3*3 matrix )
        
        let sobelFilterHorizonal : [[Double]] = [[1,0,-1],[2,0,-2],[1,0,-1]]
        let sobelFilterVertical  : [[Double]] = [[1,2,1],[0,0,0],[-1,-2,-1]]
        
        // apply sobel filter 9-Neighbor
        
        for i in 1..<ImageProcessingConstants.optimalDimensionX-1 {
            for j in 1..<ImageProcessingConstants.optimalDimensionY-1 {
                
                var Gx = inputMatrix[i-1][j-1] * sobelFilterHorizonal[0][0]
                Gx = Gx + inputMatrix[i-1][j+1] * sobelFilterHorizonal[0][2]
                Gx = Gx + inputMatrix[i][j-1] * sobelFilterHorizonal[1][0]
                Gx = Gx + inputMatrix[i][j+1] * sobelFilterHorizonal[1][2]
                Gx = Gx + inputMatrix[i+1][j-1] * sobelFilterHorizonal[2][0]
                Gx = Gx + inputMatrix[i+1][j+1] * sobelFilterHorizonal[2][2]
                
                
                var Gy = inputMatrix[i-1][j-1] * sobelFilterVertical[0][0]
                Gy = Gy + inputMatrix[i-1][j] * sobelFilterVertical[0][1]
                Gy = Gy + inputMatrix[i-1][j+1] * sobelFilterVertical[0][2]
                Gy = Gy + inputMatrix[i+1][j-1] * sobelFilterVertical[2][0]
                Gy = Gy + inputMatrix[i+1][j] * sobelFilterVertical[2][1]
                Gy = Gy + inputMatrix[i+1][j+1] * sobelFilterVertical[2][2]
                
                filteredOutput[i][j] = sqrt(Gx*Gx+Gy*Gy)
            }
        }
        return filteredOutput
    }
    
    
    //MARK:- suppression
    
    private func suppression(inputMatrix : [[Double]], intensityThreshold : Double) -> [[Double]] {
        
        var results = [[Double]]()
        
        //initialise
        for _ in 0..<ImageProcessingConstants.optimalDimensionX {
            var tempArr = [Double]()
            for _ in 0..<ImageProcessingConstants.optimalDimensionY {
                tempArr.append(0)
            }
            results.append(tempArr)
        }
        
        // supress
        for row in 0..<ImageProcessingConstants.optimalDimensionX {
            for column in 0..<ImageProcessingConstants.optimalDimensionY {
                var input = inputMatrix[row][column]
                if input > intensityThreshold {
                    input = 0
                }
                results[row][column] = input
            }
        }
        return results
    }
    

    
    //MARK:- Create Image from Pixel data
    
    private func createImageFromRGBData(inputMatrix : [Double], width : Int, height : Int) -> UIImage {
        
        var resultImage = UIImage()
        let bytesPerPixel = 4  // 4 bytes or 32 bits
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8 // rgba, so total lenghth = 32 bits
        var pixelData = inputMatrix
        let bitmapContext = CGContext(data: &pixelData[0], width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        if let cgImage = bitmapContext?.makeImage() {
            let image = UIImage(cgImage: cgImage)
            resultImage = image
        }
        return resultImage
    }
    
    // MARK:- CVPixelBuffer convert
    
    class func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    private func create1DMatrix(inputMatrix : [[Double]]) -> [Double] {
        var intensities = [Double]()
        for i in 0..<ImageProcessingConstants.optimalDimensionX {
            for j in 0..<ImageProcessingConstants.optimalDimensionY {
                intensities.append(inputMatrix[i][j]/255.0)
            }
        }
        return intensities
    }
}

