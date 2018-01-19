//
//  Settings.swift
//  ARChartsSampleApp
//
//  Created by Boris Emorine on 7/26/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

import Foundation

struct Settings {
    
    var animationType: ARChartPresenter.AnimationType = .fade
    var longPressAnimationType : ARChartHighlighter.AnimationStyle = .shrink
    var barOpacity: Float = 0.8
    var showLabels = true
    var numberOfSeries = 4
    var numberOfIndices = 4
    var graphWidth: Float = 1
    var graphHeight: Float = 1
    var graphLength: Float = 1
    var dataSet: Int = 0
    
    public func index(forEntranceAnimationType animationType: ARChartPresenter.AnimationType?) -> Int {
        guard let animationType = animationType else {
            return 0
        }
        
        switch animationType {
        case .fade:
            return 0
        case .progressiveFade:
            return 1
        case .grow:
            return 2
        case .progressiveGrow:
            return 3
        }
    }
    
    public func entranceAnimationType(forIndex index: Int) -> ARChartPresenter.AnimationType? {
        switch index {
        case 0:
            return .fade
        case 1:
            return .progressiveFade
        case 2:
            return .grow
        case 3:
            return .progressiveGrow
        default:
            return .fade
        }
    }
    
    public func index(forLongPressAnimationType animationType: ARChartHighlighter.AnimationStyle?) -> Int {
        guard let animationType = animationType else {
            return 0
        }
        switch animationType {
        case .shrink:
            return 0
        case .fade:
            return 1
        }
    }
    
    public func longPressAnimationType(forIndex index: Int) -> ARChartHighlighter.AnimationStyle? {
        switch index {
        case 0:
            return .shrink
        case 1:
            return .fade
        default:
            return .shrink
        }
    }
}
