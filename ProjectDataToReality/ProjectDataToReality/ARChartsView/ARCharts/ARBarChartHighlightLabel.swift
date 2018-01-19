//
//  ARBarChartHighlightLabel.swift
//  CoreML in ARKit
//
//  Created by Hongchao on 12/26/17.
//  Copyright © 2017 CompanyName. All rights reserved.
//

import Foundation
import SceneKit

class ARBarchartHighlightLabel: SCNNode {
    var text: String = "..."

    init(text: String) {
        super.init()
        self.text = text
        createContent()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createContent() {

        let bubbleDepth: Double = 0.01
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y

        // BUBBLE-TEXT
        let textGeometry = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        textGeometry.font = font
        textGeometry.alignmentMode = kCAAlignmentCenter
        textGeometry.firstMaterial?.diffuse.contents = UIColor.orange
        textGeometry.firstMaterial?.specular.contents = UIColor.white
        textGeometry.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        textGeometry.chamferRadius = CGFloat(bubbleDepth)

        // BUBBLE NODE
        let (minBound, maxBound) = textGeometry.boundingBox
        let bubbleNode = SCNNode(geometry: textGeometry)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, Float(bubbleDepth/2))
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.1, 0.1, 0.1)

        self.addChildNode(bubbleNode)
        self.constraints = [billboardConstraint]

    }

}
