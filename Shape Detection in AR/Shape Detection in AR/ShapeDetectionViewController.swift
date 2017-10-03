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
    private var isProcessStart : Bool = false
    private let configuration = ARWorldTrackingConfiguration()  // session config
    var detectButton : UIButton!
    var cleanButton  : UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationTitle()
        sceneView.delegate = self           // ARSCNViewDelegate for maintaining SCNView objects
        sceneView.session.delegate = self   // ARSessionDelegatem for maintaining Session 
        sceneView.showsStatistics = true
        sceneView.scene = SCNScene()
        addDetectButton()
        addCleanButton()
        // Scan the ARFrame always
        //continuousScanning() // need to improve the performance without blocking the main-thread --- "Thinking"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        runConfig()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        addCleanButton()
        addDetectButton()
    }

    private func continuousScanning() {
        dispatchQueueAR.async { [weak self] in
            self?.cleanAR()
            self?.detect()
            self?.continuousScanning()
        }
    }
    
    //MARK:- Reset config
    private func resetConfig() {
        self.sceneView.session.run(configuration, options: .resetTracking)
    }
    
    //MARK:- Run new config
    private func runConfig() {
        //configuration.planeDetection = .horizontal        // plane detection
        configuration.worldAlignment = .gravity             // Create object with respect to front of camera
        sceneView.session.run(configuration)                // run the session with config
    }
    
    //MARK:- Set title
    private func setNavigationTitle() {
        // let's create some attributed string
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.gray
        shadow.shadowBlurRadius = 3.0
        shadow.shadowOffset = CGSize(width: 3.0, height: 3.0)
        
        let attributedString = NSMutableAttributedString(string: "Shape Detection", attributes: [
            NSAttributedStringKey.foregroundColor : UIColor.red,   // text color
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: 20), // Font size
            NSAttributedStringKey.shadow : shadow // shadow effect
            ])
        let label = UILabel()
        label.attributedText = attributedString
        label.sizeToFit()
        self.navigationItem.titleView = label
    }
    
    //MARK:- Detect Captured Image
    @objc private func detect() {
        resetConfig()
        runConfig()
        cleanAR()
        if let image = self.sceneView.session.currentFrame?.capturedImage {
            self.detectCapturedImage(image: image)
        }
    }
    
    fileprivate func addDetectButton() {
        if detectButton != nil { detectButton.removeFromSuperview() }
        
        let buttonWidth : CGFloat = 100.0
        let windowWidth = (getWindow().width > 0) ? getWindow().width : buttonWidth+20.0
        let windowHeight = (getWindow().height > 0) ? getWindow().height : CGFloat(600.0)
  
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(self.detect), for: .touchUpInside)
        button.setTitle("Detect", for: .normal)
        button.frame = CGRect(x: windowWidth-buttonWidth-10.0, y: windowHeight-200.0, width: buttonWidth, height: 40.0)
        button.backgroundColor = UIColor.blue
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 20.0
        detectButton = button
        view.addSubview(detectButton)
    }

    //MARK:- Clean the Scene Nodes
    @objc private func cleanAR() {
        sceneView.scene = SCNScene() // assign an empty scene
        resetConfig()
    }
    
    fileprivate func addCleanButton() {
        if cleanButton != nil { cleanButton.removeFromSuperview() }
        
        let buttonWidth : CGFloat = 100.0
        let windowWidth = (getWindow().width > 0) ? getWindow().width : buttonWidth+20.0
        let windowHeight = (getWindow().height > 0) ? getWindow().height : CGFloat(600.0)
        
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(self.cleanAR), for: .touchUpInside)
        button.setTitle("Clean", for: .normal)
        button.frame = CGRect(x: windowWidth-buttonWidth-10.0, y: windowHeight-120.0, width: buttonWidth, height: 40.0)
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 20.0
        cleanButton = button
        view.addSubview(cleanButton)
    }
    
    private func getWindow() -> CGRect {
        guard let appDelegate = UIApplication.shared.delegate else { return CGRect(origin: .zero, size: .zero) }
        guard let window = appDelegate.window else { return CGRect(origin: .zero, size: .zero) }
        return window?.frame ?? CGRect(origin: .zero, size: .zero)
    }
    
    private func detectCapturedImage( image : CVPixelBuffer) {
        if let image = convertImage(input: image) {
            DispatchQueue.main.async { [weak self] in
                
                let resizeImage = image.resized(width: 500, height: 500)
                if let resizeImageInPixelBuffer = resizeImage.pixelBuffer(width: 500, height: 500) {
                    if let edgeDetectedImage = EdgeDetectionUtil.classify(image: resizeImageInPixelBuffer, row: 500, column: 500) {
                        // save the image into photo library for Visualization
                        // let rotatedImage = UIImage(cgImage: edgeDetectedImage.cgImage!, scale: 1.0, orientation: UIImageOrientation.right)
                        // UIImageWriteToSavedPhotosAlbum(rotatedImage, self, nil, nil)
                        
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

