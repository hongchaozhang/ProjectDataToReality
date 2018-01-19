//
//  ViewController.swift
//  ProjectDataToReality
//
//  Created by Hongchao on 1/18/18.
//  Copyright © 2018 MicroStrategy. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    private let showDebugInfo = true
    private let showRecognizedResultNearby = true
    private var recognizedResultNode: SCNNode?
    private var debugTextView = UITextView()
    private var chartImageDic = [String: UIImage]()

    private var latestPrediction: String = "…"
    private var latestPredictionConfidence: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configARSceneView()
        addScene()
        addDebuggingView()
        addCenterImage()
        addGestures()
        prepareData()
        createCoreMLRequests()
        loopCoreMLUpdate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Enable plane detection
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - Configure View
    private func configARSceneView() {
        sceneView.delegate = self

        if showDebugInfo {
            // Show statistics such as fps and timing information
            sceneView.showsStatistics = true
            // ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints
            sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        }

        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
    }

    // hide status bar
    override public var prefersStatusBarHidden : Bool {
        return true
    }

    private func addScene() {
        let scene = SCNScene()
        sceneView.scene = scene
    }

    private func addDebuggingView() {
        if showDebugInfo {
            debugTextView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
            debugTextView.backgroundColor = UIColor.clear
            view.addSubview(debugTextView)
        }
    }

    private func addCenterImage() {
        let centerIcon = UIImageView()
        centerIcon.backgroundColor = UIColor.clear
        centerIcon.image = UIImage(named: "miaozhun.png")
        let centerIconSize = CGSize(width: 30, height: 30)
        centerIcon.frame = CGRect(x: (view.frame.size.width - centerIconSize.width) / 2,
                                  y: (view.frame.size.height - centerIconSize.height) / 2,
                                  width: centerIconSize.width,
                                  height: centerIconSize.height)
        view.addSubview(centerIcon)
    }

    private func prepareData() {
        chartImageDic["banana"] = UIImage(named: "chart_banana.png")
        chartImageDic["cucumber"] = UIImage(named: "chart_cucumber.png")
        chartImageDic["orange"] = UIImage(named: "chart_orange.png")
        chartImageDic["strawberry"] = UIImage(named: "chart_strawberry.png")
    }

    // MARK: - CoreML
    // CoreML
    private var classificationRequest: VNCoreMLRequest!
    private var faceDetectionRequest: VNDetectFaceRectanglesRequest!
    private var faceRecognitionRequest: VNCoreMLRequest!
    private let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: {_ in
            self.dispatchQueueML.async {
                self.runImageBasedRequest(request: self.classificationRequest)
            }
        })

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: {_ in
            self.dispatchQueueML.async {
                self.runImageBasedRequest(request: self.faceDetectionRequest)
            }
        })

//        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
//            self.dispatchQueueML.async {
//                self.runImageBasedRequest(request: self.faceRecognitionRequest)
//            }
//        })

        //        dispatchQueueML.async {
        //            // 1. Run Update.
        //            self.updateCoreML()
        //
        //            // 2. Loop this function.
        //            self.loopCoreMLUpdate()
        //        }

    }

    private func runImageBasedRequest(request: VNRequest) {
        guard let pixbuff = (sceneView.session.currentFrame?.capturedImage) else { return }
//        let ciImage = CIImage(cvPixelBuffer: pixbuff)
        // Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.

        // For face detection on iphone, rotate to left by 90 degrees. This maybe related to the pixbuff orientation. Considering using the following initializer:
        // public init(cvPixelBuffer pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation, options: [VNImageOption : Any] = [:])
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixbuff, options: [:])

        do {
            try imageRequestHandler.perform([request])
        } catch {
            print(error)
        }
    }

    private func createCoreMLRequests() {
        guard let selectedModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }

//        guard let faceRecognitionModel = try? VNCoreMLModel(for: FaceRecognition().model) else {
//            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
//        }

        // Set up Vision-CoreML Request
        classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: fruitClassificationCompletionHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.

        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: faceDetectionCompleteHandler)

//        faceRecognitionRequest = VNCoreMLRequest(model: faceRecognitionModel, completionHandler: faceRecognitionCompleteHandler)
//        faceRecognitionRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
    }

    private func fruitClassificationCompletionHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Classification: Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("Classification: No results")
            return
        }

        // Get Classifications
        let classifications = observations[0...1] // top 2 results
            .flatMap({ $0 as? VNClassificationObservation })
            .filter({ $0.confidence > 0.2 })
            .map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
            .joined(separator: "\n")

        var bestRecognition: String?
        if observations.count > 0 {
            if let observation = observations[0] as? VNClassificationObservation {
                bestRecognition = observation.identifier + String(format:"-%.2f", observation.confidence)
            }
        }

        DispatchQueue.main.async {
            // Print Classifications
            print("Classification: " + classifications)

            if let bestRecognition = bestRecognition {
                var bestIdentifier = bestRecognition.components(separatedBy: "-")[0].components(separatedBy: ",")[0].lowercased()
                // as the Inceptionv3 model can not tell the following fruits very well, so to make system stable, hard code them. We can train a better fruit recognition model for further use.
                if bestIdentifier == "lemon" {
                    bestIdentifier = "orange"
                } else if bestIdentifier == "zucchini" {
                    bestIdentifier = "cucumber"
                }
                self.latestPrediction = bestIdentifier
                self.latestPredictionConfidence = Double(bestRecognition.components(separatedBy: "-")[1]) ?? 0
                if self.showDebugInfo {
                    self.debugTextView.text = classifications
                }
                //                self.tryToAddObjectChart(for: self.latestPrediction, and: self.latestPredictionConfidence)
            }
        }
    }

    private func faceRecognitionCompleteHandler(request: VNRequest, error: Error?) {
        // similar to fruitClassificationCompletionHandler
    }

    private var previousLayer: CALayer?
    private func faceDetectionCompleteHandler(request: VNRequest, error: Error?) {
        func removeFaceRelated() {
            DispatchQueue.main.async {
                self.previousLayer?.removeFromSuperlayer()
                self.previousLayer = nil
            }
        }
        if let error = error {
            removeFaceRelated()
            print(error.localizedDescription)
            return
        } else {
            guard let observations = request.results as? [VNFaceObservation] else {
                removeFaceRelated()
                return
            }
            guard observations.count > 0 else {
                removeFaceRelated()
                return
            }

            // a bug here: if we cope with more than one faces here, app will crash
            [observations[0]].forEach { observation in
                DispatchQueue.main.async {
                    let boundingBox = observation.boundingBox
                    let size = CGSize(width: boundingBox.width * self.view.bounds.width,
                                      height: boundingBox.height * self.view.bounds.height)
                    let origin = CGPoint(x: boundingBox.minX * self.view.bounds.width,
                                         y: (1 - observation.boundingBox.minY) * self.view.bounds.height - size.height)

                    self.previousLayer?.removeFromSuperlayer()
                    let layer = CAShapeLayer()
                    layer.frame = CGRect(origin: origin, size: size)
                    layer.borderColor = UIColor.red.cgColor
                    layer.borderWidth = 2
                    self.view.layer.addSublayer(layer)
                    self.previousLayer = layer
                }
            }
        }
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }

    // MARK: - Create Virtual Objeccts

    private var allChartNodesDic = [String: SCNNode]()
    private let confidenceThreshold: Double = 0.3

    private func tryToAddObjectChart(for name: String, and confidence: Double) {
        if confidence > confidenceThreshold {
            addObjectChart(for: name)
        }
    }

    private func getWorldPosition(from point: CGPoint) -> SCNVector3 {
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(point, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.

        var worldCoord = SCNVector3(0, 0, 0)
        if let closestResult = arHitTestResults.first {
            let transform: matrix_float4x4 = closestResult.worldTransform
            worldCoord = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        }

        return worldCoord
    }

    private func getCenterPointWorldPosition() -> SCNVector3 {
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        return getWorldPosition(from: screenCentre)
    }

    private func addObjectChart(for name: String) {
        //            // create ARBarChart
        if let existNode = allChartNodesDic[name] {
            existNode.removeFromParentNode()
            allChartNodesDic.removeValue(forKey: name)
        }

        if let screenshot = chartImageDic[name] {
            let worldCoord = getCenterPointWorldPosition()

            let screenshotNode = createNode(from: screenshot)
            screenshotNode.scale = SCNVector3(0.2, 0.2, 0.2)
            var position = worldCoord
            let offset: Float = 0.2
            position = SCNVector3(worldCoord.x, worldCoord.y + offset, worldCoord.z)
            screenshotNode.position = position
            if let eularAngles = sceneView.session.currentFrame?.camera.eulerAngles {
                // to make the newly added chart is facing the current camera, that is the user
                screenshotNode.eulerAngles.y = eularAngles.y
            }
            sceneView.scene.rootNode.addChildNode(screenshotNode)
            allChartNodesDic[name] = screenshotNode
        }
    }

    private func createNode(from image: UIImage) -> SCNNode {
        let imageNode = SCNNode()

        let cubeWidth: CGFloat  = 1.0
        let cubeHeight = cubeWidth * image.size.height / image.size.width

        imageNode.geometry = SCNBox.init(width: cubeWidth, height: cubeHeight, length: 0.000001, chamferRadius: 0.1)

        imageNode.geometry?.firstMaterial?.diffuse.contents = image
        imageNode.geometry?.firstMaterial?.multiply.intensity = 0.5
        imageNode.geometry?.firstMaterial?.lightingModel = SCNMaterial.LightingModel.constant
        imageNode.opacity = 0.8

        return imageNode
    }

    private var arChartNode: SCNNode?

    private func tryToAddARChartNode(at worldPosition: SCNVector3) {

        arChartNode?.removeFromParentNode()

        let chartNode = createBarChartNode()
        chartNode.position = worldPosition
        sceneView.scene.rootNode.addChildNode(chartNode)

        arChartNode = chartNode

    }

    let settings = Settings()

    private func createBarChartNode() -> ARBarChart  {
        var values = generateRandomNumbers(withRange: 0..<50, numberOfRows: settings.numberOfSeries, numberOfColumns: settings.numberOfIndices)
        var seriesLabels = Array(0..<values.count).map({ "Series \($0)" })
        var indexLabels = Array(0..<values.first!.count).map({ "Index \($0)" })

        if settings.dataSet > 0 {
            values = generateNumbers(fromDataSampleWithIndex: settings.dataSet - 1) ?? values
            seriesLabels = parseSeriesLabels(fromDataSampleWithIndex: settings.dataSet - 1) ?? seriesLabels
            indexLabels = parseIndexLabels(fromDataSampleWithIndex: settings.dataSet - 1) ?? indexLabels
        }

        let dataSeries = ARDataSeries(withValues: values)
        if settings.showLabels {
            dataSeries.seriesLabels = seriesLabels
            dataSeries.indexLabels = indexLabels
            dataSeries.spaceForIndexLabels = 0.2
            dataSeries.spaceForIndexLabels = 0.2
        } else {
            dataSeries.spaceForIndexLabels = 0.0
            dataSeries.spaceForIndexLabels = 0.0
        }
        dataSeries.barColors = arkitColors
        dataSeries.barOpacity = settings.barOpacity

        let barChart = ARBarChart()
        barChart.dataSource = dataSeries
        barChart.delegate = dataSeries
        barChart.animationType = settings.animationType
        barChart.size = SCNVector3(settings.graphWidth, settings.graphHeight, settings.graphLength)
        barChart.draw()

        if let eularAngles = sceneView.session.currentFrame?.camera.eulerAngles {
            barChart.eulerAngles.y = eularAngles.y
        }

        barChart.scale = SCNVector3(0.1, 0.1, 0.1)

        return barChart
    }

    func createTextNodeParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.

        let textDepth: Float = 0.01

        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y

        // TEXT
        let textGeomytry = SCNText(string: text, extrusionDepth: CGFloat(textDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        textGeomytry.font = font
        textGeomytry.alignmentMode = kCAAlignmentCenter
        textGeomytry.firstMaterial?.diffuse.contents = UIColor.orange
        textGeomytry.firstMaterial?.specular.contents = UIColor.white
        textGeomytry.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        textGeomytry.chamferRadius = CGFloat(textDepth)

        let (minBound, maxBound) = textGeomytry.boundingBox
        let textNode = SCNNode(geometry: textGeomytry)
        // Centre Node - to Centre-Bottom point
        textNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, textDepth/2)
        textNode.scale = SCNVector3Make(0.2, 0.2, 0.2)

        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)

        // BUBBLE PARENT NODE
        let textNodeParent = SCNNode()
        textNodeParent.addChildNode(textNode)
        textNodeParent.addChildNode(sphereNode)
        textNodeParent.constraints = [billboardConstraint]

        return textNodeParent
    }

    // MARK: - Gestures
    private func addGestures() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        view.addGestureRecognizer(longPressRecognizer)

        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        view.addGestureRecognizer(rotationGestureRecognizer)

        let twoTouchesSingleTapGesture = UITapGestureRecognizer(target: self, action:#selector(handleTwoTouchesSingleTap(_:)))
        twoTouchesSingleTapGesture.numberOfTapsRequired = 1
        twoTouchesSingleTapGesture.numberOfTouchesRequired = 2
        view.addGestureRecognizer(twoTouchesSingleTapGesture)

        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        view.addGestureRecognizer(singleTapGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)

        singleTapGesture.require(toFail: doubleTapGesture)
    }

    // single tap on empty space to add chart beside the recognized fruit located at the center of the screen
    @objc func handleSingleTap(_ singleTap: UITapGestureRecognizer) {
        let location = singleTap.location(in: view)

        if let hitNode = sceneView.hitTest(location, options: nil).first?.node,
            hitNode is ARBarChartBar || hitNode is ARChartLabel || hitNode.parent is ARChartLabel,
            let barChart = hitNode.parent as? ARBarChart {
            barChart.unhighlight()
        } else {
            tryToAddObjectChart(for: self.latestPrediction, and: self.latestPredictionConfidence)

            if showRecognizedResultNearby {
                recognizedResultNode?.removeFromParentNode()

                let worldCoord = getCenterPointWorldPosition()
                // Create 3D Text and bubble indicating position
                let node: SCNNode = createTextNodeParentNode(latestPrediction)
                sceneView.scene.rootNode.addChildNode(node)
                node.position = worldCoord
                recognizedResultNode = node
            }
        }
    }

    @objc func handleTwoTouchesSingleTap(_ twoTouchesSingleTap: UITapGestureRecognizer) {
        let location1 = twoTouchesSingleTap.location(ofTouch: 0, in: view)
        let location2 = twoTouchesSingleTap.location(ofTouch: 1, in: view)
        let location = CGPoint(x: (location1.x + location2.x) / 2, y: (location1.y + location2.y) / 2)
        let worldPosition = getWorldPosition(from: location)
        tryToAddARChartNode(at: worldPosition)
    }

    @objc func handleDoubleTap(_ doubleTap: UITapGestureRecognizer) {
        arChartNode?.removeFromParentNode()

        recognizedResultNode?.removeFromParentNode()

        for node in allChartNodesDic.values {
            node.removeFromParentNode()
        }
    }

    private var startingRotation: Float = 0.0
    private var nodeForRotation: SCNNode?

    // rotate ARBarChart, only when the two touches' center is on ARBarChart
    @objc func handleRotation(_ rotateGesture: UIRotationGestureRecognizer) {
        if rotateGesture.state == .began {
            let pos1 = rotateGesture.location(ofTouch: 0, in: sceneView)
            let pos2 = rotateGesture.location(ofTouch: 1, in: sceneView)
            let touchesCenter = CGPoint(x: (pos1.x + pos2.x) / 2, y: (pos1.y + pos2.y) / 2)
            if let hitNode = sceneView.hitTest(touchesCenter, options: nil).first?.node {
                if hitNode is ARBarChartBar || hitNode is ARChartLabel || hitNode.parent is ARChartLabel {
                    if let barChart = hitNode.parent as? ARBarChart {
                        nodeForRotation = barChart
                        startingRotation = barChart.eulerAngles.y
                    }
                }
            }
        } else if rotateGesture.state == .changed {
            if let nodeForRotation = nodeForRotation {
                nodeForRotation.eulerAngles.y = startingRotation - Float(rotateGesture.rotation * 5)
            }
        } else if rotateGesture.state == .ended {
            startingRotation = 0.0
            nodeForRotation = nil
        }
    }

    // long press on ARBarChart series label or index label to see only the related data
    @objc func handleLongPress(_ longPressGesture: UITapGestureRecognizer) {
        guard longPressGesture.state == .began else { return }
        var labelToHighlight: ARChartLabel?

        let animationStyle = settings.longPressAnimationType
        let animationDuration = 0.3
        let longPressLocation = longPressGesture.location(in: sceneView)
        let selectedNode = sceneView.hitTest(longPressLocation, options: nil).first?.node
        if let barNode = selectedNode as? ARBarChartBar,
            let barChart = barNode.parent as? ARBarChart {
            barChart.highlightBar(atIndex: barNode.index, forSeries: barNode.series, withAnimationStyle: animationStyle, withAnimationDuration: animationDuration)
        } else if let labelNode = selectedNode as? ARChartLabel {
            // Detect long press on label text
            labelToHighlight = labelNode
        } else if let labelNode = selectedNode?.parent as? ARChartLabel {
            // Detect long press on label background
            labelToHighlight = labelNode
        }

        if let labelNode = labelToHighlight,
            let barChart = labelNode.parent as? ARBarChart {
            switch labelNode.type {
            case .index:
                barChart.highlightIndex(labelNode.id, withAnimationStyle: animationStyle, withAnimationDuration: animationDuration)
            case .series:
                barChart.highlightSeries(labelNode.id, withAnimationStyle: animationStyle, withAnimationDuration: animationDuration)
            }
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
