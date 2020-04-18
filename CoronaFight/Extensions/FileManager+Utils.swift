//
//  FileManager+Utils.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 02/04/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation

extension FileManager {
    var documentsUrl: URL {
        self.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
