//
//  KeychainStored.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 26/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation


@propertyWrapper
struct KeychainStored<T: Codable> {

    private var keychainItem: KeychainItem
    private var keychainService: String
    private var itemKey: String

    var wrappedValue: T? {
        didSet {
            try? self.storeInKeychain(wrappedValue)
        }
    }

    var projectedValue: KeychainItem {
        return self.keychainItem
    }

    init(service: String, key: String) {
        self.keychainService = service
        self.itemKey = key
        self.keychainItem = KeychainItem(service: self.keychainService, itemKey: self.itemKey)
        self.wrappedValue = Self.readFromKeychain(self.keychainItem)
    }

    private func storeInKeychain(_ newValue: T?) throws {
        if newValue == nil {
            try? self.keychainItem.deleteItem()
            return
        }
        if let data = JSONHelper.convertValue(newValue) {
            try? self.keychainItem.saveItem(data)
        }
    }

    private static func readFromKeychain(_ keychainItem: KeychainItem) -> T? {
        if let data = try? keychainItem.readItem() {
            return JSONHelper.readValue(data)
        }
        return nil
    }
}
