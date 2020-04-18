//
//  RiskMeterView.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 3/18/20.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class RiskMeterView : UIView {

    var angle = 180.0
    let font = UIFont(name: "DMSans-Regular", size: 12)
    
    // Create the circle layer
    var outerCircle = CAShapeLayer()
    var innerCircle = CAShapeLayer()
    var riskCircle = CAShapeLayer()
    var arrow = UIView(frame: .zero)
    var centerView = UIView(frame: .zero)
    var lowLabel = UILabel()
    var highLabel = UILabel()

    private var position = 0.0 {
        didSet {
            if oldValue != position {
                animateProgress(toPosition: position, fromPosition: oldValue)
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepareViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareViews()
    }
    
    func setPosition(_ position: Double) {
        self.position = position
    }
    
    func runAnimation() {
        animateProgress(toPosition: self.position, fromPosition: 0.0)
    }
    
    func prepareViews() {
        outerCircle = CircleData.outer.shapeLayer()
        innerCircle = CircleData.inner.shapeLayer()
        riskCircle = CircleData.progress.shapeLayer()

        outerCircle.addSublayer(innerCircle)
        outerCircle.addSublayer(riskCircle)
        self.layer.addSublayer(outerCircle)
        self.addSubview(arrow)
        self.addSubview(centerView)
        self.addSubview(lowLabel)
        self.addSubview(highLabel)

        addShadow(to: arrow)
        addShadow(to: centerView)
        setupLabels()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let frame = self.bounds
        let size = self.bounds.size

        let circleRadius = self.circleRadius(size: size)
        let circleCenter = self.circleCenter(center: self.center, radius: circleRadius)

        outerCircle.path = CircleData.outer.path(size: size, center: circleCenter, radius: circleRadius)
        innerCircle.path = CircleData.inner.path(size: size, center: circleCenter, radius: circleRadius)
        riskCircle.path = CircleData.progress.path(size: size,center: circleCenter, radius: circleRadius)
        configureArrowView(frame: frame, center: circleCenter, radius: circleRadius)
        configureCenterView(frame: frame, center: circleCenter)

        arrow.layer.shadowPath = UIBezierPath(rect: arrow.bounds).cgPath
        centerView.layer.shadowPath = UIBezierPath(rect: centerView.bounds).cgPath
        layoutLabels(frame: frame, center: circleCenter, radius: circleRadius)
    }

    func circleRadius(size: CGSize) -> CGFloat {
        let maxBorder = CircleData.outer.borderWidth / 2.0
        let horizontalRadius = (size.width - maxBorder) / 2.0
        let verticalRadius = size.height - maxBorder - 30.0
        let halfCircleRadius = min(horizontalRadius, verticalRadius)
        return halfCircleRadius
    }

    func circleCenter(center: CGPoint, radius: CGFloat) -> CGPoint {
        let maxBorder = CircleData.outer.borderWidth / 2.0
        return CGPoint(x: center.x - (maxBorder / 4.0), y: center.y + (radius / 2.0))
    }

    func configureCenterView(frame: CGRect, center: CGPoint) {
        let viewSize = CGSize(width: 10.0, height: 10.0)
        let viewPosition = CGPoint(x: center.x - 5 ,
                                   y: center.y - 5)
        let frameRect = CGRect(origin: viewPosition, size: viewSize)
        centerView.frame = frameRect
        centerView.layer.cornerRadius = 5
        centerView.backgroundColor = UIColor(red: 0.153,
                                             green: 0.075,
                                             blue: 0.208,
                                             alpha: 1)
    }
    
    func configureArrowView(frame: CGRect, center: CGPoint, radius: CGFloat) {
        let arrowLength = radius - CircleData.outer.borderWidth
        let arrowPosition = CGPoint(x: center.x - arrowLength,
                                    y: center.y - 1.0)
        let arrowSize = CGSize(width: arrowLength, height: 2.0)
        arrow.frame = CGRect(origin: arrowPosition, size: arrowSize)
        arrow.backgroundColor = UIColor(named: "reportUserDateLine")
        arrow.setAnchorPoint(CGPoint(x: 1, y: 0.5))
    }
    
    func addShadow(to uiview: UIView) {
        uiview.layer.shadowColor = uiview.backgroundColor?.cgColor
        uiview.layer.shadowOpacity = 0.3
        uiview.layer.shadowOffset = CGSize(width: 1, height: 3)
        uiview.layer.shadowRadius = 5
        uiview.layer.shouldRasterize = true
        uiview.layer.rasterizationScale = UIScreen.main.scale
    }
    
    func setupLabels() {
        lowLabel.font = self.font
        highLabel.font = self.font
        lowLabel.textAlignment = .left
        highLabel.textAlignment = .right
        lowLabel.text = NSLocalizedString("Low", comment: "")
        highLabel.text = NSLocalizedString("High", comment: "")
        lowLabel.textColor = UIColor(named: "dashboardText")
        highLabel.textColor = UIColor(named: "dashboardText")
    }
    
    func layoutLabels(frame: CGRect, center: CGPoint, radius: CGFloat) {
        let fullRadius = radius + CircleData.outer.borderWidth / 2.0
        let labelX = center.x - fullRadius
        let labelY = center.y + CircleData.outer.borderWidth / 2.0
        let labelSize = CGSize(width: fullRadius * 2.0, height: 20.0)

        let lowOrigin = CGPoint(x: labelX, y: labelY)
        let labelFrame = CGRect(origin: lowOrigin, size: labelSize)
        
        lowLabel.frame = labelFrame
        highLabel.frame = labelFrame
    }
    
    func animateProgress(toPosition: Double = 0.0, fromPosition: Double = 0.0, duration: Double = 3.0) {
        let riskCircleData = CircleData.progress
        let colorAnimation = CABasicAnimation(keyPath: "strokeColor")
        colorAnimation.fromValue = riskCircleData.colorAt(position: 0.0).cgColor
        colorAnimation.toValue = riskCircleData.colorAt(position: toPosition).cgColor
        colorAnimation.duration = duration
        colorAnimation.repeatCount = 1
        riskCircle.add(colorAnimation, forKey: "riskColorAnimation")

        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.repeatCount = 1
        strokeAnimation.fromValue = fromPosition
        strokeAnimation.toValue = toPosition
        strokeAnimation.duration = duration
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        riskCircle.add(strokeAnimation, forKey: "riskStrokeAnimation")
        riskCircle.strokeEnd = CGFloat(toPosition)
        riskCircle.strokeColor = riskCircleData.colorAt(position: toPosition).cgColor
        
        let arrowAnimation = CABasicAnimation(keyPath: "transform.rotation")
        arrowAnimation.fromValue = fromPosition * Double.pi
        arrowAnimation.toValue = toPosition * Double.pi
        arrowAnimation.duration = duration
        arrowAnimation.repeatCount = 1
        arrowAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        arrowAnimation.fillMode = .forwards
        arrowAnimation.isRemovedOnCompletion = false
        arrow.layer.add(arrowAnimation, forKey: "RotatingAnimation")
    }
}
