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
        
        let secondaryDataSet = LineGraphDataSet(title: "Average Reach",
                                             dataPoints: [LineGraphTestData(title: "Tier1", value: 31.7),
                                                          LineGraphTestData(title: "Tier2", value: 40.0),
                                                          LineGraphTestData(title: "Tier3", value: 43.7)],
                                             color: UIColor.orange)
        
        let primaryDataSet = LineGraphDataSet(title: "Frequency by segment",
                                               dataPoints: [LineGraphTestData(title: "Tier1", value: 4.2),
                                                            LineGraphTestData(title: "Tier2", value: 1.8),
                                                            LineGraphTestData(title: "Tier3", value: 1.5)],
                                                color: UIColor.init(red: 112.0/255.0, green: 185.0/255.0, blue: 228.0/255.0, alpha: 1.0))
        
        let dataPlot = LineGraphDataPlot(title: "Average Reach and Frequency by Segment", primaryDataSet: primaryDataSet, secondaryDataSet:secondaryDataSet)
//        lineGraph.dataPlots = [dataPlot]
        
//        let time = DispatchTime.now() + 1.0

        
            self.lineGraph.finishLoading([dataPlot])

        lineGraph.layer.cornerRadius   = 6.0
        lineGraph.clipsToBounds        = true
        
        
        
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


