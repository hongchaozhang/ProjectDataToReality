//
//  ARDataSeries.swift
//  ARBarCharts
//
//  Created by Bobo on 7/16/17.
//  Copyright © 2017 Boris Emorine. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

/**
 * The `ARDataSeries` object is used as a convenience to easily create bar charts with `ARBarcharts`.
 * If more customization is desired, you should create your own object conforming to `ARBarChartDataSource` and `ARBarChartDelegate`.
 */
class ARDataSeries: ARBarChartDataSource, ARBarChartDelegate {
    
    private let values: [[Double]]
    
    /// Labels to use for the series (Z-axis).
    var seriesLabels: [String]? = nil
    
    /// Labels to use for the values at each index (X-axis).
    var indexLabels: [String]? = nil
    
    /// Colors to use for the bars, cycled through based on bar position.
    var barColors: [UIColor]? = nil
    
    /// Materials to use for the bars, cycled through based on bar position.
    /// If non-nil, `barMaterials` overrides `barColors` to style the bars.
    var barMaterials: [SCNMaterial]? = nil
    
    /// Chamfer radius to use for the bars.
    var chamferRadius: Float = 0.0
    
    /// Gap between series, expressed as a ratio of gap to bar width (Z-axis).
    var seriesGap: Float = 0.2
    
    /// Gap between indices, expressed as a ratio of gap to bar length (X-axis).
    var indexGap: Float = 0.2
    
    /// Space to allow for the series labels, expressed as a ratio of label space to graph width (Z-axis).
    var spaceForSeriesLabels: Float = 0.1
    
    /// Space to allow for the index labels, expressed as a ratio of label space to graph length (X-axis).
    var spaceForIndexLabels: Float = 0.6
    
    /// Opacity of each bar in the graph.
    var barOpacity: Float = 1.0
    
    
    // MARK - ARBarChartDataSource
    
    required init(withValues values: [[Double]]) {
        self.values = values
    }
    
    func numberOfSeries(in barChart: ARBarChart) -> Int {
        return values.count
    }
    
    func barChart(_ barChart: ARBarChart, numberOfValuesInSeries series: Int) -> Int {
        return values[series].count
    }
    
    func barChart(_ barChart: ARBarChart, valueAtIndex index: Int, forSeries series: Int) -> Double {
        return values[series][index]
    }
    
    func barChart(_ barChart: ARBarChart, labelForSeries series: Int) -> String? {
        let label = seriesLabels?[series]
        
        return label
    }
    
    func barChart(_ barChart: ARBarChart, labelForValuesAtIndex index: Int) -> String? {
        return indexLabels?[index]
    }

    func barChart(_ barChart: ARBarChart, labelNodeAtIndex index: Int, atSeries series: Int) -> ARBarchartHighlightLabel {
        let valueString = String(values[series][index])
        return ARBarchartHighlightLabel(text: valueString)
    }


    // MARK - ARBarChartDelegate

    private func getMinMaxValue() -> (Double, Double) {
        var minValue: Double = 1000000000
        var maxValue: Double = -1

        for row in values {
            for value in row {
                if minValue > value {
                    minValue = value
                }
                if maxValue < value {
                    maxValue = value
                }
            }
        }

        if minValue  < maxValue {
            return (minValue, maxValue)
        }

        return (0, 1)
    }

    
    func barChart(_ barChart: ARBarChart, colorForBarAtIndex index: Int, forSeries series: Int) -> UIColor {
        guard let barColors = barColors, barColors.count > 1 else {
            return UIColor.white
        }

        //        let minMaxValues = getMinMaxValue()
        //        let minValue = minMaxValues.0
        //        let maxValue = minMaxValues.1
        //        let range = maxValue - minValue
        //
        //        let startR: Double = 1.0
        //        let startG: Double = 0.0
        //        let startB: Double = 0.0
        //        let endR: Double = 0.0
        //        let endG: Double = 1.0
        //        let endB: Double = 0.0
        //
        //        let startRedGreat = startR > endR
        //        let redRange = abs(startR - endR)
        //        let startGreenGreat = startG > endG
        //        let greenRange = abs(startG - endG)
        //        let startBlueGreat = startB > endB
        //        let blueRange = abs(startB - endB)
        //
        //        let value = values[series][index]
        //        let ratio = (value - minValue) / range
        //
        //        let redValue = CGFloat(startRedGreat ? startR - ratio * redRange : startR + ratio * redRange)
        //        let greenValue = CGFloat(startGreenGreat ? startG - ratio * greenRange : startG + ratio * greenRange)
        //        let blueValue = CGFloat(startBlueGreat ? startB - ratio * blueRange : startB + ratio * blueRange)
        //
        //        let color = UIColor(red: redValue,
        //                            green: greenValue,
        //                            blue: blueValue,
        //                            alpha: 1.0)
        //
        //        return color

        //        return barColors[(series * values[series].count + index) % barColors.count]
        return barColors[series % barColors.count]
    }
    
    func barChart(_ barChart: ARBarChart, materialForBarAtIndex index: Int, forSeries series: Int) -> SCNMaterial {
        if let barMaterials = barMaterials {
            return barMaterials[(series * (values.first?.count ?? 0) + index) % barMaterials.count]
        }
        
        // If bar materials are not set, default to using colors
        let colorMaterial = SCNMaterial()
        colorMaterial.diffuse.contents = self.barChart(barChart, colorForBarAtIndex: index, forSeries: series)
        colorMaterial.specular.contents = UIColor.white
        return colorMaterial
    }
    
    func barChart(_ barChart: ARBarChart, gapSizeAfterSeries series: Int) -> Float {
        return seriesGap
    }
    
    func barChart(_ barChart: ARBarChart, gapSizeAfterIndex index: Int) -> Float {
        return indexGap
    }
    
    func barChart(_ barChart: ARBarChart, opacityForBarAtIndex index: Int, forSeries series: Int) -> Float {
        return barOpacity
    }
    
    func barChart(_ barChart: ARBarChart, chamferRadiusForBarAtIndex index: Int, forSeries series: Int) -> Float {
        return chamferRadius
    }
    
    func spaceForSeriesLabels(in barChart: ARBarChart) -> Float {
        return spaceForSeriesLabels
    }
    
    func spaceForIndexLabels(in barChart: ARBarChart) -> Float {
        return spaceForIndexLabels
    }
    
}
