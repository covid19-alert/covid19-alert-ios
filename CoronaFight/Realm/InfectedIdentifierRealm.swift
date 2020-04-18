//
//  InfectedIdentifierRealm.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation
import SwiftDate

class InfectedIdentifierRealm: Object {
    @objc dynamic var identifier: String = ""

    override class func primaryKey() -> String? {
        return "identifier"
    }
}
