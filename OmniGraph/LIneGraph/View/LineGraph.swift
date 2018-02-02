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
    var title:String = ""
    var currentPlotIdx = 0
    var plotSegmentedController:UISegmentedControl?
    var indicatorViewsContainer:UIView!
    var isFullScreen   = false
    var primaryLabelSuffix = ""
    var secondaryLabelSuffix = ""
    var numPrimaryLines = 10
    var numSecondaryLines = 5
    // MARK: - Initialize Methods
    
    
    /**
     Responsible for setting the graph label suffix
     */
    func setLabelSuffixes(primaryLabelSuffix:String?, secondaryLabelSuffix:String?){
        if let primarySuffix = primaryLabelSuffix {
            self.primaryLabelSuffix = primarySuffix
        }
        
        if let secondarySuffix = secondaryLabelSuffix{
            self.secondaryLabelSuffix = secondarySuffix
        }
    }
    
    func setNumberOfHorizontalLines(primary:Int,secondary:Int){
        self.numPrimaryLines = primary
        self.numSecondaryLines = secondary
    }
    
    
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
    fileprivate func drawSegmenetedControl() {
        if plotSegmentedController == nil && dataPlots.count > 2 {
            // Initialize, configure and add the plot switching segmented controller
            var plotTitles = [String]()
            for currentPlot in dataPlots {
                plotTitles.append(currentPlot.plotTitle)
            }
            plotSegmentedController            = UISegmentedControl(items: plotTitles)
            plotSegmentedController!.tintColor = UIColor.init(red: 112.0/255.0, green: 185.0/255.0, blue: 228.0/255.0, alpha: 1.0)
            plotSegmentedController!.setTitleTextAttributes([NSAttributedStringKey.font : LineGraphView.lightFont()], for: UIControlState())
            plotSegmentedController!.setTitleTextAttributes([NSAttributedStringKey.font : LineGraphView.regularFont()], for: .selected)
            plotSegmentedController!.addTarget(self, action: #selector(LineGraphView.activePlotValueChanged(_:)), for: .valueChanged)
            plotSegmentedController!.selectedSegmentIndex = 0
            addSubview(plotSegmentedController!)
        }
    }
    
    fileprivate func initializeTitleLabel() {
        // Configure and add the title label
        if !subviews.contains(titleLabel) {
            titleLabel.font           = LineGraphView.regularFont()
            titleLabel.textColor      = UIColor.white
            titleLabel.textAlignment  = titleAlignment
            titleLabel.attributedText = mainTitleText
            addSubview(titleLabel)
        }
    }
    
    fileprivate func initializeDimmingView() {
        if !subviews.contains(loadingDimView) {
            // Initialize all of the loading indicator objects
            loadingDimView.frame           = bounds
            loadingDimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            loadingDimView.isHidden          = true
            
            loadingActivityView.tintColor        = UIColor.darkGray
            loadingActivityView.hidesWhenStopped = true
            loadingDimView.addSubview(loadingActivityView)
            addSubview(loadingDimView)
        }
    }
    
    func initializeSubViews()
    {
        //Initialize the tile Label, which will be displayed at the top as the graph title.
        initializeTitleLabel()
        // initialize the Segmeneted control to switch between the differene tuypes of Plots.
        drawSegmenetedControl()
        // initialize the Dimming view, which will show the spinner, if it is taking little longer to initialize the graph
        initializeDimmingView()
        // initialize the line indicators to indicator which color graph relates to which type.
        initializeLineIndicators()
    }
    
    
    private func initializeLineIndicators(){
        
        var xIndex = 0
        var yIndex = 0
        var indicatorXOrigin = 0.0
        var indicatorYOrigin = 0.0
        
        self.indicatorViewsContainer = UIView.init(frame: CGRect.init(x: 0, y: 0, width: graphInsetFrame.width, height: 60))
        
        var dataSets  = [LineGraphDataSet]()
        // assuming there will always be one or more values in primary data sets
        
        if dataPlots.count > 0{
            for aDataSet in dataPlots[currentPlotIdx].primaryDataSets{
                dataSets.append(aDataSet)
            }
            
            if let secondaryDataSets = self.dataPlots[currentPlotIdx].secondaryDataSets{
                for aDataSet in secondaryDataSets{
                    dataSets.append(aDataSet)
                }
            }
            
            for aDataSet in  dataSets{
                
                if xIndex % 2 == 0 {
                    indicatorXOrigin = 0
                }else{
                    indicatorXOrigin  = 135
                }
                
                indicatorYOrigin = Double(yIndex * 20) //if yINdex==0 then indicatorYorigin = 0 if it ges up to 1 it will be multiplied by 20 and will be come 20
                
                let indicatorView =  UIView.init(frame: CGRect.init(x: indicatorXOrigin, y: indicatorYOrigin, width: 125, height: 18))
                let colorView  = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 50, height: 1))
                colorView.backgroundColor = aDataSet.color
                let label:UILabel = UILabel.init(frame: CGRect.init(x: colorView.frame.width + 2, y: 0, width:indicatorView.frame.width - (colorView.frame.width + 2) , height: 20))
                label.text = aDataSet.dataTitle
                label.font = LineGraphView.regularFont(8.0)
                colorView.center.y  = label.center.y
                indicatorView.addSubview(colorView)
                indicatorView.addSubview(label)
                self.indicatorViewsContainer.addSubview(indicatorView)
                if xIndex % 2 != 0{
                    yIndex += 1
                }
                xIndex = xIndex + 1
            }
        }
        var containerFrame = self.indicatorViewsContainer.frame
        containerFrame.size.height = CGFloat(yIndex * 20)
        self.indicatorViewsContainer.frame = containerFrame
        addSubview(self.indicatorViewsContainer)
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
    func finishLoading(_ dataPlots:[LineGraphDataPlot], title:String) {
        self.dataPlots   = dataPlots
        self.title = title
        
        currentlyLoading = false
        setNeedsDisplay()
        initializeSubViews()
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        let labelWidth             = bounds.width * 0.8
        let titleYPadding:CGFloat  = isFullScreen ? 15.0 : 5.0
        let labelHeight:CGFloat    = 40.0
        
        titleLabel.font          = LineGraphView.regularFont(14.0)
        titleLabel.textAlignment = titleAlignment
        let xOrigin              = (titleAlignment == .center) ? (bounds.width * 0.1) : max(graphInsetFrame.origin.x, 40.0)
        titleLabel.frame         = CGRect(x: xOrigin, y: titleYPadding, width: labelWidth, height: labelHeight)
        titleLabel.contentMode = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines  = 2
        averageValueLabel.frame         = CGRect(x: xOrigin, y: titleLabel.frame.maxY, width: labelWidth, height: 16.0)
        averageValueLabel.textAlignment = titleAlignment
        
        loadingDimView.frame       = bounds
        loadingActivityView.center = CGPoint(x: loadingDimView.bounds.width/2.0, y: loadingDimView.bounds.height/2.0)
    }
    
    // Only override drawRect: if you perform custom drawing.
    fileprivate func drawXAxisLabels(_ currentDataSet: LineGraphDataSet, _ index: Int, _ columnXPosition: ([LineGraphDataPoint], CGFloat) -> CGFloat) {
        // Draw the x axis labels
        var previousXAxisFrame  = CGRect.zero
        let xLabelWidth:CGFloat = 80.0
        let xLabelCount:Int     = min(currentDataSet.dataPoints.count, 6)
        
        if xLabelCount > 1 && index == 0// Currently only draw the primary data plots x label
        {
            for i in 0..<xLabelCount
            {
                let xIndex:Int       = min(Int((CGFloat(i)/CGFloat(xLabelCount-1)) * CGFloat(currentDataSet.dataPoints.count)), currentDataSet.dataPoints.count - 1)
                let titleLabel       = UILabel()
                titleLabel.textColor = UIColor.darkGray
                titleLabel.font      = LineGraphView.lightFont(10)
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
    
    fileprivate func drawSideMarkers(_ counter: inout Int, _ bgLinePoints: [CGFloat], _ bgLabelValues: inout [NSString], _ index: Int) {
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
            currentLabel.font      = LineGraphView.lightFont(10.0)
            currentLabel.sizeToFit()
            
            // Primary data points are drawn on the right margin, secondary on the left
            let xOrigin = (index == 0) ? (graphInsetFrame.origin.x - (currentLabel.bounds.width + 5.0)):(bgLineWidth+5.0)
            currentLabel.drawText(in: CGRect(x: xOrigin, y: currentBGYPoint-10, width: bounds.width-(bgLineWidth + 5), height: 20))
        }
        
        UIColor.lightGray.setStroke()
        bgLinePath.lineWidth = 0.2
        bgLinePath.stroke()
    }
    
    fileprivate func drawHorizontalLines(_ valueInterval: CGFloat, _ frameInterval: CGFloat, _ counter: inout Int, _ index: Int) {
        // Draw the horizontal lines and the indicator lables
        
        
        var bgLabelValues = [NSString]()
        var bgLinePoints = [CGFloat]()
        
        for sideIndex in 0..<self.numPrimaryLines{
            bgLabelValues.append(NSString.singlePrecisionFloat(valueInterval * CGFloat(sideIndex), attemptToTrim: true) as NSString)
            bgLinePoints.append(graphInsetFrame.origin.y + graphInsetFrame.height - (CGFloat(sideIndex) * frameInterval))
        }
        
        drawSideMarkers(&counter, bgLinePoints, &bgLabelValues, index)
    }
    
    fileprivate func drawLinePlotWithContent(_ columnXPosition: ([LineGraphDataPoint], CGFloat) -> CGFloat, _ columnYPosition: (CGFloat, LineGraphDataPoint, LineGraphDataPoint, CGFloat, CGFloat) -> CGFloat, _ context: CGContext?) {
        
        var dataSet  = [LineGraphDataSet]()
        // assuming there will always be one or more values in primary data sets
        for aDataSet in self.dataPlots[currentPlotIdx].primaryDataSets{
            dataSet.append(aDataSet)
        }
        
        if let secondaryDataSets = self.dataPlots[currentPlotIdx].secondaryDataSets{
            for aDataSet in secondaryDataSets{
                dataSet.append(aDataSet)
            }
        }
        
        
        let minMaxValues = maxMinValue(primaryDataSets: self.dataPlots[currentPlotIdx].primaryDataSets, secondaryDataSets: self.dataPlots[currentPlotIdx].secondaryDataSets)
        var maxValue:LineGraphDataPoint
        var minValue:LineGraphDataPoint
        
        
        var index = -1
        var dataSetIndex = -1
        for currentDataSet in dataSet
        {
            dataSetIndex = dataSetIndex + 1
            
            if dataSetIndex <= self.dataPlots[currentPlotIdx].primaryDataSets.count - 1{
                index = 0
                maxValue     = minMaxValues.primary.min
                minValue     = minMaxValues.primary.max
            }else{
                maxValue     = minMaxValues.secondary!.min
                minValue     = minMaxValues.secondary!.max
                index = 1
                
            }
            
            let valueInterval = ( maxValue.lineGraphValue() + minValue.lineGraphValue()) / CGFloat(self.numPrimaryLines)
            let frameInterval = graphInsetFrame.height / CGFloat(self.numPrimaryLines)
            
            // Move to the start add the main graph plot
            let graphPath = UIBezierPath()
            graphPath.move(to: CGPoint(x: columnXPosition(currentDataSet.dataPoints, 0),
                                       y: columnYPosition(currentDataSet.dataPoints[0].lineGraphValue(), minValue, maxValue,valueInterval,frameInterval)))
            
            for i in 1..<currentDataSet.dataPoints.count
            {
                graphPath.addLine(to: CGPoint(x: columnXPosition(currentDataSet.dataPoints, CGFloat(i)),
                                              y: columnYPosition(currentDataSet.dataPoints[i].lineGraphValue(), minValue, maxValue,valueInterval,frameInterval)))
            }
            
            // Stroke the main graph plot
            currentDataSet.color.setStroke()
            graphPath.lineWidth = 1.0
            graphPath.stroke()
            context?.saveGState()
            
            
            // Cycle through all the points drawing the data circles
            context?.restoreGState()
            currentDataSet.color.setFill()
            currentDataSet.color.setStroke()
            var counter             = 0;
            var dataAverage:CGFloat = 0.0
            var dotRadius:CGFloat   = 0.0
            dotRadius = 1.0
            
            
            
            // Cycle through all of the datapoints and draw the dots
            for currentPt in currentDataSet.dataPoints
            {
                let dotCenter = CGPoint(x: columnXPosition(currentDataSet.dataPoints, CGFloat(counter)) - dotRadius/2,
                                        y: columnYPosition(currentPt.lineGraphValue(), minValue, maxValue,valueInterval,frameInterval) -   dotRadius/2)
                counter += 1
                let graphDotPath = UIBezierPath(ovalIn: CGRect(origin: dotCenter, size: CGSize(width: dotRadius, height: dotRadius)))
                graphDotPath.fill()
                dataAverage += currentPt.lineGraphValue()
            }
            
            // Calculate the average, tell the delegate and update the UI components affected
            dataAverage /= CGFloat(currentDataSet.dataPoints.count)
            delegate?.averageCalculated?(self, graphDataAverage: dataAverage, dataSet: currentDataSet)
            
            drawHorizontalLines(valueInterval, frameInterval, &counter, index)
            
            drawXAxisLabels(currentDataSet, index, columnXPosition)
        }
        
    }
    
    fileprivate func ShowNoContentMessage() {
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
    
    fileprivate func drawLinePlots(_ columnXPosition: ([LineGraphDataPoint], CGFloat) -> CGFloat, _ columnYPosition: (CGFloat, LineGraphDataPoint, LineGraphDataPoint, CGFloat, CGFloat) -> CGFloat, _ context: CGContext?) {
        
        if currentPlotIdx < dataPlots.count && (dataPlots[currentPlotIdx].primaryDataSets.first!.dataPoints.count > 0)
        {
            drawLinePlotWithContent(columnXPosition, columnYPosition, context)
        }
        else
        {
            ShowNoContentMessage()
        }
    }
    
    fileprivate func setupTitleText() {
        // Set up the title text
        let titleFont = LineGraphView.regularFont(14.0)
        let titleAttributeText = NSMutableAttributedString.init(string: self.title,attributes: [NSAttributedStringKey.font : titleFont,NSAttributedStringKey.foregroundColor : UIColor.darkGray])
        mainTitleText = titleAttributeText
        
        titleLabel.attributedText = mainTitleText
    }
    
    override func draw(_ rect: CGRect) {
        
        fullScreenButton?.isHidden = !allowFullScreen
        if currentPlotIdx < dataPlots.count
        {
            setupTitleText()
            
            // Calculate the boundaries
            graphInsetFrame.origin.y    = bounds.height * 0.3
            if dataPlots.count > 1 {
                graphInsetFrame.origin.y -= 20.0
            }
            
            graphInsetFrame.size.height = bounds.height - graphInsetFrame.origin.y*2
            if dataPlots.count > 1 {
                graphInsetFrame.size.height -= 40.0
            }
            graphInsetFrame.origin.x    = bounds.width  * 0.125
            graphInsetFrame.size.width  = bounds.width - (graphInsetFrame.origin.x * 2.0)
            
            let columnWidth:CGFloat     = (currentPlotIdx < dataPlots.count) ? (graphInsetFrame.width / max(1,(CGFloat(dataPlots[currentPlotIdx].primaryDataSets.first!.dataPoints.count)) - 1.0)) : 0
            
            // Now that you have the inset bounds calculated you can layout the segmented controller to sit right underneath it
            if let segmentedController = plotSegmentedController {
                
                let yOffset = ((bounds.height - graphInsetFrame.maxY) / 2.0) - (segmentedController.bounds.height / 4.0)
                if !isFullScreen {
                    segmentedController.frame = CGRect(x: 15.0, y: graphInsetFrame.maxY + yOffset, width: bounds.width - 30.0, height: segmentedController.frame.size.height)
                }
                else {
                    segmentedController.frame = CGRect(x: graphInsetFrame.origin.x, y: graphInsetFrame.maxY + yOffset, width: graphInsetFrame.size.width, height: segmentedController.frame.size.height)
                }
//                segmentedController.center.x = center.x
            }
            
            // Now that inset boud is calculated, indicators can be placed right underneath teh Segmeneted controller.
            
            if let indicatorContainerView = self.indicatorViewsContainer{
                var yOffset:CGFloat = 0
                if let segmenetedControl = plotSegmentedController{
                    yOffset = (segmenetedControl.frame.height) + (segmenetedControl.frame.maxY)
                    yOffset -= 30.0
                }else{
                    yOffset = ((bounds.height - graphInsetFrame.maxY) / 2.0) - (indicatorContainerView.bounds.height / 4.0)
                    yOffset = graphInsetFrame.maxY + yOffset
                }
                
                var frame = indicatorContainerView.frame
                frame.origin.y = yOffset //- 30
                frame.size.width = graphInsetFrame.width
                indicatorContainerView.frame = frame
                indicatorContainerView.center.x = center.x
            }
            
            // Draw the background gradient
            let context:CGContext?  = UIGraphicsGetCurrentContext()
            let colorRGB = CGColorSpaceCreateDeviceRGB()
            let gradiant = CGGradient(colorsSpace: colorRGB,
                                      colors: [startColor.cgColor, endColor.cgColor] as CFArray, locations: [0.0,1.0])
            context?.drawLinearGradient(gradiant!, start: CGPoint.zero, end: CGPoint(x: 0, y: self.bounds.height), options: .drawsBeforeStartLocation)
            
            
            let columnXPosition = {(dataPoints:[LineGraphDataPoint], xColumn:CGFloat)->CGFloat in
                return (dataPoints.count > 1) ? self.graphInsetFrame.origin.x + columnWidth*xColumn : self.bounds.width/2.0
            }
            
            
            let columnYPosition = {(graphValue:CGFloat, minValue: LineGraphDataPoint,  maxValue:LineGraphDataPoint,valueInterval:CGFloat,frameInterval:CGFloat)->CGFloat in
                
                let quotient = graphValue / valueInterval
                
                let yPosition              = (self.graphInsetFrame.size.height + self.graphInsetFrame.origin.y) - quotient * frameInterval
                
                return yPosition.isNaN ? self.graphInsetFrame.origin.y + self.graphInsetFrame.size.height/2.0 : yPosition
            }
            
            // Draw the actual data plots
            loadingDimView.isHidden = true
            drawLinePlots(columnXPosition, columnYPosition, context)
        }
    }
    
    
    // MARK: - Data Plot Mutation Methods
    
    @objc func activePlotValueChanged(_ segmentedController:UISegmentedControl)
    {
        currentPlotIdx = segmentedController.selectedSegmentIndex
        setNeedsDisplay()
    }
    
    
    
    // MARK: - Touch Methods
    
    //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        handleTouch(touches, withEvent: event)
    //    }
    //
    //    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        handleTouch(touches, withEvent: event)
    //    }
    
    /// Responsible for reacting to the touch inside of the graph inset view - Updates the top label
    //    func handleTouch(_ touches: Set<UITouch>, withEvent event:UIEvent?) {
    //
    //        if showTouchTitle {
    //
    //            // If the touch point is in the drawn graph (or a little outside of it) handle it as a data touch
    //            let locationPoint = touches.first!.location(in: self)
    //            let touchArea     = graphInsetFrame.insetBy(dx: -10, dy: -10)
    //            if touchArea.contains(locationPoint)
    //            {
    //                let normalizedX      = locationPoint.x - touchArea.origin.x
    //                let insetPercentage  = normalizedX / touchArea.size.width
    //                let index            = Int(floor(CGFloat(dataPlots[currentPlotIdx].primaryDataSet.dataPoints.count) * insetPercentage))
    //                let dataPointTouched = dataPlots[currentPlotIdx].primaryDataSet.dataPoints[index]
    //
    //                titleLabel.attributedText = NSAttributedString(string: "\(dataPointTouched.lineGraphTitle()):\(dataPointTouched.lineGraphValue())")
    //            }
    //            else {
    //                titleLabel.attributedText = mainTitleText
    //            }
    //        }
    
    
    private func maxMinValue(primaryDataSets:[LineGraphDataSet],secondaryDataSets:[LineGraphDataSet]?)->(primary:(max:LineGraphDataPoint,min:LineGraphDataPoint),secondary:(max:LineGraphDataPoint,min:LineGraphDataPoint)?){
        
        typealias MaxMin = (LineGraphDataPoint,LineGraphDataPoint)
        var primaryDataPoints:[LineGraphDataPoint] = [LineGraphDataPoint]()
        
        for aPrimaryDataSet in primaryDataSets {
            primaryDataPoints.append(contentsOf: aPrimaryDataSet.dataPoints)
        }
        
        let sudoPrimaryDataSet = LineGraphDataSet.init(title: "Title", dataPoints: primaryDataPoints, color: UIColor.init())
        
        let  primaryMaxMin:MaxMin = sudoPrimaryDataSet.maxMinElement()
        
        var secondaryDataPoints = [LineGraphDataPoint]()
        var secondaryMaxMin:MaxMin?
        if let secondaryDataSet = secondaryDataSets {
            for aSecondaryDataSet in secondaryDataSet {
                secondaryDataPoints.append(contentsOf: aSecondaryDataSet.dataPoints)
            }
            let sudoSecondaryDataSet = LineGraphDataSet.init(title: "Title", dataPoints: secondaryDataPoints, color: UIColor.init())
            
            secondaryMaxMin = sudoSecondaryDataSet.maxMinElement()
            
        }
        
        return (primaryMaxMin,secondaryMaxMin)
        
    }
}




extension LineGraphView {
    
//    static func boldFont()->UIFont {
//        return LineGraphView.boldFont(14.0)
//    }
//
//    static func boldFont(_ pointSize:CGFloat)->UIFont {
//        return UIFont.boldSystemFont(ofSize: pointSize)
//    }
    
    static func regularFont()->UIFont {
        return LineGraphView.regularFont(14.0)
    }
    
    static func regularFont(_ pointSize:CGFloat)->UIFont {
        return UIFont.systemFont(ofSize: pointSize)
    }
    
    static func lightFont()->UIFont {
        return UIFont.systemFont(ofSize: 14.0)
    }
    static func lightFont(_ pointSize:CGFloat)->UIFont {
        return UIFont.systemFont(ofSize: pointSize)
    }

    
}

