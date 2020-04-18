//
//  DeeplinkManager.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 23/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift

protocol DeeplinkHandler {
    var deeplink: Deeplink { get }
    func handle()
}

struct Deeplink {
    let type: DeeplinkType
    var url: URL

    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}

enum DeeplinkType: String {
    case reportInfection = "report"
}

class DeeplinkManager {
    static let shared = DeeplinkManager()

    private var currentDeeplink: Deeplink?

    var deeplinkSubject = BehaviorSubject<Deeplink?>(value: nil)

    func storeDeeplink(url: URL) {
        if url.host != GlobalConfig.deeplinkHost {
            print("[Deeplink] Wrong deeplink host \(url)")
            return
        }

        let purePath = url.path.replacingOccurrences(of: "/", with: "")
        if let deeplinkType = DeeplinkType(rawValue: purePath) {
            currentDeeplink = Deeplink(type: deeplinkType, url: url)
            deeplinkSubject.onNext(currentDeeplink)
        }
    }

    func deeplinkToHandle() -> Deeplink? {
        return currentDeeplink
    }

    func deeplinkHandled() {
        currentDeeplink = nil
    }
}
