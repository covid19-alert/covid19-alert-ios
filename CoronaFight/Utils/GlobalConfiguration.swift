//
//  GlobalConfiguration.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

enum GlobalLinks: String {
    case instructionsForSick = "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/advice-for-public"
    case selfAssessment = "https://covid19.infermedica.com/"

    func localizedURL() -> URL? {
        if self == .selfAssessment {
            switch Locale.supportedLanguage {
            case .en:
                return URL(string: "\(self.rawValue)en/")
            case .pl:
                return URL(string: "\(self.rawValue)pl/")
            case .cs:
                return URL(string: "\(self.rawValue)cs/")
            case .de:
                return URL(string: "\(self.rawValue)de/")
            case .pt:
                return URL(string: "\(self.rawValue)pt/")
            case .es:
                //Intentional..
                return URL(string: "\(self.rawValue)pt/")
            }
        } else if self == .instructionsForSick {
            switch Locale.supportedLanguage {
            case .pl:
                return URL(string: "https://www.gov.pl/web/koronawirus")
            default:
                return URL(string: self.rawValue)
            }
        }

        return URL(string: self.rawValue)
    }
}

enum GlobalConfig {
    #if DEBUG
    static var currentEnv = Env.test
    #else
    static var currentEnv = Env.prod
    #endif

    static var deviceUUID = UIDevice.current.identifierForVendor!.uuidString
    static var beaconUUID = "43DB3082-A889-4510-902A-E99E5EDB9504"
    static var deeplinkHost = "www.covid19-alert.eu"
    static var keychainServiceName = Bundle.main.bundleIdentifier ?? "com.virus.CoronaFight"
}

class SessionManager {
    static let shared = SessionManager()

    private init() {}

    @KeychainStored(service: GlobalConfig.keychainServiceName, key: UserDefaultKeys.databaseKey.rawValue)
    private var databaseKeyStorage: Data?

    var databaseKey: Data {
        if let dbKey = self.databaseKeyStorage {
            return dbKey
        } else {
            // generate key, save it to keychain
            let newKey = AppDelegate.generateSecureKey()
            self.databaseKeyStorage = newKey
            return newKey
        }
    }

    @UserDefault(key: .lastTimeRegistered, defaultValue: nil)
    var registerTime: Date?

    @KeychainStored(service: GlobalConfig.keychainServiceName, key: UserDefaultKeys.minorId.rawValue)
    var minor: Int?

    @KeychainStored(service: GlobalConfig.keychainServiceName, key: UserDefaultKeys.majorId.rawValue)
    var major: Int?

    @KeychainStored(service: GlobalConfig.keychainServiceName, key: UserDefaultKeys.deviceId.rawValue)
    var deviceIdentifier: String?

    @UserDefault(key: .lastNotifiedChangeForRiskLevel, defaultValue: RiskLevel.low.rawValue)
    var lastNotifiedChangeForRiskLevel: Int?
    
    @UserDefault(key: .dashboardData, defaultValue: DashboardData(riskLevel: 0,
                                                                  numberOfInfectedMet: 0,
                                                                  reportedSelfInfection: false,
                                                                  reportedRecovered: false))
    var dashboardData: DashboardData

    func currentRiskLevel(numberOfInfectedPeople: Int) -> RiskLevel {
        if dashboardData.reportedRecovered {
            return .recovered
        }
        if dashboardData.reportedSelfInfection {
            return .infected
        }
        return numberOfInfectedPeople > 0 ? .medium : .low
    }

    var isRegistered: Bool {
        let minorAndMajorPresent = self.minor != nil && self.major != nil
        let shouldConsiderRegistrationDate = FeatureFlagManager.isFeatureFlagEnabled(.storeCredentials)
        let previouslyRegistered = self.registerTime != nil || shouldConsiderRegistrationDate
        return minorAndMajorPresent && previouslyRegistered
    }

    var webActionTitle: String {
        return dashboardData.sickAndNotRecovered() ? NSLocalizedString("What can you do?", comment: "") : NSLocalizedString("Run self assessment test", comment: "")
    }

    var webActionUrl: URL? {
        return dashboardData.sickAndNotRecovered() ? GlobalLinks.instructionsForSick.localizedURL() : GlobalLinks.selfAssessment.localizedURL()
    }

    func clearAllSessionData() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        let allItems = try? KeychainItem.allItems(forService: GlobalConfig.keychainServiceName)
        allItems?.forEach { try? $0.deleteItem() }
    }
}
