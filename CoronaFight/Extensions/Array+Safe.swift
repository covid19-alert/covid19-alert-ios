//
//  Array+Safe.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 16/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation

extension Array {
    public subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
