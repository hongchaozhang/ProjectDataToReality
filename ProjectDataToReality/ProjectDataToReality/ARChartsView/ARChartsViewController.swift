//
//  ARChartsViewController.swift
//  ARCharts
//
//  Created by Bobo on 7/5/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

import SceneKit
import UIKit


class ARChartsViewController: UIViewController, SettingsDelegate, UIPopoverPresentationControllerDelegate {

    var settingsButton: UIButton!
    var sceneView = SCNView()
    
    var barChart: ARBarChart?

    private let arKitColors = [
        UIColor(red: 238.0 / 255.0, green: 109.0 / 255.0, blue: 150.0 / 255.0, alpha: 1.0),
        UIColor(red: 70.0  / 255.0, green: 150.0 / 255.0, blue: 150.0 / 255.0, alpha: 1.0),
        UIColor(red: 134.0 / 255.0, green: 218.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0),
        UIColor(red: 237.0 / 255.0, green: 231.0 / 255.0, blue: 254.0 / 255.0, alpha: 1.0),
        UIColor(red: 0.0   / 255.0, green: 110.0 / 255.0, blue: 235.0 / 255.0, alpha: 1.0),
        UIColor(red: 193.0 / 255.0, green: 193.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0),
        UIColor(red: 84.0  / 255.0, green: 204.0 / 255.0, blue: 254.0 / 255.0, alpha: 1.0)
    ]
    
    var screenCenter: CGPoint?
    var settings = Settings()
    var dataSeries: ARDataSeries?
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.scene = SCNScene()
        sceneView.showsStatistics = false
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = true
        sceneView.contentScaleFactor = 1.0
        sceneView.preferredFramesPerSecond = 60
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }

        settingsButton.layer.cornerRadius = 5.0
        settingsButton.clipsToBounds = true

        setupRotationGesture()
        setupHighlightGesture()

        addLightSource(ofType: .omni)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBarChart(at: SCNVector3(x: 0, y: 0, z: 0))
        screenCenter = self.sceneView.bounds.mid
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK - Setups

    
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
        dataSeries?.barColors = arKitColors
        dataSeries?.barOpacity = settings.barOpacity
        
        barChart = ARBarChart()
        if let barChart = barChart {
            barChart.dataSource = dataSeries
            barChart.delegate = dataSeries
            setupGraph()
            barChart.position = position
            barChart.draw()
            sceneView.scene?.rootNode.addChildNode(barChart)
        }
    }
    
    private func addLightSource(ofType type: SCNLight.LightType, at position: SCNVector3? = nil) {
        let light = SCNLight()
        light.color = UIColor.white
        light.type = type
        light.intensity = 1500 // Default SCNLight intensity is 1000
        
        let lightNode = SCNNode()
        lightNode.light = light
        if let lightPosition = position {
            // Fix the light source in one location
            lightNode.position = lightPosition
            self.sceneView.scene?.rootNode.addChildNode(lightNode)
        } else {
            // Make the light source follow the camera position
            self.sceneView.pointOfView?.addChildNode(lightNode)
        }
    }
    
    private func setupRotationGesture() {
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        self.view.addGestureRecognizer(rotationGestureRecognizer)
    }
    
    private func setupHighlightGesture() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.view.addGestureRecognizer(longPressRecognizer)
    }

    
    // MARK: - Actions
    
    private var startingRotation: Float = 0.0
    
    @objc func handleRotation(rotationGestureRecognizer: UIRotationGestureRecognizer) {
        guard let barChart = barChart,
            let pointOfView = sceneView.pointOfView,
            sceneView.isNode(barChart, insideFrustumOf: pointOfView) == true else {
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
        let longPressLocation = gestureRecognizer.location(in: self.view)
        let selectedNode = self.sceneView.hitTest(longPressLocation, options: nil).first?.node
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
        self.view.addGestureRecognizer(tapToUnhighlight)
    }
    
    @objc func handleTapToUnhighlight(_ gestureRecognizer: UITapGestureRecognizer) {
        barChart?.unhighlight()
        self.view.removeGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: - Helper Functions
    
    var dragOnInfinitePlanesEnabled = false
    
    private func setupGraph() {
        barChart?.animationType = settings.animationType
        barChart?.size = SCNVector3(settings.graphWidth, settings.graphHeight, settings.graphLength)
    }
    
    // MARK: Navigation
    
    func handleTapOnSettingsButton(_ sender: UIButton) {
        guard let settingsNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "settingsPopoverNavigationControllerId") as? UINavigationController,
            let settingsViewController = settingsNavigationController.viewControllers.first as? SettingsTableViewController else {
                return
        }
        
        settingsNavigationController.modalPresentationStyle = .popover
        settingsNavigationController.popoverPresentationController?.permittedArrowDirections = .any
        settingsNavigationController.popoverPresentationController?.sourceView = sender
        settingsNavigationController.popoverPresentationController?.sourceRect = sender.bounds
        
        settingsViewController.delegate = self
        settingsViewController.settings = self.settings
        
        DispatchQueue.main.async {
            self.present(settingsNavigationController, animated: true, completion: nil)
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: SettingsDelegate
    
    func didUpdateSettings(_ settings: Settings) {
        self.settings = settings
        barChart?.removeFromParentNode()
        barChart = nil
    }
    
    
}
