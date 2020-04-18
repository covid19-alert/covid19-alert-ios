//
//  RegisterViewController.swift
//  CoronaFight
//
//  Created by Dima on 15/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import UIKit
import CoreLocation
import RxSwift
import RxRelay
import RxRealm
import SwiftDate
import JGProgressHUD
import CocoaLumberjack
 
// TODO that one need to be opened only if user is not registered,
class RegisterViewController: UIViewController {

    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var privacyAcceptance: UILabel!
    @IBOutlet weak var privacySwitch: UISwitch!

    private var userLocation: CLLocation?
    private var firebaseToken: String?

    private let disposableBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupStrings()
        if SessionManager.shared.isRegistered == true {
            registrationCompleted(animated: false)
            return
        }

        if FeatureFlagManager.isFeatureFlagEnabled(.automaticRegistration) {
            self.registerIfNeeded()
            return
        }

        registerButton.isEnabled = false
        privacySwitch.isOn = false

        let privacyAccepted = privacySwitch.rx.isOn
        DataCollectorService.shared.firebaseTokenSubject.asObserver().subscribe(onNext: { (firebaseToken) in
                self.firebaseToken = firebaseToken
        }).disposed(by: disposableBag)

        privacyAccepted.subscribe(onNext: { (enabled) in
            let color = UIColor(named: "buttonColor")
            self.registerButton.isEnabled = enabled
            self.registerButton.backgroundColor = enabled ? color : color?.withAlphaComponent(0.3)
        }).disposed(by: disposableBag)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openPrivacyPolicy))
        privacyAcceptance.isUserInteractionEnabled = true
        privacyAcceptance.addGestureRecognizer(tapGestureRecognizer)

        if !FeatureFlagManager.isFeatureFlagEnabled(.onboarding) {
            self.navigationItem.setHidesBackButton(true, animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.registerButton.layer.cornerRadius =  self.registerButton.bounds.height / 2.0
    }

    private func setupStrings() {
        welcomeLabel.text = NSLocalizedString("Please accept to\ncontinue using the app", comment: "")
        registerButton.setTitle(NSLocalizedString("Enter", comment: ""), for: .normal)
        registerButton.setTitle(NSLocalizedString("Enter", comment: ""), for: .disabled)
        privacyAcceptance.text = NSLocalizedString("I accept the privacy policy", comment: "")
        //usernameTextField.placeholder = NSLocalizedString("Username", comment: "")
    }

    func registerIfNeeded() {
        // Override point for customization after application launch.
        if SessionManager.shared.isRegistered == false {
            let hud = JGProgressHUD(style: .light)
            hud.show(in: self.view, animated: true)

            let deviceId = SessionManager.shared.deviceIdentifier ?? GlobalConfig.deviceUUID

            DDLogDebug("Entering server with id: \(deviceId)")
            let coordinate = self.userLocation?.coordinate
            RegisterService.register(deviceId,
                                     lat: coordinate?.latitude,
                                     lon: coordinate?.longitude,
                                     firebaseToken: self.firebaseToken)
                .subscribe(onNext: { response in
                    print("Registered, userId: \(response)")
                    SessionManager.shared.registerTime = Date()
                    SessionManager.shared.minor = response.minor
                    SessionManager.shared.major = response.major
                    SessionManager.shared.deviceIdentifier = deviceId
                    if let status = response.status {
                        SessionManager.shared.dashboardData = status
                    }
                    hud.dismiss(animated: true)
                    self.registrationCompleted(animated: true)
                }, onError: { error in
                    hud.dismiss(animated: false)
                    UIApplication.sharedDelegate.showConfirmationHUD(with: "Error occured during registration, try again in a moment")
                    DDLogError("Error in registration -> \(error)")
                })
                .disposed(by: self.disposableBag)
        } else {
            print("No need to register, already registered")
            self.registrationCompleted(animated: false)
        }
    }

    func registrationCompleted(animated: Bool) {
        AppDelegate.setupDataCollector()

        if FeatureFlagManager.isFeatureFlagEnabled(.storeCredentials) {
            UIApplication.sharedDelegate.setupPushNotifications()
        }
        
        DDLogDebug("Open Dashboard")
        let identifier = animated ? "DashboardViewControllerSeque" : "DashboardViewControllerStaticSeque"
        self.performSegue(withIdentifier: identifier, sender: nil)
    }

    @IBAction func registerAction(_ sender: Any) {
        registerIfNeeded()
    }

    @objc func openPrivacyPolicy() {
        guard let url = URL(string: "https://www.covid19-alert.eu/privacy.html") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
