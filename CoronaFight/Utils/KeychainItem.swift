/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    A struct for accessing generic password keychain items.

    Modified by Przemysław Szurmak
*/

import Foundation

struct KeychainItem {
    // MARK: Types

    enum KeychainError: Error {
        case noItem
        case unexpectedItemData
        case unexpectedItemsData
        case unhandledError(status: OSStatus)
    }

    // MARK: Properties

    let service: String

    private(set) var itemKey: String

    let accessGroup: String?

    // MARK: Intialization

    init(service: String, itemKey: String, accessGroup: String? = nil) {
        self.service = service
        self.itemKey = itemKey
        self.accessGroup = accessGroup
    }

    // MARK: Keychain access

    func readItem() throws -> Data  {
        /*
            Build a query to find the item that matches the service, itemKey and
            access group.
        */
        var query = KeychainItem.keychainQuery(withService: service, account: itemKey, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue

        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.noItem }
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }

        // Parse the password string from the query result.
        guard let existingItem = queryResult as? [String : AnyObject],
            let itemData = existingItem[kSecValueData as String] as? Data
        else {
            throw KeychainError.unexpectedItemData
        }

        return itemData
    }

    func saveItem(_ encodedItem: Data) throws {
        do {
            // Check for an existing item in the keychain.
            try _ = readItem()

            // Update the existing item with the new password.
            var attributesToUpdate = [String : AnyObject]()
            attributesToUpdate[kSecValueData as String] = encodedItem as AnyObject?

            let query = KeychainItem.keychainQuery(withService: service, account: itemKey, accessGroup: accessGroup)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
        catch KeychainError.noItem {
            /*
                No password was found in the keychain. Create a dictionary to save
                as a new keychain item.
            */
            var newItem = KeychainItem.keychainQuery(withService: service, account: itemKey, accessGroup: accessGroup)
            newItem[kSecValueData as String] = encodedItem as AnyObject?

            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)

            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
    }

    mutating func renameItemKey(_ newItemKey: String) throws {
        // Try to update an existing item with the new itemKey name.
        var attributesToUpdate = [String : AnyObject]()
        attributesToUpdate[kSecAttrAccount as String] = newItemKey as AnyObject?

        let query = KeychainItem.keychainQuery(withService: service, account: self.itemKey, accessGroup: accessGroup)
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }

        self.itemKey = newItemKey
    }

    func deleteItem() throws {
        // Delete the existing item from the keychain.
        let query = KeychainItem.keychainQuery(withService: service, account: itemKey, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)

        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }

    static func allItems(forService service: String, accessGroup: String? = nil) throws -> [KeychainItem] {
        // Build a query for all items that match the service and access group.
        var query = KeychainItem.keychainQuery(withService: service, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanFalse

        // Fetch matching items from the keychain.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        // If no items were found, return an empty array.
        guard status != errSecItemNotFound else { return [] }

        // Throw an error if an unexpected status was returned.
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }

        // Cast the query result to an array of dictionaries.
        guard let resultData = queryResult as? [[String : AnyObject]] else { throw KeychainError.unexpectedItemsData }

        // Create a `KeychainItem` for each dictionary in the query result.
        var allItemsArray = [KeychainItem]()
        for result in resultData {
            guard let account  = result[kSecAttrAccount as String] as? String else { throw KeychainError.unexpectedItemsData }

            let nextItem = KeychainItem(service: service, itemKey: account, accessGroup: accessGroup)
            allItemsArray.append(nextItem)
        }

        return allItemsArray
    }

    // MARK: Convenience

    private static func keychainQuery(withService service: String, account: String? = nil, accessGroup: String? = nil) -> [String : AnyObject] {
        var query = [String : AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?

        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }

        return query
    }
}
