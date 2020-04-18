//
//  UserDefaults.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 08/02/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift

struct UserDefaultKeys: RawRepresentable {
    let rawValue: String

    static let databaseKey: UserDefaultKeys = "databaseKey"
    static let minorId: UserDefaultKeys = "minorId"
    static let majorId: UserDefaultKeys = "majorId"
    static let deviceId: UserDefaultKeys = "deviceId"
    static let isUserSick: UserDefaultKeys = "isUserSick"
    static let isUserRecovered: UserDefaultKeys = "isUserRecovered"
    static let lastNotifiedChangeForRiskLevel: UserDefaultKeys = "lastNotifiedChangeForRiskLevel"
    static let dashboardData: UserDefaultKeys = "dashboardData"
    static let lastTimeRegistered: UserDefaultKeys = "registerTime"
}

extension UserDefaultKeys: ExpressibleByStringLiteral {
    init(stringLiteral: String) {
        rawValue = stringLiteral
    }
}

@propertyWrapper
struct UserDefault<T: Codable> {
    private let key: UserDefaultKeys
    private let defaultValue: T
    private let behaviorSubject: BehaviorSubject<T>

    init(key: UserDefaultKeys, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
        self.behaviorSubject = BehaviorSubject(value: self.defaultValue)
        self.behaviorSubject.onNext(self.wrappedValue)
    }

    var wrappedValue: T {
        get {
            // Read value from UserDefaults
            guard let data = UserDefaults.standard.object(forKey: key.rawValue) as? Data else {
                // Return defaultValue when no data in UserDefaults
                return defaultValue
            }

            // Convert data to the desire data type
            let value: T? = JSONHelper.readValue(data)

            return value ?? defaultValue
        }
        set {
            // Convert newValue to data
            let data = JSONHelper.convertValue(newValue)

            // Set value to UserDefaults
            UserDefaults.standard.set(data, forKey: key.rawValue)

            // update observable
            self.behaviorSubject.onNext(newValue)
        }
    }

    var projectedValue: Observable<T> {
        get {
            return behaviorSubject
                .observeOn(MainScheduler.instance) // because some of the observers may want to access observed value in the
                                                // same call stack before setter finished (waiting for onNext call) it may lead
                                                // to crash due to simultaneous access. By adding MainScheduler here it will
                                                // move observation code to next run loop and prevent crash.
                .asObservable()
        }
    }
}
