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
        
        let primaryDataSet = LineGraphDataSet(title: "2017-18",
                                             dataPoints: [LineGraphTestData(title: "Tier1", value: 31.7),
                                                          LineGraphTestData(title: "Tier2", value: 40.0),
                                                          LineGraphTestData(title: "Tier3", value: 43.7)],
                                             color: UIColor.orange)
        let secondPrimaryDataSet = LineGraphDataSet(title: "Q2",
                                              dataPoints: [LineGraphTestData(title: "Tier1", value: 50),
                                                           LineGraphTestData(title: "Tier2", value: 100),
                                                           LineGraphTestData(title: "Tier3", value: 21)],
                                              color: UIColor.cyan)

//        LineGraphTestData(title: "Tier3", value: 1.5)
        
        let secondaryDataSet = LineGraphDataSet(title: "Frequency",
                                               dataPoints: [LineGraphTestData(title: "Tier1", value: 4.2),
                                                            LineGraphTestData(title: "Tier2", value: 1.8),
                                                            LineGraphTestData(title: "Tier3", value: 2.0)],
                                                color:UIColor.black)
        
        let thirdDataSet = LineGraphDataSet(title: "Frequency",
                                                dataPoints: [LineGraphTestData(title: "Tier1", value: 15),
                                                             LineGraphTestData(title: "Tier2", value: 5),
                                                             LineGraphTestData(title: "Tier3", value: 6)],
                                                color: UIColor.init(red: 112.0/255.0, green: 185.0/255.0, blue: 228.0/255.0, alpha: 1.0))
        
        let fourthDataSet = LineGraphDataSet(title: "Frequency",
                                            dataPoints: [LineGraphTestData(title: "Tier1", value: 6),
                                                         LineGraphTestData(title: "Tier2", value: 2),
                                                         LineGraphTestData(title: "Tier2", value: 10)],
                                            color: UIColor.red)


        //[secondaryDataSet,thirdDataSet,fourthDataSet]
        let dataPlot = LineGraphDataPlot(title: "All", primaryDataSet: [primaryDataSet,secondPrimaryDataSet], secondaryDataSet:[secondaryDataSet,fourthDataSet])
        let frequencyPlot  = LineGraphDataPlot(title: "Frequency", primaryDataSet: [primaryDataSet], secondaryDataSet:nil)
        let reachPlot  = LineGraphDataPlot(title: "Reach", primaryDataSet: [secondaryDataSet,thirdDataSet], secondaryDataSet:nil)

        
        self.lineGraph.finishLoading([dataPlot,reachPlot,frequencyPlot],title: "Average Reach and Frequency by Segment")

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


