//
//  SceneNodeCreator.swift
//
//
//  Created by Ashis Laha on 14/07/17.
//

import Foundation
import SceneKit

class SceneNodeCreator {
    
    static let windowRoot : (x:Float,y:Float) = (-0.25,-0.25) // default is (0.0,0.0)
    static let z : Float = -0.5 // Z axis of AR co-ordinates
    
    //MARK:- Create straight Line
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
        let midPosition = SCNVector3Make((from.x+to.x)/2, (from.y+to.y)/2,(from.z+to.z)/2)
        let node = SCNNode(geometry: route)
        node.position = midPosition
        node.rotation = SCNVector4Make(0, 0, 1, Float(theta)) // along Z axis
        return node
    }
    
    //MARK:- Create Circle
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
    
    //MARK:- Add boundary Node
    class func boundaryNode() -> SCNNode {
        let node = SCNNode()
        let points : [(Float,Float)] = [(0.0,0.0),(0.5,0.0), (0.5,0.5), (0.0,0.5)]
        
        for i in 0..<4 {
            let x1 = points[i].0+SceneNodeCreator.windowRoot.x
            let y1 = points[i].1+SceneNodeCreator.windowRoot.y
            let x2 = points[(i+1)%points.count].0+SceneNodeCreator.windowRoot.x
            let y2 = points[(i+1)%points.count].1+SceneNodeCreator.windowRoot.y
            
            let from = SCNVector3Make(x1,y1,SceneNodeCreator.z)
            let to = SCNVector3Make(x2,y2,SceneNodeCreator.z)
            node.addChildNode(SceneNodeCreator.createline(from: from, to: to))
        }
        let textPosition = SCNVector3Make(0, -SceneNodeCreator.windowRoot.y+0.02, SceneNodeCreator.z)
        node.addChildNode(SceneNodeCreator.create3DText("Boundary", position: textPosition))
      return node
    }
    
    // calculate nodes based on data for shape detection
    class func getSceneNode(shapreResults : [[String : Any]] ) -> SCNScene { // input is array of dictionary
        let scene = SCNScene()
        let convertionRatio : Float = 1000.0
        let imageWidth : Int = 499
        
        for eachShape in shapreResults {
            if let dictionary = eachShape.first {
                
                let values = dictionary.value as! [[String : Any]]
                switch dictionary.key {
                case "circle" :
                    
                    if let circleParams = values.first as? [String : Float] {
                        let x = circleParams["center.x"] ?? 0.0
                        let y = circleParams["center.y"] ?? 0.0
                        let radius = circleParams["radius"] ?? 0.0
                        let center = SCNVector3Make(Float(Float(imageWidth)-y)/convertionRatio+SceneNodeCreator.windowRoot.x, Float(Float(imageWidth)-x)/convertionRatio+SceneNodeCreator.windowRoot.y, SceneNodeCreator.z)
                        scene.rootNode.addChildNode(SceneNodeCreator.createCircle(center: center, radius: CGFloat(radius/convertionRatio)))
                        
                        // adding text
                        var textPosition = center
                        textPosition.y = textPosition.y + (radius/convertionRatio) + 0.01
                        scene.rootNode.addChildNode(SceneNodeCreator.create3DText("C", position: textPosition))
                        
                    }
                    
                case "line","triangle", "rectangle","pentagon","hexagon":
                    for i in 0..<values.count { // connect all points usning straight lines (basic)
                        let x1 = values[i]["x"] as! Int
                        let y1 = values[i]["y"] as! Int
                        let x2 = values[(i+1)%values.count]["x"] as! Int
                        let y2 = values[(i+1)%values.count]["y"] as! Int
                        
                        // skip the boundary Rectangle here
                        if x1>15 && x1<485 {
                            let from = SCNVector3Make(Float(imageWidth-y1)/convertionRatio+SceneNodeCreator.windowRoot.x, Float(imageWidth-x1)/convertionRatio+SceneNodeCreator.windowRoot.y, SceneNodeCreator.z)
                            let to = SCNVector3Make(Float(imageWidth-y2)/convertionRatio+SceneNodeCreator.windowRoot.x, Float(imageWidth-x2)/convertionRatio+SceneNodeCreator.windowRoot.y, SceneNodeCreator.z)
                            scene.rootNode.addChildNode(SceneNodeCreator.createline(from: from, to: to))
                        }
                    }
                    
                    // add shape description
                    switch values.count {
                    case 2: // line
                        let x1 = values[0]["x"] as! Int
                        let y1 = values[0]["y"] as! Int
                        let x2 = values[1]["x"] as! Int
                        let y2 = values[1]["y"] as! Int
                        let center = SceneNodeCreator.center(diagonal_p1: (Float(x1),Float(y1)), diagonal_p2: (Float(x2),Float(y2)))
                        let centerVector = SCNVector3Make((Float(imageWidth)-center.1)/convertionRatio+SceneNodeCreator.windowRoot.x,
                                                          (Float(imageWidth)-center.0)/convertionRatio+SceneNodeCreator.windowRoot.y,
                                                          SceneNodeCreator.z)
                        scene.rootNode.addChildNode(SceneNodeCreator.create3DText("R", position: centerVector))
                        
                    case 3 : // traingle
                        let x1 = values[0]["x"] as! Int
                        let y1 = values[0]["y"] as! Int
                        let x2 = values[1]["x"] as! Int
                        let y2 = values[1]["y"] as! Int
                        let x3 = values[2]["x"] as! Int
                        let y3 = values[2]["y"] as! Int
                        
                        let centroid = SceneNodeCreator.centroidOfTriangle(point1: (Float(x1),Float(y1)), point2: (Float(x2),Float(y2)), point3: (Float(x3),Float(y3)))
                        let centerVector = SCNVector3Make((Float(imageWidth)-centroid.1)/convertionRatio+SceneNodeCreator.windowRoot.x,
                                                          (Float(imageWidth)-centroid.0)/convertionRatio+SceneNodeCreator.windowRoot.y,
                                                          SceneNodeCreator.z)
                        
                        scene.rootNode.addChildNode(SceneNodeCreator.create3DText("T", position: centerVector))
                        
                    case 4: // Rectangle
                        let x1 = values[0]["x"] as! Int
                        let y1 = values[0]["y"] as! Int
                        let x2 = values[2]["x"] as! Int
                        let y2 = values[2]["y"] as! Int
                        let center = SceneNodeCreator.center(diagonal_p1: (Float(x1),Float(y1)), diagonal_p2: (Float(x2),Float(y2)))
                        let centerVector = SCNVector3Make((Float(imageWidth)-center.1)/convertionRatio+SceneNodeCreator.windowRoot.x,
                                                          (Float(imageWidth)-center.0)/convertionRatio+SceneNodeCreator.windowRoot.y,
                                                          SceneNodeCreator.z)
                        scene.rootNode.addChildNode(SceneNodeCreator.create3DText("R", position: centerVector))
                        
                    case 5,6: // pentagon, Hexagon
                        let x1 = values[0]["x"] as! Int
                        let y1 = values[0]["y"] as! Int
                        let x2 = values[3]["x"] as! Int
                        let y2 = values[3]["y"] as! Int
                        let center = SceneNodeCreator.center(diagonal_p1: (Float(x1),Float(y1)), diagonal_p2: (Float(x2),Float(y2)))
                        let centerVector = SCNVector3Make((Float(imageWidth)-center.1)/convertionRatio+SceneNodeCreator.windowRoot.x,
                                                          (Float(imageWidth)-center.0)/convertionRatio+SceneNodeCreator.windowRoot.y,
                                                          SceneNodeCreator.z)
                        let text = (values.count == 5) ? "P" : "H"
                        scene.rootNode.addChildNode(SceneNodeCreator.create3DText(text, position: centerVector))
                        
                    default:
                        print("NO Shape")
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
    
    class func centroidOfTriangle(point1 : (Float,Float), point2 : (Float,Float), point3 : (Float,Float)) -> (Float,Float) {
        var centroid : (x:Float, y:Float) = (0.0,0.0)
        let middleOfp1p2 : (x:Float, y:Float) = ((point1.0+point2.0)/2 , (point1.1+point2.1)/2)
        centroid.x = point3.0 + 2/3*(middleOfp1p2.x-point3.0)
        centroid.y = point3.1 + 2/3*(middleOfp1p2.y-point3.1)
        return centroid
    }
    
    class func center(diagonal_p1: (Float,Float), diagonal_p2 : (Float,Float)) -> (Float,Float) {
        return ((diagonal_p1.0+diagonal_p2.0)/2 ,(diagonal_p1.1+diagonal_p2.1)/2)
    }
}

/*
         ******************************** Below extension NOT USED FOR SHAPE DETECTION *******************************
 */


enum GeometryNode {
    case Box
    case Pyramid
    case Capsule
    case Cone
    case Cylinder
}

enum ArrowDirection {
    case towards
    case backwards
    case left
    case right
}

extension SceneNodeCreator {
    
    class func getGeometryNode(type : GeometryNode, position : SCNVector3, text : String? = nil, imageName : String? = nil) -> SCNNode {
        var geometry : SCNGeometry!
        switch type {
        case .Box:          geometry = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.2)
        case .Pyramid:      geometry = SCNPyramid(width: 0.5, height: 0.5, length: 0.5)
        case .Capsule:      geometry = SCNCapsule(capRadius: 0.5, height: 0.5)
        case .Cone:         geometry = SCNCone(topRadius: 0.0, bottomRadius: 0.3, height: 0.5)
        case .Cylinder:     geometry = SCNCylinder(radius: 0.1, height: 0.5)
        }
        
        if let imgName = imageName , let image =  UIImage(named: imgName) {
             geometry.firstMaterial?.diffuse.contents = image
        } else if let txt = text, let img = imageWithText(text:txt, imageSize: CGSize(width: 1024, height: 1024), backgroundColor: UIColor.getRandomColor()) {
            geometry.firstMaterial?.diffuse.contents = img
        } else {
            geometry.firstMaterial?.diffuse.contents = UIColor.getRandomColor()
        }
        geometry.firstMaterial?.specular.contents = UIColor.getRandomColor()
        let node = SCNNode(geometry: geometry)
        node.position = position
        return node
    }
    
    class func drawPath(position1 : SCNVector3, position2 : SCNVector3 ) -> SCNNode {
        
        // calculate Angle
        let dx = position2.x - position1.x
        let dz = (-1.0) * (position2.z - position1.z)
        var theta = atan(Double(dz/dx))
        if theta == .nan {
            theta = 3.14159265358979 / 2 // 90 Degree
        }
        print("Angle between point1 and point2 is : \(theta * 180 / Double.pi) along Y-Axis")
        
        //Create Node
        let width = CGFloat(sqrt( dx*dx + dz*dz ))
        let height : CGFloat = 0.1
        let length : CGFloat = 0.8
        let chamferRadius : CGFloat = 0.05
        let route = SCNBox(width: width, height: height, length: length, chamferRadius: chamferRadius)
        route.firstMaterial?.diffuse.contents = UIColor(red: 210.0/255.0, green: 217.0/255.0, blue: 66.0/255.0, alpha: 1.0)
        let midPosition = SCNVector3Make((position1.x+position2.x)/2, -1, (position1.z+position2.z)/2)
        let node = SCNNode(geometry: route)
        node.position = midPosition
        
        // Do rotation of node in "theta" angle along Y-axis with Animation
       /*
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.fromValue = SCNVector4Make(0, 1, 0, 0)
        rotation.toValue = SCNVector4Make(0, 1, 0,  Float(theta))
        rotation.duration = 2.0
        node.addAnimation(rotation, forKey: "Rotate it")
        */
        node.rotation = SCNVector4Make(0, 1, 0, Float(theta))
        return node
    }
    
    class func drawArrow(position1 : SCNVector3, position2 : SCNVector3 ) -> SCNNode {
        
        let angle = getAngle(position1: position1, position2: position2)
        // create node
        let midPosition = SCNVector3Make((position1.x+position2.x)/2, 1.0, (position1.z+position2.z)/2)
        print("Draw Arrow at \(midPosition)")
        let arrowNode = SceneNodeCreator.createNodeWithImage(image: UIImage(named: "arrow")!, position: midPosition, width: 2, height: 2)
        arrowNode.rotation = SCNVector4Make(0, 1, 0, Float(angle))
        
        return arrowNode
    }
    
    class func getAngle(position1 : SCNVector3, position2 : SCNVector3) -> Double {
        // calculate Angle
        let dx = position2.x - position1.x
        let dz = (-1.0) * (position2.z - position1.z)
        var theta = atan(Double(dz/dx))
        if theta == .nan {
            theta = 3.14159265358979 / 2  // 90 Degree
        }
        return theta
    }
    
    class func drawBanner(position1 : SCNVector3, position2 : SCNVector3) -> [SCNNode] { // it gives at the begining & mid-point for advertisement
        
        let delta : Float = 5.0
        let startPosition = SCNVector3Make(position1.x + delta, 1.0, position1.z + delta)
        let midPosition = SCNVector3Make((position1.x+position2.x)/2 + delta, 1.0, (position1.z+position2.z)/2 + delta) // adding to x or Z should be based on angle
        print("Advertisement drawn at begin : \(startPosition) and mid : \(midPosition)")
        let bannerBegin = SceneNodeCreator.createNodeWithImage(image: UIImage(named: "advertisement")!, position: startPosition, width: 7, height: 7)
        let bannerMid = SceneNodeCreator.createNodeWithImage(image: UIImage(named: "advertisement")!, position: midPosition, width: 7, height: 7)
        return [bannerBegin,bannerMid]
    }
    
    class func createNodeWithImage(image : UIImage, position : SCNVector3 , width : CGFloat, height : CGFloat ) -> SCNNode {
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = image
        plane.firstMaterial?.lightingModel = .constant
        let node = SCNNode(geometry: plane)
        node.position = position
        return node
    }
    
    // Composite node
    class func getCompositeNode(position : SCNVector3 , direction : ArrowDirection ) -> SCNNode {
        let color = UIColor.getRandomColor()
        let cylinder = SCNCylinder(radius: 0.1, height: 0.6)
        cylinder.firstMaterial?.diffuse.contents = color
        let cylinderNode = SCNNode(geometry: cylinder)
        
        let pyramid = SCNPyramid(width: 0.5, height: 0.5, length: 0.5)
        pyramid.firstMaterial?.diffuse.contents = color
        let pyramidNode = SCNNode(geometry: pyramid)
        pyramidNode.position = position
        pyramidNode.addChildNode(cylinderNode)
        
        let rotation = CABasicAnimation(keyPath: "rotation")
        switch direction {
            case .left:
                rotation.fromValue = SCNVector4Make(0, 0, 1, 0)
                rotation.toValue = SCNVector4Make(0, 0, 1, Float(Double.pi / 2 )) // Anti-clockwise 90 degree around z-axis
                pyramidNode.rotation = SCNVector4Make(0, 0, 1, Float(Double.pi / 2 ))
            case .right:
                rotation.fromValue = SCNVector4Make(0, 0, 1, 0)
                rotation.toValue = SCNVector4Make(0, 0, 1, -Float(Double.pi / 2 )) // clockwise 90 degree around z-axis
                pyramidNode.rotation = SCNVector4Make(0, 0, 1, -Float(Double.pi / 2 ))
            case .towards:
                rotation.fromValue = SCNVector4Make(1, 0, 0, 0)
                rotation.toValue = SCNVector4Make(1, 0, 0, -Float(Double.pi / 2 ))  // clockwise 90 degree around x-axis
                pyramidNode.rotation = SCNVector4Make(1, 0, 0, -Float(Double.pi / 2 ))
            case .backwards:
                rotation.fromValue = SCNVector4Make(1, 0, 0, 0)
                rotation.toValue = SCNVector4Make(1, 0, 0, Float(Double.pi / 2 )) // anti-clockwise 90 degree around x-axis
                pyramidNode.rotation = SCNVector4Make(1, 0, 0, Float(Double.pi / 2 ))
        }
        rotation.duration = 2.0
        pyramidNode.addAnimation(rotation, forKey: "Rotate it")
        
        return pyramidNode
    }
    
    // Camera node
    class func createCameraNode(position : SCNVector3) -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = position
        return cameraNode
    }
    
    // omni light node
    class func createLightNode(position : SCNVector3) -> SCNNode {
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light?.type = .omni
        omniLightNode.light?.color = UIColor.white.withAlphaComponent(0.5)
        omniLightNode.position = position
        return omniLightNode
    }
    
    // Scene node
    class func createSceneNode(sceneName : String , position : SCNVector3) -> SCNNode {
        if let scene = SCNScene(named:sceneName) {
            let sceneNode = scene.rootNode.childNodes.first ?? SCNNode()
            sceneNode.position = position
            return sceneNode
        }
        return SCNNode()
    }
    
    // Image with Text
    class func imageWithText(text:String, fontSize:CGFloat = 150, fontColor: UIColor = .black, imageSize:CGSize, backgroundColor:UIColor) -> UIImage? {
        let imageRect = CGRect(origin: CGPoint.zero, size: imageSize)
        UIGraphicsBeginImageContext(imageSize)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Fill the background with a color
        context.setFillColor(backgroundColor.cgColor)
        context.fill(imageRect)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        // Define the attributes of the text
        let attributes : [NSAttributedStringKey : Any] = [
            NSAttributedStringKey.font : UIFont(name: "TimesNewRomanPS-BoldMT", size:fontSize) ?? UIFont.italicSystemFont(ofSize: fontSize),
            NSAttributedStringKey.paragraphStyle : paragraphStyle,
            NSAttributedStringKey.foregroundColor : fontColor
        ]
        
        // Determine the width/height of the text for the attributes
        let textSize = text.size(withAttributes: attributes)
        
        // Draw text in the current context
        text.draw(at: CGPoint(x: imageSize.width/2 - textSize.width/2, y: imageSize.height/2 - textSize.height/2), withAttributes: attributes)
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        }
        return nil
    }
    
    //MARK:- 3D Text
    class func create3DText(_ text : String, position : SCNVector3) -> SCNNode {
        
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // text billboard constraint
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // text
        let depth : CGFloat = 0.01
        let bubble = SCNText(string: text, extrusionDepth: depth)
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitItalic)
        bubble.font = font
        bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        bubble.chamferRadius = CGFloat(depth)
        
        // node
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, Float(depth/2))
        
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.12, 0.12, 0.12)
        
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        bubbleNodeParent.position = position
        
        return bubbleNodeParent
    }
    
    
    // Temporary Scene Graph
    class func sceneSetUp() -> SCNScene {
        let scene = SCNScene()
        scene.rootNode.addChildNode(SceneNodeCreator.getGeometryNode(type: .Box, position: SCNVector3Make(-1, 0, -1), text: "Hi"))
        scene.rootNode.addChildNode(SceneNodeCreator.create3DText("Hello World", position: SCNVector3Make(0, 0, -0.2)))
        return scene
    }
}

extension UIColor {
    class func getRandomColor() -> UIColor {
        let random = Int(arc4random_uniform(8))
        switch random {
        case 0: return UIColor.red
        case 1: return UIColor.brown
        case 2: return UIColor.green
        case 3: return UIColor.yellow
        case 4: return UIColor.blue
        case 5: return UIColor.purple
        case 6: return UIColor.cyan
        case 7: return UIColor.orange
        default: return UIColor.darkGray
        }
    }
}

extension UIFont {
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}
