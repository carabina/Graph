//
//  ViewController.swift
//  OmniGraph
//
//  Created by Saurabh shrivastava on 1/28/18.
//  Copyright © 2018 Saurabh shrivastava. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var lineGraph: LineGraphView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let primaryDataSet = LineGraphDataSet(title: "Reach",
                                             dataPoints: [LineGraphTestData(title: "Tier1", value: 365),
                                                          LineGraphTestData(title: "Tier2", value: 365),
                                                          LineGraphTestData(title: "Tier3", value: 385),
                                                          LineGraphTestData(title: "Tier4", value: 385),
                                                          LineGraphTestData(title: "Tier5", value: 405)],
                                             color: UIColor.white)
        
        let secondaryDataSet = LineGraphDataSet(title: "Frequency",
                                               dataPoints: [LineGraphTestData(title: "Tier1", value: 6),
                                                            LineGraphTestData(title: "Tier2", value: 4),
                                                            LineGraphTestData(title: "Tier3", value: 6),
                                                            LineGraphTestData(title: "Tier4", value: 4),
                                                            LineGraphTestData(title: "Tier5", value: 2)],
                                               color: UIColor.blue)
        
        let dataPlot = LineGraphDataPlot(title: "Frequency vs Reach", primaryDataSet: primaryDataSet, secondaryDataSet:secondaryDataSet)
        lineGraph.dataPlots = [dataPlot]
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


class LineGraphTestData: NSObject, LineGraphDataPoint {
    
    var title:String
    var value:CGFloat
    
    init(title:String, value:CGFloat)
    {
        self.title = title
        self.value = value
    }
    
    // MARK: - LineGraphDataPoint Methods
    
    func lineGraphTitle() -> String {
        return self.title
    }
    
    func lineGraphValue() -> CGFloat {
        return self.value
    }
    
    
}


