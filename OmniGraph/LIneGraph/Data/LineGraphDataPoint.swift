//
//  LineGraphDataPoint.swift
//  OmniGraph
//
//  Created by Saurabh shrivastava on 1/28/18.
//  Copyright © 2018 Saurabh shrivastava. All rights reserved.
//

import UIKit

@objc protocol LineGraphDataPoint {
    
    /**
     Responsible for getting the value associated with this data point
     
     - returns: The CGFloat representation of the data point
     */
    func lineGraphValue()->CGFloat
    
    /**
     Responsible for getting the title associated with this data point
     
     - returns: The string representation of the data point
     */
    func lineGraphTitle()->String
    
}

/// Generic data object that is designed to feed the GraphDataPoint data source
class LineGraphData <LineGraphDataPoint> {
    
    private let title:String
    private let value:CGFloat
    
    init(title:String, value:CGFloat)
    {
        self.title = title;
        self.value = value;
    }
    
    func lineGraphTitle() -> String {
        return self.title
    }
    
    func lineGraphValue() -> CGFloat {
        return self.value
    }
}
