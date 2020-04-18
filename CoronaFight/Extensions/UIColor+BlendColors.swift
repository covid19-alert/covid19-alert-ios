//
//  UIColorBlendColors.swift
//  CoronaFight
//
//  Created by botichelli on 3/20/20.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    // Alpha Blending
    func blend(coverColor: UIColor, mixLevel: CGFloat = 0.5) -> UIColor {
        let c1 = coverColor.rgbaTuple()
        let c2 = self.rgbaTuple()

        let c1r = CGFloat(c1.r)
        let c1g = CGFloat(c1.g)
        let c1b = CGFloat(c1.b)
        let c1a = CGFloat(c1.a)

        let c2r = CGFloat(c2.r)
        let c2g = CGFloat(c2.g)
        let c2b = CGFloat(c2.b)
        let c2a = CGFloat(c2.a)

        let r = ((c1r * mixLevel) + (c2r * (1.0 - mixLevel))) / 255.0
        let g = ((c1g * mixLevel) + (c2g * (1.0 - mixLevel))) / 255.0
        let b = ((c1b * mixLevel) + (c2b * (1.0 - mixLevel))) / 255.0
        let a = (c1a * mixLevel) + (c2a * (1.0 - mixLevel))

        return UIColor.init(red: r, green: g, blue: b, alpha: a)
    }

    func rgbaTuple() -> (r: CGFloat, g: CGFloat, b: CGFloat,a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        r = r * 255
        g = g * 255
        b = b * 255

        return ((r),(g),(b),a)
    }
}
