//
//  JSONHelper.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 28/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation

struct JSONHelper<T: Codable> {
    private struct BoxedValue<T: Codable>: Codable {
        let value: T
    }

    /// seems like on iOS <13 JSONSerializer must have top level object
    /// it was fixed on iOS 13, but funny, it was meant to be fixed on Swift Foundation side,
    /// not on OS side...
    static func readValue(_ data: Data) -> T? {
        if #available(iOS 13, *) {
            return try? JSONDecoder().decode(T.self, from: data)
        } else {
            let boxedValue: BoxedValue<T>? = try? JSONDecoder().decode(BoxedValue<T>.self, from: data)
            return boxedValue?.value
        }
    }

    static func convertValue(_ newValue: T) -> Data? {
        if #available(iOS 13, *) {
            return try? JSONEncoder().encode(newValue)
        } else {
            let boxedValue = BoxedValue(value: newValue)
            return try? JSONEncoder().encode(boxedValue)
        }
    }
}
