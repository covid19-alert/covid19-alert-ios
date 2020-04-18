//
//  DashboardService.swift
//  CoronaFight
//
//  Created by botichelli on 3/26/20.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift

struct DashboardData: Codable {
    let riskLevel: Int
    let numberOfInfectedMet: Int
    let reportedSelfInfection: Bool
    let reportedRecovered: Bool
    
    func sickAndNotRecovered() -> Bool {
        return reportedSelfInfection && !reportedRecovered
    }

    func riskLevelEnum() -> RiskLevel {
        if reportedSelfInfection && !reportedRecovered {
            return RiskLevel.infected
        } else if reportedRecovered {
            return RiskLevel.recovered
        } else if riskLevel < 34 {
            return RiskLevel.low
        } else if riskLevel < 67 {
            return RiskLevel.medium
        }
        
        return RiskLevel.high
    }
    
    func riskLevelDouble() -> Double {
        if reportedSelfInfection && !reportedRecovered {
            return 1.0
        }

        if reportedRecovered {
            return 0.01
        }

        guard (1...100).contains(riskLevel) else {
            return 0.01
        }
        
        return ( Double(riskLevel) / 100 )
    }
}
