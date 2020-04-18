//
//  BeaconDiscovery.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import CoreLocation
import RealmSwift
import Darwin

class BeaconDiscovery: Object {
    @objc dynamic var uuid: String = ""
    @objc dynamic var major: Int = 0
    @objc dynamic var minor: Int = 0
    @objc dynamic var accuracy: Int = 0
    @objc dynamic var proximityRaw: Int = 0
    @objc dynamic var date: Date = Date()

    func seenUserId() -> String {
        return "\(major):\(minor)"
    }

    // Generated with http://www.xuru.org/rt/ExpR.asp#CopyPaste
    // Source data https://docs.google.com/spreadsheets/d/18iJMessuhHYw55TkZy9YAnhk9JSToJH-LDFu9JTS5Us/edit#gid=0
    func convertRSSIToMeters() -> Double {
        let eNumber = Darwin.M_E
        let multiplier = pow(eNumber, -0.0538911686 * Double(accuracy))
        let result = 3.986383967 * multiplier * 0.01
        return result
    }

    func isClose() -> Bool {
        return accuracy < 0 && accuracy >= -70
    }
}
