//
//  ReportingHelper.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 27/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import CocoaLumberjack
import JGProgressHUD

class ReportingHelper {

    private let disposeBag = DisposeBag()

    func confirmReportInfected(alertPresenter: UIViewController, testedAt: Date, infectionValidationKey: String) {
         let alert = UIAlertController(title: NSLocalizedString("Infection report", comment: ""),
                                       message: NSLocalizedString("You are confirming to be tested on SARS-CoV-2 with positive result", comment: ""),
                                       preferredStyle: .alert)

         alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""),
                                       style: .default, handler: { _ in
             self.reportInfection(alertPresenter: alertPresenter, date: testedAt, infectionValidationKey: infectionValidationKey)
             alert.dismiss(animated: true)
         }))

         alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""),
                                       style: .cancel, handler: { _ in
             DDLogDebug("User did dismiss report infection from deeplink confirmation")
             alert.dismiss(animated: true)
         }))

         alertPresenter.present(alert, animated: true)
     }

    func confirmReportRecovered(alertPresenter: UIViewController, testedAt: Date) {
           let alert = UIAlertController(title: NSLocalizedString("Recovery report", comment: ""),
                                         message: NSLocalizedString("You are confirming that your body has no longer presence of SARS-CoV-2", comment: ""),
                                         preferredStyle: .alert)

           alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""),
                                         style: .default, handler: { _ in
               self.reportRecovery(alertPresenter: alertPresenter, date: testedAt)
               alert.dismiss(animated: true)
           }))

           alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""),
                                         style: .cancel, handler: { _ in
               DDLogDebug("User did dismiss report recovery")
               alert.dismiss(animated: true)
           }))

           alertPresenter.present(alert, animated: true)
     }

     private func reportInfection(alertPresenter: UIViewController, date: Date, infectionValidationKey: String) {
         let hud = JGProgressHUD(style: .light)
         hud.show(in: alertPresenter.view, animated: true)

         ReportInfectedWithDeeplinkService.report(testTime: date, infectionValidationKey: infectionValidationKey)
               .subscribe(
                 onNext: { response in
                     if let dashboardData = response {
                        SessionManager.shared.dashboardData = dashboardData
                     }
                 },
                 onError: { error in
                   DDLogError("Error when sending infection from deeplink \(error)")

                   if let apiError = error as? APIError {
                     hud.textLabel.text = apiError.localizedDescription
                   } else {
                     hud.textLabel.text = NSLocalizedString("Something went wrong..", comment: "")
                   }

                   hud.indicatorView = JGProgressHUDErrorIndicatorView()
                   hud.dismiss(afterDelay: 3.0, animated: true)
                 },
                 onCompleted: {
                   DDLogDebug("Successfully reported infection from deeplink!")
                   DeeplinkManager.shared.deeplinkHandled()
                   hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                   hud.textLabel.text = NSLocalizedString("Reported", comment: "")
                   hud.dismiss(afterDelay: 3.0, animated: true)
             })
         .disposed(by: self.disposeBag)
     }

     private func reportRecovery(alertPresenter: UIViewController, date: Date) {
        let hud = JGProgressHUD(style: .light)
        hud.show(in: alertPresenter.view, animated: true)

        ReportRecoveredService.report(testTime: date)
              .subscribe(
                onNext: { response in
                    if let dashboardData = response {
                        SessionManager.shared.dashboardData = dashboardData
                    }
                },
                onError: { error in
                  DDLogError("Error when sending recovery \(error)")

                  if let apiError = error as? APIError {
                    hud.textLabel.text = apiError.localizedDescription
                  } else {
                    hud.textLabel.text = NSLocalizedString("Something went wrong..", comment: "")
                  }

                  hud.indicatorView = JGProgressHUDErrorIndicatorView()
                  hud.dismiss(afterDelay: 3.0, animated: true)
                },
                onCompleted: {
                  DDLogDebug("Successfully reported infection from deeplink!")
                  DeeplinkManager.shared.deeplinkHandled()
                  hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                  hud.textLabel.text = NSLocalizedString("Wonderful!", comment: "")
                  hud.dismiss(afterDelay: 3.0, animated: true)
            })
        .disposed(by: self.disposeBag)
    }

}
