//
//  FirebaseTokenUpdateService.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 25/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift

struct FirebaseTokenUpdateRequest: Codable {
    let firebaseToken: String
}

struct FirebaseTokenUpdateService: APICall {
    static var api = APIService()
    static let base = GlobalConfig.currentEnv.url()

    private static let endpoint = "update_firebase_token"

    static func updateToken(_ firebaseToken: String) -> Observable<Void> {
        let authData: (minor: String, major: String)
        do {
            authData = try Self.authData()
        } catch {
            return Observable.error(APIError.noAuthData)
        }
        
        let requestBody = FirebaseTokenUpdateRequest(firebaseToken: firebaseToken)
        let request = Self.simpleAuthenticatedJsonPostRequest(Self.endpoint,
                                                              minor: authData.minor,
                                                              major: authData.major).jsonBody(requestBody)
        return self.api.run(request).map { _ in Void() }
    }
}
