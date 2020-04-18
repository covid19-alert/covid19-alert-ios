//
//  NSAttribiutedString+Keyword.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 18/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString {

    static func markKeyword(_ keyword: String, in fullText: String, with color: UIColor) -> NSAttributedString {
        let rangeOfKeyword = (fullText as NSString).range(of: keyword)
        let attributedString = NSMutableAttributedString(string: fullText)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: rangeOfKeyword)
        return attributedString
    }

}
