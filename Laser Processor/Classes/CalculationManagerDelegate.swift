//
//  CalculationManagerDelegate.swift
//  Laser Processor
//
//  Created by Xinhong LIU on 2/3/2016.
//  Copyright © 2016 ParseCool. All rights reserved.
//

protocol CalculationManagerDelegate: class {
    
    // called when new correlation value is calculated
    func calculationManagerCorrelationCalculated(calculationManager: CalculationManager, correlation: Double)
    
    // called when all values calculated
    func calculationManagerAllCorrelationCalculated(calculationManager: CalculationManager, count: Int)
}