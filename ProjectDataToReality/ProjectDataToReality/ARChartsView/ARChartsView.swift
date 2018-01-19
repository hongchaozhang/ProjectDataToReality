//
//  ARChartsView.swift
//  SwiftPlayground
//
//  Created by Hongchao on 12/16/17.
//  Copyright © 2017 Hongchao Zhang. All rights reserved.
//

import SceneKit

class ARChartsView: SCNView {
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var cubeNode: SCNNode!
    var planeNode: SCNNode!

    var barChart: ARBarChart?
    var settings = Settings()
    var dataSeries: ARDataSeries?

    override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 1.0

        setupScene()
        addGestures()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupScene() {

        let scene = SCNScene()
        self.scene = scene

        func addCube() {
            let cubeGeometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
            cubeNode = SCNNode(geometry: cubeGeometry)

            let redMaterial = SCNMaterial()
            redMaterial.diffuse.contents = UIColor.red
            cubeGeometry.materials = [redMaterial]

            scene.rootNode.addChildNode(cubeNode)
        }

        func addPlane() {
            let planeGeometry = SCNPlane(width: 50.0, height: 50.0)
            planeNode = SCNNode(geometry: planeGeometry)
            planeNode.eulerAngles = SCNVector3(x: GLKMathDegreesToRadians(-90), y: 0, z: 0)
            planeNode.position = SCNVector3(x: 0, y: -0.5, z: 0)

            let greenMaterial = SCNMaterial()
            greenMaterial.diffuse.contents = UIColor.green
            planeGeometry.materials = [greenMaterial]

            scene.rootNode.addChildNode(planeNode)
        }

        func addCamera() {
            let camera = SCNCamera()
            cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(x: -3.0, y: 3.0, z: 3.0)

            let constraint = SCNLookAtConstraint(target: barChart)
            constraint.isGimbalLockEnabled = true
            cameraNode.constraints = [constraint]

            scene.rootNode.addChildNode(cameraNode)
        }

        func addLight() {
            let ambientLight = SCNLight()
            ambientLight.type = SCNLight.LightType.ambient
            ambientLight.color = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            cameraNode.light = ambientLight

            let light = SCNLight()
            light.type = SCNLight.LightType.omni
            let lightNode = SCNNode()
            lightNode.light = light
            lightNode.position = SCNVector3(x: 1.5, y: 1.5, z: 1.5)

//            let light = SCNLight()
//            light.type = SCNLight.LightType.spot
//            light.spotInnerAngle = 30.0
//            light.spotOuterAngle = 80.0
//            light.castsShadow = true
//            lightNode = SCNNode()
//            lightNode.light = light
//            lightNode.position = SCNVector3(x: 1.5, y: 1.5, z: 1.5)

            let constraint = SCNLookAtConstraint(target: barChart)
            constraint.isGimbalLockEnabled = true
            lightNode.constraints = [constraint]

            scene.rootNode.addChildNode(lightNode)
        }

        addBarChart(at: SCNVector3(x: 0, y: 0, z: 0))
//        addCube()
//        addPlane()
        addCamera()
        addLight()

    }

    private func addBarChart(at position: SCNVector3) {
        if barChart != nil {
            barChart?.removeFromParentNode()
            barChart = nil
        }

        var values = generateRandomNumbers(withRange: 0..<50, numberOfRows: settings.numberOfSeries, numberOfColumns: settings.numberOfIndices)
        var seriesLabels = Array(0..<values.count).map({ "Series \($0)" })
        var indexLabels = Array(0..<values.first!.count).map({ "Index \($0)" })


        if settings.dataSet > 0 {
            values = generateNumbers(fromDataSampleWithIndex: settings.dataSet - 1) ?? values
            seriesLabels = parseSeriesLabels(fromDataSampleWithIndex: settings.dataSet - 1) ?? seriesLabels
            indexLabels = parseIndexLabels(fromDataSampleWithIndex: settings.dataSet - 1) ?? indexLabels
        }

        dataSeries = ARDataSeries(withValues: values)
        if settings.showLabels {
            dataSeries?.seriesLabels = seriesLabels
            dataSeries?.indexLabels = indexLabels
            dataSeries?.spaceForIndexLabels = 0.2
            dataSeries?.spaceForIndexLabels = 0.2
        } else {
            dataSeries?.spaceForIndexLabels = 0.0
            dataSeries?.spaceForIndexLabels = 0.0
        }
        dataSeries?.barColors = arkitColors
        dataSeries?.barOpacity = settings.barOpacity

        barChart = ARBarChart()
        if let barChart = barChart {
            barChart.dataSource = dataSeries
            barChart.delegate = dataSeries
            setupGraph()
            barChart.position = position
            barChart.draw()
            scene?.rootNode.addChildNode(barChart)
        }
    }

    private func setupGraph() {
        barChart?.animationType = settings.animationType
        barChart?.size = SCNVector3(settings.graphWidth, settings.graphHeight, settings.graphLength)
    }

    private func addGestures() {
        func setupRotationGesture() {
            let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
            self.addGestureRecognizer(rotationGestureRecognizer)
        }

        func setupHighlightGesture() {
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            self.addGestureRecognizer(longPressRecognizer)
        }

        setupRotationGesture()
        setupHighlightGesture()
    }

    // MARK: - Actions
    private var startingRotation: Float = 0.0

    @objc func handleRotation(rotationGestureRecognizer: UIRotationGestureRecognizer) {
        guard let barChart = barChart,
            let pointOfView = self.pointOfView,
            self.isNode(barChart, insideFrustumOf: pointOfView) == true else {
                return
        }

        if rotationGestureRecognizer.state == .began {
            startingRotation = barChart.eulerAngles.y
        } else if rotationGestureRecognizer.state == .changed {
            self.barChart?.eulerAngles.y = startingRotation - Float(rotationGestureRecognizer.rotation)
        }
    }

    @objc func handleLongPress(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        var labelToHighlight: ARChartLabel?

        let animationStyle = settings.longPressAnimationType
        let animationDuration = 0.3
        let longPressLocation = gestureRecognizer.location(in: self)
        let selectedNode = self.hitTest(longPressLocation, options: nil).first?.node
        if let barNode = selectedNode as? ARBarChartBar {
            barChart?.highlightBar(atIndex: barNode.index, forSeries: barNode.series, withAnimationStyle: animationStyle, withAnimationDuration: animationDuration)
        } else if let labelNode = selectedNode as? ARChartLabel {
            // Detect long press on label text
            labelToHighlight = labelNode
        } else if let labelNode = selectedNode?.parent as? ARChartLabel {
            // Detect long press on label background
            labelToHighlight = labelNode
        }

        if let labelNode = labelToHighlight {
            switch labelNode.type {
            case .index:
                barChart?.highlightIndex(labelNode.id, withAnimationStyle: animationStyle, withAnimationDuration: animationDuration)
            case .series:
                barChart?.highlightSeries(labelNode.id, withAnimationStyle: animationStyle, withAnimationDuration: animationDuration)
            }
        }

        let tapToUnhighlight = UITapGestureRecognizer(target: self, action: #selector(handleTapToUnhighlight(_:)))
        self.addGestureRecognizer(tapToUnhighlight)
    }

    @objc func handleTapToUnhighlight(_ gestureRecognizer: UITapGestureRecognizer) {
        barChart?.unhighlight()
        self.removeGestureRecognizer(gestureRecognizer)
    }

}

extension ARChartsView: SettingsDelegate {
    func didUpdateSettings(_ settings: Settings) {
        self.settings = settings
        barChart?.removeFromParentNode()
        barChart = nil
    }
}
