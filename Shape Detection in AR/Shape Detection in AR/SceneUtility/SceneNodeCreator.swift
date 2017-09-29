//
//  SceneNodeCreator.swift
//
//
//  Created by Ashis Laha on 14/07/17.
//

import Foundation
import SceneKit

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

class SceneNodeCreator {
    
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
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // center point of node
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        bubbleNodeParent.position = position
        
        return bubbleNodeParent
    }
    
    
    // Temporary Scene Graph
    class func sceneSetUp() -> SCNScene {
        let scene = SCNScene()
        scene.rootNode.addChildNode(SceneNodeCreator.getGeometryNode(type: .Box, position: SCNVector3Make(-1, 0, -1), text: "Hi"))
        scene.rootNode.addChildNode(SceneNodeCreator.create3DText("Hello World", position: SCNVector3Make(0, 0, -0.2)))
        
        /*
        scene.rootNode.addChildNode(SceneNodeCreator.getGeometryNode(type: .Capsule, position: SCNVector3Make(-1, 0, -1), text: "Hi" ))
        scene.rootNode.addChildNode(SceneNodeCreator.getCompositeNode(position: SCNVector3Make(0, 0, -2), direction: .right))
        scene.rootNode.addChildNode(SceneNodeCreator.createSceneNode(sceneName: "art.scnassets/ship.scn", position:  SCNVector3Make(1, 0, -1)))
        scene.rootNode.addChildNode(SceneNodeCreator.getGeometryNode(type: .Cone, position: SCNVector3Make(2, 0, -1),text: "Hi"))
        scene.rootNode.addChildNode(SceneNodeCreator.getGeometryNode(type: .Pyramid, position: SCNVector3Make(3, 0, -1),text: "Hi"))
       */
        
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
