//
//  UIFont+Scale.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 20/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {

    static func boldMetricFont(size: CGFloat) -> UIFont {
        guard let boldFont = UIFont(name: "DMSans-Bold", size: size) else {
            return UIFontMetrics(forTextStyle: .title1).scaledFont(for: UIFont.boldSystemFont(ofSize: size))
        }
        return UIFontMetrics(forTextStyle: .title1).scaledFont(for: boldFont)
    }

    static func regularMetricFont(size: CGFloat) -> UIFont {
       guard let regularFont = UIFont(name: "DMSans-Regular", size: size) else {
           return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: size))
       }
       return UIFontMetrics(forTextStyle: .body).scaledFont(for: regularFont)
   }

}
