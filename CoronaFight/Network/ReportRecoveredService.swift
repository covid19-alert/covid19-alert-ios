//
//  ReportRecoveredService.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 27/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift

struct ReportRecoveredRequest: Codable {
    let testedAt: Date
}

struct ReportRecoveredService: APICall {
    static var api = APIService()
    static let base = GlobalConfig.currentEnv.url()

    private static let endpoint = "report_recovered"

    static func report(testTime: Date) -> Observable<DashboardData?> {

        let authData: (minor: String, major: String)
        do {
            authData = try Self.authData()
        } catch {
            return Observable.error(APIError.noAuthData)
        }

        let requestBody = ReportRecoveredRequest(testedAt: testTime)
        let request = Self.simpleAuthenticatedJsonPostRequest(self.endpoint, minor: authData.minor, major: authData.major).jsonBody(requestBody)
        return self.api.run(request).map { $0.value }
    }
}
