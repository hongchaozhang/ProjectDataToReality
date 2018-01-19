//
//  ARBarChartBar.swift
//  ARCharts
//
//  Created by Christopher Chute on 7/25/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

import SceneKit
import UIKit

class ARBarChartBar: SCNNode {
    
    let series: Int
    let index: Int
    let value: Double
    let finalHeight: Float
    let finalOpacity: Float
    
    override var description: String {
        return "ARBarNode(series: \(series), index: \(index), value: \(value))"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(geometry: SCNBox, index: Int, series: Int, value: Double, finalHeight: Float, finalOpacity: Float) {
        self.series = series
        self.index = index
        self.value = value
        self.finalHeight = finalHeight
        self.finalOpacity = finalOpacity
        
        super.init()
        self.geometry = geometry
    }
    
}
