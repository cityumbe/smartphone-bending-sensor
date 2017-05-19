//
//  PlotViewController.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 18/2/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

import UIKit
import CorePlot

class PlotView: CPTGraphHostingView, CPTPlotDataSource {
    
    var values = [Double]()
    var graph: CPTXYGraph!
    var correlationPlot: CPTScatterPlot!
    var plotInterval: Int!
    
    override func awakeFromNib() {
        plotInterval = Preference.getPlotInterval()
        
        super.awakeFromNib()
    }
    
    func initPlot() {
        let hostingView = self
        
        graph = CPTXYGraph(frame: CGRectZero)
        hostingView.hostedGraph = graph
        
        graph.paddingLeft   = 5.0
        graph.paddingRight  = 5.0
        graph.paddingTop    = 5.0
        graph.paddingBottom = 5.0
        let axisSet = graph.axisSet as! CPTXYAxisSet
        
        let xAxis = axisSet.xAxis!
        xAxis.majorTickLineStyle = axisLineStype()
        xAxis.minorTickLineStyle = axisLineStype()
        xAxis.axisLineStyle = axisLineStype()
        
        let yAxis = axisSet.yAxis!
        yAxis.majorTickLineStyle = axisLineStype()
        yAxis.minorTickLineStyle = axisLineStype()
        yAxis.axisLineStyle = axisLineStype()
        
        let plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsUserInteraction = false
        plotSpace.yRange = CPTPlotRange(location:0.0, length:0.02)
        plotSpace.xRange = CPTPlotRange(location:0.0, length:0.2)
        
        correlationPlot = CPTScatterPlot(frame: CGRectZero)
        
        correlationPlot.dataLineStyle = correlationLineStype()
        correlationPlot.identifier = "Corr"
        correlationPlot.dataSource = self
        
        graph.addPlot(correlationPlot)
    }
    
    func correlationLineStype() -> CPTLineStyle {
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 1.5
        lineStyle.lineColor = CPTColor.whiteColor()
        return lineStyle
    }
    
    func axisLineStype() -> CPTLineStyle {
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 1.0
        lineStyle.lineColor = CPTColor.whiteColor()
        return lineStyle
    }
    
    func fixXYRange() {
        assert(NSThread.isMainThread())
        guard values.count > 0 else {
            return
        }
        let plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.yRange = CPTPlotRange(location:-0.1, length: 1.2)
        plotSpace.globalYRange = CPTPlotRange(location:-0.1, length: 1.2)
        plotSpace.xRange = CPTPlotRange(location:-1.5, length:plotInterval + 2)
        plotSpace.globalXRange = CPTPlotRange(location:-1.5, length:plotInterval + 2)
        // plotSpace.scaleToFitPlots(graph.allPlots())
    }
    
    func addCorrelation(value: Double) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.values.append(value)
            self.correlationPlot.reloadData()
            self.fixXYRange()
        }
    }
    
    func numberOfRecordsForPlot(plot: CPTPlot) -> UInt {
        return min(UInt(values.count), UInt(plotInterval))
    }
    
    func numberForPlot(plot: CPTPlot, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject? {
        let plotField = CPTScatterPlotField(rawValue: Int(fieldEnum))
        
        let value = self.values[Int(idx) + max(values.count - plotInterval, 0)]
        let plotID = plot.identifier as! String
        if (plotField! == .Y) && (plotID == "Corr") {
            return value
        } else {
            return idx
        }
    }
}