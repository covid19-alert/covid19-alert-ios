//
//  RiskLevel.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 18/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit

enum RiskLevel: Int {
    case low, medium, high, infected, recovered

    func riskLevelString() -> NSAttributedString {
        switch self {
        case .low:
            let keyword = NSLocalizedString("low risk", comment: "")
            let fullText = NSLocalizedString("You have a low risk of being infected", comment: "")
            return NSAttributedString.markKeyword(keyword, in: fullText, with: UIColor(named: "lowRiskTitle")!)
        case .medium:
            let keyword = NSLocalizedString("medium risk", comment: "")
            let fullText = NSLocalizedString("You have a medium risk of being infected", comment: "")
            return NSAttributedString.markKeyword(keyword, in: fullText, with: UIColor(named: "mediumRiskTitle")!)
        case .high:
            let keyword = NSLocalizedString("high risk", comment: "")
            let fullText = NSLocalizedString("You have a high risk of being infected", comment: "")
            return NSAttributedString.markKeyword(keyword, in: fullText, with: UIColor(named: "highRiskTitle")!)
        case .infected:
            let keyword = NSLocalizedString("infected", comment: "")
            let fullText = NSLocalizedString("You are infected", comment: "")
            return NSAttributedString.markKeyword(keyword, in: fullText, with: UIColor(named: "highRiskTitle")!)
        case .recovered:
            let keyword = NSLocalizedString("recovered", comment: "")
            let fullText = NSLocalizedString("You are recovered", comment: "")
            return NSAttributedString.markKeyword(keyword, in: fullText, with: UIColor(named: "lowRiskTitle")!)
        }
    }

    func backgroundColor() -> UIColor {
        switch self {
        case .low, .recovered:
            return UIColor(named: "lowRiskBg")!
        case .medium:
            return UIColor(named: "mediumRiskBg")!
        case .high, .infected:
            return UIColor(named: "highRiskBg")!
        }
    }

    func statsColor() -> UIColor {
       switch self {
       case .low, .recovered:
           return UIColor(named: "lowRiskStat")!
       case .medium:
           return UIColor(named: "mediumRiskStat")!
       case .high, .infected:
           return UIColor(named: "highRiskStat")!
       }
    }

    func bgImageName() -> String {
        switch self {
        case .low, .recovered:
            return "risk_low_bg"
        case .medium:
            return "risk_medium_bg"
        case .high, .infected:
            return "risk_high_bg"
        }
    }
    
    func riskLevelPosition() -> Double {
        switch self {
        case .recovered:
            return 0.01
        case .low:
            return 0.1
        case .medium:
            return 0.5
        case .high:
            return 0.9
        case .infected:
            return 1.0
        }
    }
}
