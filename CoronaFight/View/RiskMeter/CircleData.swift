//
//  CircleData.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 3/20/20.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit

struct CircleData {
    let borderWidth: CGFloat
    let lowerColor: UIColor
    let midColor: UIColor?
    let upperColor: UIColor?
    let isHalfCircle: Bool

    func colors() -> [UIColor] {
        guard let midColor = midColor,
              let upperColor = upperColor else {
                return [lowerColor]
        }

        return [lowerColor, midColor, upperColor]
    }

    func colorAt(position: Double) -> UIColor {
        let allColors = colors()
        let colorsDelta = 1.01 / Double(allColors.count)
        let index = Int(floor(position / colorsDelta))
        let delta = CGFloat(position - colorsDelta * Double(index))

        if index == allColors.count - 1 {
            return allColors[index]
        }

        let firstColor = allColors[index]
        let secondColor = allColors[index + 1]
        return firstColor.blend(coverColor: secondColor, mixLevel: delta)
    }

    func shapeLayer() -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = lowerColor.cgColor
        shapeLayer.lineWidth = borderWidth
        shapeLayer.lineCap = .round
        shapeLayer.strokeStart = 0.0
        shapeLayer.strokeEnd = 1.0
        return shapeLayer
    }

    func path(size: CGSize, center: CGPoint, radius: CGFloat) -> CGPath {
        let ang = CGFloat.pi
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: ang,
                                endAngle: 2 * ang,
                                clockwise: true)
        return path.cgPath
    }
    

    static let outer = CircleData(borderWidth: 26.0,
                                  lowerColor: UIColor(named: "riskMeterBackground")!,
                                  midColor: nil,
                                  upperColor: nil,
                                  isHalfCircle: true)
    
    static let inner = CircleData(borderWidth: 16.0,
                                  lowerColor: UIColor(named: "riskMeterInnerBackground")!,
                                  midColor: nil,
                                  upperColor: nil,
                                  isHalfCircle: true)

    static let progress = CircleData(borderWidth: 6.0,
                                     lowerColor: UIColor(named: "lowRiskMeter")!,
                                     midColor: UIColor(named: "mediumRiskMeter"),
                                     upperColor: UIColor(named: "highRiskMeter"),
                                     isHalfCircle: true)
}
