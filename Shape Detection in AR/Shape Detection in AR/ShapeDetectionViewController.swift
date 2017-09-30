//
//  ViewController.swift
//  Shape Detection in AR
//
//  Created by Ashis Laha on 22/09/17.
//  Copyright © 2017 Ashis Laha. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ShapeDetectionViewController: UIViewController, ARSCNViewDelegate , ARSessionDelegate {

    let dispatchQueueAR = DispatchQueue(label: "arkit.scan") // A Serial Queue
    private var overlayView : UIView!
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self           // ARSCNViewDelegate for maintaining SCNView objects
        sceneView.session.delegate = self   // ARSessionDelegatem for maintaining Session 
        sceneView.showsStatistics = true
        sceneView.scene = SCNScene()
        navigationController?.navigationBar.backgroundColor = UIColor.clear
        // Scan the ARFrame always
        //continuousScanning() // need to improve the performance without blocking the main-thread --- "Thinking"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()  // session config
        configuration.planeDetection = .horizontal          // plane detection
        configuration.worldAlignment = .gravity             // Create object with respect to front of camera and gravity
        sceneView.session.run(configuration)                // run the session with config
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    private func continuousScanning() {
        dispatchQueueAR.async { [weak self] in
            //self?.detect()
            self?.continuousScanning()
        }
    }
    
    //MARK:- Detect
    @IBAction func detect(_ sender: UIBarButtonItem) {
        detect()
    }
    
    //MARK:- Detect Captured Image
    private func detect() {
        if let image = self.sceneView.session.currentFrame?.capturedImage {
            self.detectCapturedImage(image: image)
        }
    }
    
    private func detectCapturedImage( image : CVPixelBuffer) {
        if let image = convertImage(input: image) {
            DispatchQueue.main.async { [weak self] in
                
                let resizeImage = image.resized(width: 500, height: 500)
                if let resizeImageInPixelBuffer = resizeImage.pixelBuffer(width: 500, height: 500) {
                    if let edgeDetectedImage = EdgeDetectionUtil.classify(image: resizeImageInPixelBuffer, row: 500, column: 500) {
                        // save the image into photo library to retrieve other information
                        let rotatedImage = UIImage(cgImage: edgeDetectedImage.cgImage!, scale: 1.0, orientation: UIImageOrientation.right)
                        UIImageWriteToSavedPhotosAlbum(rotatedImage, self, nil, nil)
                        // call open CV frameworks to perform the rest actions
                        self?.sceneView.scene = EdgeDetectionUtil.getShapes(edgeDetectedImage: edgeDetectedImage)
                    }
                }
            }
        }
    }
    
    private func convertImage(input : CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: input)
        let ciContext = CIContext(options: nil)
        if let videoImage = ciContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(input), height: CVPixelBufferGetHeight(input))) {
            return UIImage(cgImage: videoImage)
        }
        return nil
    }
    
    //MARK:- Clean the Scene Nodes 
    @IBAction func clean(_ sender: UIBarButtonItem) {
       sceneView.scene = SCNScene() // assign an empty scene
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
}

//MARK:- Error Handling
extension ShapeDetectionViewController {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .limited(let reason) :
            if reason == .excessiveMotion {
                showAlert(header: "Tracking State Failure", message: "Excessive Motion")
            } else if reason == .insufficientFeatures {
                showAlert(header: "Tracking State Failure", message: "Insufficient Features")
            }
        case .normal, .notAvailable : break
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        showAlert(header: "Session Failure", message: "\(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("sessionWasInterrupted")
        addOverlay()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("sessionInterruptionEnded")
        removeOverlay()
    }
    
    private func showAlert(header : String? = "Header", message : String? = "Message")  {
        let alertController = UIAlertController(title: header, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (alert) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    private func addOverlay() {
        overlayView = UIView(frame: sceneView.bounds)
        overlayView.backgroundColor = UIColor.brown
        self.sceneView.addSubview(overlayView)
    }
    
    private func removeOverlay() {
        if let overlayView = overlayView {
            overlayView.removeFromSuperview()
        }
    }
}

