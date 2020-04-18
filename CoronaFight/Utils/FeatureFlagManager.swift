//
//  FeatureFlagManager.swift
//  CoronaFight
//
//  Created by botichelli on 3/23/20.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import CocoaLumberjack

enum FeatureFlag: String, CaseIterable {
    case automaticRegistration
    case onboarding
    case photoProof
    case reportButton
    case pushNotifications
    case storeCredentials
    case requireIntermediateInfoBeforeSelfCheck
    case displayShareButton
    case displaySelfAssessmentButton
}

struct FeatureFlagManager {
    static let shared = FeatureFlagManager()
    static let onDefault = true
    private var flags: [FeatureFlag: Bool] = [:]
    let resource: (name: String, extension: String) = ("config", "json")

    enum FeatureFlagManagerError: Error {
        case contentsCouldNotBeLoaded
        case fileNotFound
    }
    
    init() {
        flags = FeatureFlag.allCases.reduce([FeatureFlag: Bool]()){ (dict, value) -> [FeatureFlag: Bool] in
            var dict = dict
            dict[value] = FeatureFlagManager.onDefault
            return dict
        }

        do {
            try getFlagsFromFile()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    static func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool{
        return FeatureFlagManager.shared.flags[flag] ?? onDefault
    }
    
    mutating func getFlagsFromFile() throws {
        if let filepath = Bundle.main.url(forResource: resource.name,
                                          withExtension: resource.extension) {
            do {
                let data = try Data(contentsOf: filepath)
                if let flags = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Bool] {
                    flags.forEach {
                        guard let key = FeatureFlag(rawValue: $0.key) else { return }
                        self.flags[key] = $0.value
                        DDLogDebug("Setting flag \(key.rawValue) to \($0.value)")
                    }
                }
            } catch {
                throw FeatureFlagManagerError.contentsCouldNotBeLoaded
            }
        } else {
            throw FeatureFlagManagerError.fileNotFound
        }
    }

}
