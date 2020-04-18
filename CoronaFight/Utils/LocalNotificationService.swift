//
//  LocalNotificationService.swift
//  CoronaFight
//
//  Created by botichelli on 3/31/20.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UserNotifications
import CocoaLumberjack
import RxSwift

class LocalNotificationService {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let disposeBag = DisposeBag()
    private var riskLevel = SessionManager.shared.dashboardData.riskLevelEnum()
    
    init() {
        SessionManager.shared.$dashboardData.subscribe(onNext: { [weak self] data in
            let newRiskLevel = data.riskLevelEnum()
            let lastNotifiedRiskLevel = SessionManager.shared.lastNotifiedChangeForRiskLevel ?? RiskLevel.low.rawValue
            let shouldNotify = (lastNotifiedRiskLevel != newRiskLevel.rawValue)
            if shouldNotify {
                self?.riskLevelChanged(to: newRiskLevel)
            }

        }).disposed(by: disposeBag)
    }
    
    func riskLevelChanged(to level: RiskLevel) {
        DDLogDebug("Risk level changed")
        notificationCenter.getNotificationSettings { (settings) in
            let notValidStatus = [UNAuthorizationStatus.notDetermined, UNAuthorizationStatus.denied]
            if !notValidStatus.contains(settings.authorizationStatus) {
                self.notifyUserWith(status: level.riskLevelString().string)
                SessionManager.shared.lastNotifiedChangeForRiskLevel = level.rawValue
            }
        }
    }
    
    private func notifyUserWith(status: String) {
        let title = NSLocalizedString("Risk level update", comment: "")
        let description = status
        scheduleNotification(title: title, description: description)
    }
    
    private func scheduleNotification(title: String, description: String) {
        DDLogDebug("Sending local notification \(title), \(description)")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = description
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: "Risk Level Changed Notification", content: content, trigger: nil)
        notificationCenter.add(request) { (error) in
            if let error = error {
                DDLogError("Error \(error.localizedDescription)")
            }
        }
    }
}
