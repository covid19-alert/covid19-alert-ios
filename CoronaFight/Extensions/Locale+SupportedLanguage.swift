//
//  Locale+SupportedLanguage.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 26/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation

enum SupportedLanguage: String, CaseIterable {
    case en, pl, cs, de, pt, es
}

extension Locale {

    static var supportedLanguage: SupportedLanguage {
        if let language = Locale.preferredLanguages.first {
           let supportedLanguages = SupportedLanguage.allCases.compactMap { language.starts(with: $0.rawValue) ? $0 : nil }
            if let supportedLanguage = supportedLanguages.first {
                return supportedLanguage
            }
        }
        return .en
    }
}
