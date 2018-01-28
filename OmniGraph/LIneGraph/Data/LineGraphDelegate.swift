//
//  LineGraphDelegate.swift
//  OmniGraph
//
//  Created by Saurabh shrivastava on 1/28/18.
//  Copyright © 2018 Saurabh shrivastava. All rights reserved.
//

import UIKit
import Foundation

@objc protocol LineGraphDelegate
{
    /**
     Resposnible for letting the delegate know that there is a new average value calculated
     
     - parameter graphView:        the currently active graph view
     - parameter graphDataAverage: the cgfloat value of the average
     - parameter dataSet:          the LineGraphDataSet whose average was just calculated
     */
    @objc optional func averageCalculated(_ graphView:LineGraphView, graphDataAverage:CGFloat, dataSet:LineGraphDataSet)
    
    /**
     Responsible for letting the delegate know that the user wants this graph to be presented in full screen mode
     
     - parameter graphView: The currently active LineGraphView
     */
    @objc optional func showFullScreenGraph(_ graphView:LineGraphView)
}

