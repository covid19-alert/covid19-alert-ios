//
//  InfectedDeeplinkHandler.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 26/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import CocoaLumberjack
import JGProgressHUD
import RxSwift

class InfectedDeeplinkHandler: DeeplinkHandler {

    private var disposeBag = DisposeBag()
    private let infectionValidationKey: String
    private let reportingHelper = ReportingHelper()

    var deeplink: Deeplink
    var alertPresenter: UIViewController

    init?(deeplink: Deeplink, alertPresenter: UIViewController) {
        guard let infectionValidationKey = deeplink.queryParameters?["infectionValidationKey"] else {
            DDLogError("Will not handle infection deeplink, wrong parameter")
            return nil
        }

        self.deeplink = deeplink
        self.infectionValidationKey = infectionValidationKey
        self.alertPresenter = alertPresenter
    }

    func handle() {
        DDLogDebug("Handling report infection deeplink")
        reportingHelper.confirmReportInfected(alertPresenter: self.alertPresenter,
                                              testedAt: Date(),
                                              infectionValidationKey: self.infectionValidationKey)
    }
}
