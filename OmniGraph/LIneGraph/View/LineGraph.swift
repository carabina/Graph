//
//  LineGraph.swift
//  OmniGraph
//
//  Created by Saurabh shrivastava on 1/28/18.
//  Copyright © 2018 Saurabh shrivastava. All rights reserved.
//
import UIKit

extension NSString
{
    /**
     Responsible for returning a single precision representation of the provided CGFloat
     
     - parameter currentFloat: The CGFloat being represented
     - parameter trim:         A boolean flag that tells if you want to trim any trailing .0 or not
     
     - returns: a string that representation of the cgfloat in the parameters
     */
    static func singlePrecisionFloat(_ currentFloat:CGFloat, attemptToTrim trim:Bool)->String {
        
        let string = NSString(format: "%.1f", currentFloat)
        return (trim && string.contains(".0")) ? string.replacingOccurrences(of: ".0", with: "") : string as String
    }
    
}

@IBDesignable class LineGraphView: UIView {
    
    // Visual Configuration Objects
    var graphInsetFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
    @IBInspectable var startColor:UIColor = UIColor.lightGray//UIColor(red: 128.0/255.0, green: 182.0/255.0, blue: 248.0/255.0, alpha: 1.0)
    @IBInspectable var endColor:UIColor   = UIColor.darkGray
    
    //UIColor(red: 50.0/255.0, green: 118.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    // Loading Variables
    @IBInspectable var currentlyLoading    = false
    let loadingActivityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    let loadingDimView      = UIView(frame: CGRect.zero)
    
    // Graph Interaction Objects
    var delegate:LineGraphDelegate?;
    @IBInspectable var showTouchTitle  = true
    @IBInspectable var allowFullScreen = true
    var fullScreenButton:UIButton?
    
    // Main Title Objects
    @IBInspectable var titleAlignment     = NSTextAlignment.center
    var titleLabel:UILabel = UILabel()
    var mainTitleText      = NSAttributedString(string: "")
    var averageValueLabel  = UILabel()
    
    // Graph State Objects
    var dataPlots      = [LineGraphDataPlot]()
    var currentPlotIdx = 0
    var plotSegmentedController:UISegmentedControl?
    var isFullScreen   = false
    
    // MARK: - Initialize Methods
    
    /**
     Responsible for getting a new graph view
     
     - parameter frame:      The frame of the graph view
     - parameter dataPoints: The datapoints that will be used in creating this graph
     - parameter delegate:   The object that conforms to the delegate (optional)
     
     - returns: A newly initialized LineGraphView
     */
    static func newGraphView(_ frame: CGRect, dataPlots:[LineGraphDataPlot], delegate:LineGraphDelegate?)->LineGraphView
    {
        return LineGraphView(frame: frame, dataPlots: dataPlots, delegate: delegate)
    }
    
    static func newLoadingGraphView(_ frame:CGRect, delegate:LineGraphDelegate?)->LineGraphView
    {
        let graphView              = LineGraphView(frame: frame, dataPlots: [LineGraphDataPlot](), delegate: delegate)
        graphView.currentlyLoading = true
        
        return graphView
    }
    
    fileprivate init(frame: CGRect, dataPlots:[LineGraphDataPlot], delegate:LineGraphDelegate?) {
        
        super.init(frame: frame)
        self.dataPlots = dataPlots
        self.delegate  = delegate
        initializeSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.dataPlots = []
        initializeSubViews()
    }
    
    // Responsble for initializing all of the subviews associated with this graphview instance
    func initializeSubViews()
    {
        // Configure and add the title label
        if !subviews.contains(titleLabel) {
            titleLabel.font           = LineGraphView.regularFont()
            titleLabel.textColor      = UIColor.white
            titleLabel.textAlignment  = titleAlignment
            titleLabel.attributedText = mainTitleText
            addSubview(titleLabel)
        }
        
        // Configure and add the average label
//        if !subviews.contains(averageValueLabel) {
//            averageValueLabel.font          = LineGraphView.regularFont(12.0)
//            averageValueLabel.textColor     = UIColor.white
//            averageValueLabel.textAlignment = titleAlignment
//            averageValueLabel.text          = ""
//            insertSubview(averageValueLabel, belowSubview: titleLabel)
//        }
        
        if plotSegmentedController == nil && dataPlots.count > 1 {
            
            // Initialize, configure and add the plot switching segmented controller
            var plotTitles = [String]()
            for currentPlot in dataPlots {
                plotTitles.append(currentPlot.plotTitle)
            }
            plotSegmentedController            = UISegmentedControl(items: plotTitles)
            plotSegmentedController!.tintColor = UIColor.white
            plotSegmentedController!.setTitleTextAttributes([NSAttributedStringKey.font : LineGraphView.lightFont()], for: UIControlState())
            plotSegmentedController!.setTitleTextAttributes([NSAttributedStringKey.font : LineGraphView.boldFont()], for: .selected)
            plotSegmentedController!.addTarget(self, action: #selector(LineGraphView.activePlotValueChanged(_:)), for: .valueChanged)
            plotSegmentedController!.selectedSegmentIndex = 0
            addSubview(plotSegmentedController!)
        }
        
        if !subviews.contains(loadingDimView) {
            // Initialize all of the loading indicator objects
            loadingDimView.frame           = bounds
            loadingDimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            loadingDimView.isHidden          = true
            
            loadingActivityView.tintColor        = UIColor.white
            loadingActivityView.hidesWhenStopped = true
            loadingDimView.addSubview(loadingActivityView)
            addSubview(loadingDimView)
        }
        
        if (allowFullScreen && fullScreenButton == nil)
        {
            let fullScreenButtonSide:CGFloat = 15.0
            
            // Initialize the full screen button and functionality
            fullScreenButton            = UIButton(type: .custom)
            fullScreenButton!.tintColor = UIColor.white
            fullScreenButton!.frame     = CGRect(x: 15.0, y: 15.0, width: fullScreenButtonSide, height: fullScreenButtonSide)
            
            fullScreenButton!.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
            addSubview(fullScreenButton!)
        }
    }
    
    /**
     Responsible for copying all of the state attributes from one graph view to another
     
     - parameter idealGraph: The LineGraphView that you are copying the attribute values from
     */
    func copyGraphAttributes(_ idealGraph:LineGraphView)
    {
        titleAlignment   = idealGraph.titleAlignment
        showTouchTitle   = idealGraph.showTouchTitle
        currentlyLoading = idealGraph.currentlyLoading
        currentPlotIdx   = idealGraph.currentPlotIdx
    }
    
    
    // MARK: - View Layout Methods
    
    func finishLoading(_ dataPlots:[LineGraphDataPlot]) {
        self.dataPlots   = dataPlots
        currentlyLoading = false
        initializeSubViews()
        setNeedsDisplay()
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        let labelWidth             = bounds.width * 0.5
        let titleYPadding:CGFloat  = isFullScreen ? 15.0 : 5.0
        let labelHeight:CGFloat    = 20.0
        
        titleLabel.font          = isFullScreen ? LineGraphView.boldFont(18.0) : LineGraphView.boldFont()
        titleLabel.textAlignment = titleAlignment
        let xOrigin              = (titleAlignment == .center) ? (bounds.width*0.25) : max(graphInsetFrame.origin.x, 40.0)
        titleLabel.frame         = CGRect(x: xOrigin, y: titleYPadding, width: labelWidth, height: labelHeight)
        titleLabel.contentMode = .scaleAspectFill
        averageValueLabel.frame         = CGRect(x: xOrigin, y: titleLabel.frame.maxY, width: labelWidth, height: 16.0)
        averageValueLabel.textAlignment = titleAlignment
        
        loadingDimView.frame       = bounds
        loadingActivityView.center = CGPoint(x: loadingDimView.bounds.width/2.0, y: loadingDimView.bounds.height/2.0)
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        
        fullScreenButton?.isHidden = !allowFullScreen
        if currentPlotIdx < dataPlots.count
        {
            // Set up the title text
            // This is in draw rect becuase it needs to get reset everytime that the segmented controller value changes
            let titleFont = isFullScreen ? LineGraphView.regularFont(12.0) : LineGraphView.regularFont(15.0)
            if let secondaryData = dataPlots[currentPlotIdx].secondaryDataSet
            {
                let primaryDataSet = dataPlots[currentPlotIdx].primaryDataSet
                let titleAttributeText = NSMutableAttributedString(string: "\(primaryDataSet.dataTitle) vs \(secondaryData.dataTitle)",
                    attributes: [NSAttributedStringKey.font : titleFont,
                                 NSAttributedStringKey.foregroundColor : UIColor.white])
                titleAttributeText.addAttributes([NSAttributedStringKey.foregroundColor:UIColor.white], range: NSMakeRange(0, primaryDataSet.dataTitle.count))
                titleAttributeText.addAttributes([NSAttributedStringKey.foregroundColor:UIColor.white], range: NSMakeRange(primaryDataSet.dataTitle.count + 4, secondaryData.dataTitle.count))
                mainTitleText = titleAttributeText
            }
            else {
                mainTitleText = NSAttributedString(string: "\(dataPlots[currentPlotIdx].primaryDataSet.dataTitle)", attributes: [NSAttributedStringKey.font : titleFont, NSAttributedStringKey.foregroundColor : UIColor.white])
            }
        }
        else {
            mainTitleText = NSAttributedString(string: "")
        }
        titleLabel.attributedText = mainTitleText
        averageValueLabel.text    = ""
        
        // Calculate the boundaries
        graphInsetFrame.origin.y    = bounds.height * 0.25
        if dataPlots.count > 1 {
            graphInsetFrame.origin.y -= 20.0
        }
        
        graphInsetFrame.size.height = bounds.height - graphInsetFrame.origin.y*2.0
        if dataPlots.count > 1 {
            graphInsetFrame.size.height -= 40.0
        }
        graphInsetFrame.origin.x    = bounds.width  * 0.125
        graphInsetFrame.size.width  = bounds.width - (graphInsetFrame.origin.x * 2.0)
        let columnWidth:CGFloat     = (currentPlotIdx < dataPlots.count) ? (graphInsetFrame.width / max(1,(CGFloat(dataPlots[currentPlotIdx].primaryDataSet.dataPoints.count)) - 1.0)) : 0
        
        // Now that you have the inset bounds calculated you can layout the segmented controller to sit right underneath it
        if let segmentedController = plotSegmentedController {
            
            let yOffset = ((bounds.height - graphInsetFrame.maxY) / 2.0) - (segmentedController.bounds.height / 4.0)
            if !isFullScreen {
                segmentedController.frame = CGRect(x: 15.0, y: graphInsetFrame.maxY + yOffset, width: bounds.width - 30.0, height: segmentedController.frame.size.height)
            }
            else {
                segmentedController.frame = CGRect(x: graphInsetFrame.origin.x, y: graphInsetFrame.maxY + yOffset, width: graphInsetFrame.size.width, height: segmentedController.frame.size.height)
            }
        }
        
        // Draw the background gradient
        let context:CGContext?  = UIGraphicsGetCurrentContext()
        let colorRGB = CGColorSpaceCreateDeviceRGB()
        let gradiant = CGGradient(colorsSpace: colorRGB,
                                  colors: [startColor.cgColor, endColor.cgColor] as CFArray, locations: [0.0,1.0])
        context?.drawLinearGradient(gradiant!, start: CGPoint.zero, end: CGPoint(x: 0, y: self.bounds.height), options: .drawsBeforeStartLocation)
        
        // MARK: - column X|Y positioning closures
        
        let columnXPosition = {(dataPoints:[LineGraphDataPoint], xColumn:CGFloat)->CGFloat in
            return (dataPoints.count > 1) ? self.graphInsetFrame.origin.x + columnWidth*xColumn : self.bounds.width/2.0
        }
        
        let columnYPosition = {(graphValue:CGFloat, minValue:LineGraphDataPoint, maxValue:LineGraphDataPoint)->CGFloat in
            
            let normalizedCurrentValue = graphValue - minValue.lineGraphValue()
            let yPosition              = (self.graphInsetFrame.size.height + self.graphInsetFrame.origin.y) - ((normalizedCurrentValue/(maxValue.lineGraphValue() - minValue.lineGraphValue())) * self.graphInsetFrame.size.height)
            return yPosition.isNaN ? self.graphInsetFrame.origin.y + self.graphInsetFrame.size.height/2.0 : yPosition
        }
        
        // Draw the actual data plots
        loadingDimView.isHidden = true
        if currentPlotIdx < dataPlots.count && dataPlots[currentPlotIdx].primaryDataSet.dataPoints.count > 0
        {
            var dataSets = [self.dataPlots[currentPlotIdx].primaryDataSet];
            if let secondDataSet = self.dataPlots[currentPlotIdx].secondaryDataSet {
                dataSets.append(secondDataSet)
            }
            
            var index = -1
            for currentDataSet in dataSets
            {
                index += 1
                let minMaxValues = currentDataSet.maxMinElement()
                let maxValue     = minMaxValues.maxValue
                let minValue     = minMaxValues.minValue
                
                // Move to the start add the main graph plot
                let graphPath = UIBezierPath()
                graphPath.move(to: CGPoint(x: columnXPosition(currentDataSet.dataPoints, 0),
                                           y: columnYPosition(currentDataSet.dataPoints[0].lineGraphValue(), minValue, maxValue)))
                for i in 1..<currentDataSet.dataPoints.count
                {
                    graphPath.addLine(to: CGPoint(x: columnXPosition(currentDataSet.dataPoints, CGFloat(i)),
                                                  y: columnYPosition(currentDataSet.dataPoints[i].lineGraphValue(), minValue, maxValue)))
                }
                
                // Stroke the main graph plot
                currentDataSet.color.setStroke()
                graphPath.lineWidth = 3.0
                graphPath.stroke()
                context?.saveGState()
                
                
                // Cycle through all the points drawing the data circles
                context?.restoreGState()
                currentDataSet.color.setFill()
                currentDataSet.color.setStroke()
                var counter             = 0;
                var dataAverage:CGFloat = 0.0
                var dotRadius:CGFloat   = 0.0
                dotRadius = 4.0
                
                // Cycle through all of the datapoints and draw the dots
                for currentPt in currentDataSet.dataPoints
                {
                    let dotCenter = CGPoint(x: columnXPosition(currentDataSet.dataPoints, CGFloat(counter)) - dotRadius/2,
                                            y: columnYPosition(currentPt.lineGraphValue(), minValue, maxValue) -   dotRadius/2)
                    counter += 1
                    let graphDotPath = UIBezierPath(ovalIn: CGRect(origin: dotCenter, size: CGSize(width: dotRadius, height: dotRadius)))
                    graphDotPath.fill()
                    dataAverage += currentPt.lineGraphValue()
                }
                
                // Calculate the average, tell the delegate and update the UI components affected
                dataAverage /= CGFloat(currentDataSet.dataPoints.count)
                delegate?.averageCalculated?(self, graphDataAverage: dataAverage, dataSet: currentDataSet)
                
                // Draw the horizontal lines and the indicator lables
                let graphMidPtY   = graphInsetFrame.origin.y + graphInsetFrame.size.height/2.0
                let averageWeight = (maxValue.lineGraphValue() + minValue.lineGraphValue())/2.0
                var bgLinePoints  = [graphInsetFrame.origin.y+graphInsetFrame.size.height, graphMidPtY, graphInsetFrame.origin.y]
                var bgLabelValues:[NSString] = [NSString.singlePrecisionFloat(minValue.lineGraphValue(), attemptToTrim: true) as NSString,
                                                NSString.singlePrecisionFloat(averageWeight, attemptToTrim: true) as NSString,
                                                NSString.singlePrecisionFloat(maxValue.lineGraphValue(), attemptToTrim: true) as NSString]
                
                // Enter here if there are a lot of graph points and you could have more than just 2 lines
                if currentDataSet.dataPoints.count > 2
                {
                    bgLinePoints.insert(graphMidPtY + graphInsetFrame.size.height/4.0, at: 1)
                    bgLabelValues.insert(NSString.singlePrecisionFloat((averageWeight + minValue.lineGraphValue()) / 2.0, attemptToTrim: true) as NSString, at: 1)
                    
                    bgLinePoints.insert(graphMidPtY - graphInsetFrame.size.height/4.0, at: 3)
                    bgLabelValues.insert(NSString.singlePrecisionFloat((averageWeight + maxValue.lineGraphValue()) / 2.0, attemptToTrim: true) as NSString, at: 3)
                }
                
                // MARK: - Draw side markers
                let bgLinePath    = UIBezierPath()
                let bgLineWidth   = bounds.width-graphInsetFrame.origin.x
                counter           = 0
                for currentBGYPoint in bgLinePoints
                {
                    bgLinePath.move(to: CGPoint(x: graphInsetFrame.origin.x, y: currentBGYPoint))
                    bgLinePath.addLine(to: CGPoint(x: bgLineWidth, y: currentBGYPoint))
                    
                    let currentLabel  = UILabel()
                    currentLabel.text = bgLabelValues[counter] as String
                    counter += 1
                    currentLabel.textColor = UIColor.darkGray
                    currentLabel.font      = LineGraphView.lightFont()
                    currentLabel.sizeToFit()
                    
                    // Primary data points are drawn on the right margin, secondary on the left
                    let xOrigin = (index == 0) ? (bgLineWidth+10.0) : (graphInsetFrame.origin.x - (currentLabel.bounds.width))
                    currentLabel.drawText(in: CGRect(x: xOrigin, y: currentBGYPoint-10, width: bounds.width-(bgLineWidth + 5), height: 20))
                }
                
                UIColor(white: 1.0, alpha: 0.5).setStroke()
                bgLinePath.lineWidth = 1.0
                bgLinePath.stroke()
                
                // Draw the x axis labels
                var previousXAxisFrame  = CGRect.zero
                let xLabelWidth:CGFloat = 80.0
                let xLabelCount:Int     = min(currentDataSet.dataPoints.count, 6)
                if xLabelCount > 1 && index == 0 // Currently only draw the primary data plots x label
                {
                    for i in 0..<xLabelCount
                    {
                        let xIndex:Int       = min(Int((CGFloat(i)/CGFloat(xLabelCount-1)) * CGFloat(currentDataSet.dataPoints.count)), currentDataSet.dataPoints.count - 1)
                        let titleLabel       = UILabel()
                        titleLabel.textColor = UIColor.darkGray
                        titleLabel.font      = LineGraphView.boldFont()
                        titleLabel.text      = currentDataSet.dataPoints[xIndex].lineGraphTitle()
                        titleLabel.textAlignment = .center
                        
                        let xOrigin:CGFloat = columnXPosition(currentDataSet.dataPoints, CGFloat(xIndex)) - (xLabelWidth/2.0)
                        let yOrigin:CGFloat = graphInsetFrame.maxY + 10.0
                        
                        var currentXAxisFrame = CGRect(x: xOrigin, y: yOrigin, width: xLabelWidth, height: 20.0)
                        if previousXAxisFrame.intersects(currentXAxisFrame) {
                            currentXAxisFrame.origin.y += 13
                        }
                        previousXAxisFrame = currentXAxisFrame
                        titleLabel.drawText(in: currentXAxisFrame)
                    }
                }
            }
        }
        else
        {
            // Enter here if there are no qualifying data points
            let borderBezier = UIBezierPath()
            borderBezier.move(to: CGPoint(x: graphInsetFrame.origin.x, y: graphInsetFrame.origin.y))
            borderBezier.addLine(to: CGPoint(x: graphInsetFrame.origin.x, y: graphInsetFrame.origin.y + graphInsetFrame.size.height))
            borderBezier.addLine(to: CGPoint(x: bounds.width - graphInsetFrame.origin.x, y: graphInsetFrame.origin.y + graphInsetFrame.size.height))
            
            UIColor(white: 1.0, alpha: 0.5).setStroke()
            borderBezier.lineWidth = 1.0
            borderBezier.stroke()
            
            if !currentlyLoading {
                let noneLabel       = UILabel()
                noneLabel.text      = "No Data Available"
                noneLabel.textColor = UIColor.white
                noneLabel.font      = UIFont.systemFont(ofSize: 30.0)
                noneLabel.sizeToFit()
                noneLabel.drawText(in: CGRect(x: bounds.width / 2.0 - noneLabel.bounds.width / 2.0, y: bounds.height / 2.0 - noneLabel.bounds.height, width: noneLabel.bounds.width, height: noneLabel.bounds.height))
            }
            else {
                loadingActivityView.startAnimating()
                loadingDimView.isHidden = false
            }
        }
    }
    
    // MARK: - Data Plot Mutation Methods
    
    @objc func activePlotValueChanged(_ segmentedController:UISegmentedControl)
    {
        currentPlotIdx = segmentedController.selectedSegmentIndex
        setNeedsDisplay()
    }
    
    // MARK: - Touch Methods
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches, withEvent: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches, withEvent: event)
    }
    
    /// Responsible for reacting to the touch inside of the graph inset view - Updates the top label
    func handleTouch(_ touches: Set<UITouch>, withEvent event:UIEvent?) {
        
        if showTouchTitle {
            
            // If the touch point is in the drawn graph (or a little outside of it) handle it as a data touch
            let locationPoint = touches.first!.location(in: self)
            let touchArea     = graphInsetFrame.insetBy(dx: -10, dy: -10)
            if touchArea.contains(locationPoint)
            {
                let normalizedX      = locationPoint.x - touchArea.origin.x
                let insetPercentage  = normalizedX / touchArea.size.width
                let index            = Int(floor(CGFloat(dataPlots[currentPlotIdx].primaryDataSet.dataPoints.count) * insetPercentage))
                let dataPointTouched = dataPlots[currentPlotIdx].primaryDataSet.dataPoints[index]
                
                titleLabel.attributedText = NSAttributedString(string: "\(dataPointTouched.lineGraphTitle()):\(dataPointTouched.lineGraphValue())")
            }
            else {
                titleLabel.attributedText = mainTitleText
            }
        }
    }
}


extension LineGraphView {
    
    static func boldFont()->UIFont {
        return LineGraphView.boldFont(14.0)
    }
    
    static func boldFont(_ pointSize:CGFloat)->UIFont {
        return UIFont.boldSystemFont(ofSize: pointSize)
    }
    
    static func regularFont()->UIFont {
        return LineGraphView.regularFont(14.0)
    }
    
    static func regularFont(_ pointSize:CGFloat)->UIFont {
        return UIFont.systemFont(ofSize: pointSize)
    }
    
    static func lightFont()->UIFont {
        return UIFont.systemFont(ofSize: 14.0)
    }
    
}

