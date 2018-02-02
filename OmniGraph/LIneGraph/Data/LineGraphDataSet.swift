//
//  LineGraphDataSet.swift
//  OmniGraph
//
//  Created by Saurabh shrivastava on 1/28/18.
//  Copyright © 2018 Saurabh shrivastava. All rights reserved.
//

import UIKit

class LineGraphDataPlot: NSObject {
    
    var plotTitle = ""
    var primaryDataSets:[LineGraphDataSet]
    var secondaryDataSets:[LineGraphDataSet]?
    
    init(title:String, primaryDataSet:[LineGraphDataSet], secondaryDataSet:[LineGraphDataSet]?)
    {
        self.plotTitle       = title
        self.primaryDataSets  = primaryDataSet
        self.secondaryDataSets = secondaryDataSet
    }
}

/**
 The LineGraphDataSet is what drives a single line on the LineGraphView
 It contains one set of datapoints and the title/color attributes associated with it
 */
class LineGraphDataSet: NSObject {
    
    var dataTitle:String
    var dataPoints:[LineGraphDataPoint]
    var color:UIColor
    
    init(title:String, dataPoints:[LineGraphDataPoint], color:UIColor)
    {
        dataTitle       = title
        self.dataPoints = dataPoints
        self.color      = color
    }
    
    /**
     Responsible for getting the min and max values for a datasets
     
     - returns: A tuple of min max values
     */
    func maxMinElement()->(minValue:LineGraphDataPoint, maxValue:LineGraphDataPoint) {
        
        var maxValue = dataPoints.first!
        var minValue = dataPoints.last!
        
        if maxValue.lineGraphValue() < minValue.lineGraphValue() {
            maxValue = minValue
            minValue = dataPoints.first!
        }
        
        for i in 0..<(dataPoints.count/2)
        {
            let valueA = dataPoints[i*2]
            let valueB = dataPoints[i*2+1]
            
            if valueA.lineGraphValue() <= valueB.lineGraphValue() {
                
                if (valueA.lineGraphValue() < minValue.lineGraphValue()) {
                    minValue = valueA
                }
                
                if (valueB.lineGraphValue() > maxValue.lineGraphValue()) {
                    maxValue = valueB
                }
            }
            else {
                
                if valueA.lineGraphValue() > maxValue.lineGraphValue() {
                    maxValue = valueA
                }
                
                if valueB.lineGraphValue() < minValue.lineGraphValue() {
                    minValue = valueB
                }
            }
        }
        return (minValue, maxValue)
    }
    
}

