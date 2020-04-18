//
//  DashboardViewController.swift
//  CoronaFight
//
//  Created by Dima on 15/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import RxRealm
import SwiftDate
import CoreLocation
import CocoaLumberjack

class DashboardViewController: UIViewController {

    private var disposeBag = DisposeBag()

    private var realmStorage = RealmStorage()

    @IBOutlet weak var infectedPeopleReportButton: UIButton!
    @IBOutlet weak var reportInfectionButton: UIButton!
    @IBOutlet weak var whatCanYouDoButton: UIButton!
    
    @IBOutlet weak var stackViewBackground: UIView!
    @IBOutlet weak var statsStackView: UIStackView!
    @IBOutlet weak var detailsStackView: UIStackView!

    @IBOutlet weak var statsViewBackground: UIView!
    @IBOutlet weak var permissionsViewBackground: UIView!
    
    @IBOutlet weak var riskMeterView: RiskMeterView!
    @IBOutlet weak var riskBgImageView: UIImageView!

    @IBOutlet weak var totalNumberLabel: UILabel!
    @IBOutlet weak var numberInfectedLabel: UILabel!
    @IBOutlet weak var riskTitleLabel: UILabel!
    @IBOutlet weak var numberInfectedDescrTopLabel: UILabel!
    
    @IBOutlet weak var permissionRequiredStackVIew: UIStackView!
    @IBOutlet weak var requirementsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        //To Avoid going back to onboarding
        navigationController?.viewControllers = [self]
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "",
                                                                style: .plain,
                                                                target: nil,
                                                                action: nil)

        if FeatureFlagManager.isFeatureFlagEnabled(.displayShareButton) {
            let shareButton = UIBarButtonItem.init(barButtonSystemItem: .action,
                                                   target: self,
                                                   action: #selector(share(sender:)))
            self.navigationItem.rightBarButtonItem = shareButton
        }

        #if DEBUG
        self.configureDebugScreenPresentation()
        #endif

        self.setupLabels()
        self.setupStrings()
        self.setupDeeplinkHandler()
        self.bindLabels()
        self.bindDashboardData()

        if !FeatureFlagManager.isFeatureFlagEnabled(.reportButton) {
            self.reportInfectionButton.isHidden = true
        }

        if FeatureFlagManager.isFeatureFlagEnabled(.displaySelfAssessmentButton) == false {
            self.whatCanYouDoButton.isHidden = true
            // disable layout marings to gain maximum size for risk meter
//            self.detailsStackView.directionalLayoutMargins = NSDirectionalEdgeInsets()
//            self.detailsStackView.isLayoutMarginsRelativeArrangement = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.checkPermissions()

        DataCollectorService.shared.reloadInfectedIds()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.riskMeterView.runAnimation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.reportInfectionButton.layer.cornerRadius = self.reportInfectionButton.frame.height / 2.0
        self.stackViewBackground.layer.cornerRadius = 16.0
        self.numberInfectedLabel.layer.backgroundColor = self.numberInfectedLabel.backgroundColor?.cgColor
        self.numberInfectedLabel.layer.masksToBounds = true
        self.numberInfectedLabel.layer.cornerRadius = self.numberInfectedLabel.bounds.height / 2.0
        self.riskMeterView.setNeedsLayout()
    }
    
    private func bindDashboardData() {
        SessionManager.shared.$dashboardData.observeOn(MainScheduler.instance).subscribe(onNext:{ [weak self] data in
            let riskLevelEnum = data.riskLevelEnum()
            self?.setupRiskLevel(riskLevel: riskLevelEnum)
            self?.riskMeterView.setPosition(data.riskLevelDouble())
            self?.numberInfectedLabel.text = String(data.numberOfInfectedMet)
            if riskLevelEnum == .infected {
                self?.reportInfectionButton.setTitle(NSLocalizedString("Report your recovery", comment: ""), for: .normal)
            } else {
                self?.reportInfectionButton.setTitle(NSLocalizedString("Report your infection", comment: ""), for: .normal)
            }
        }).disposed(by: disposeBag)
    }
    
    private func checkPermissions() {
        let permissionObservable = PermissionService.permissionsSubject
        permissionObservable.subscribe(onNext:{ [weak self] location, bluetooth in
            var locationStatus: String? = nil
            var bluetoothStatus: String? = nil
                        
            switch location {
            case .authorizedWhenInUse, .authorizedAlways:
                locationStatus = nil
            default:
                locationStatus = NSLocalizedString("location permission", comment: "")
            }
            
            switch bluetooth {
            case .poweredOn:
                bluetoothStatus = nil
            case .poweredOff:
                bluetoothStatus = NSLocalizedString("Bluetooth to be turned on", comment: "")
            default:
                bluetoothStatus = NSLocalizedString("Bluetooth permission", comment: "")
            }
            let permissions = [locationStatus, bluetoothStatus].compactMap{ $0 }
            
            if permissions.count == 0 {
                self?.didReceivePermissions()
            } else {
                let permissionsText = NSLocalizedString("Covid-19 Alert needs ", comment: "") +
                                        permissions.joined(separator:  " and ") +
                                        NSLocalizedString(" to work correctly. Open settings to adjust.", comment: "")
                self?.requiresPermissionsView(message: permissionsText)
            }
            
            }).disposed(by: disposeBag)
    }
    
    private func requiresPermissionsView(message: String) {
        DDLogDebug("setuping view for no permission mode")
        requirementsLabel.text = message

        DispatchQueue.main.async {
           self.permissionsViewBackground.isHidden = false
           self.permissionRequiredStackVIew.isHidden = false
           self.statsStackView.isHidden = true
           self.statsViewBackground.isHidden = true
           self.view.setNeedsLayout()
       }
    }
    
    private func didReceivePermissions() {
        DispatchQueue.main.async {
            self.permissionsViewBackground.isHidden = true
            self.permissionRequiredStackVIew.isHidden = true
            self.statsStackView.isHidden = false
            self.statsViewBackground.isHidden = false
            self.view.setNeedsLayout()
        }
    }
    
    private func setupDeeplinkHandler() {
        DeeplinkManager.shared.deeplinkSubject.asObserver().subscribe { (event) in
            if let element = event.element,
               let deeplink = element {
                self.handle(deeplink: deeplink)
            }
        }.disposed(by: disposeBag)
    }

    private func handle(deeplink:  Deeplink) {
        switch deeplink.type {
          case .reportInfection:
            if let infectedDeeplinkHandler = InfectedDeeplinkHandler(deeplink: deeplink, alertPresenter: self) {
                infectedDeeplinkHandler.handle()
            }
        }
    }

    private func setupLabels() {
        totalNumberLabel.font = UIFont.regularMetricFont(size: 16.0)
        totalNumberLabel.adjustsFontForContentSizeCategory = true
        totalNumberLabel.adjustsFontSizeToFitWidth = true
        totalNumberLabel.minimumScaleFactor = 0.5

        numberInfectedDescrTopLabel.font = UIFont.regularMetricFont(size: 20.0)
        numberInfectedDescrTopLabel.adjustsFontForContentSizeCategory = true
        numberInfectedDescrTopLabel.adjustsFontSizeToFitWidth = true
        numberInfectedDescrTopLabel.minimumScaleFactor = 0.5

        requirementsLabel.font = UIFont.regularMetricFont(size: 20.0)
        requirementsLabel.adjustsFontForContentSizeCategory = true
        requirementsLabel.adjustsFontSizeToFitWidth = true
        requirementsLabel.minimumScaleFactor = 0.8
    }

    private func setupStrings() {
        self.totalNumberLabel.text = String(format: NSLocalizedString("Out of %d people met", comment: ""), 0)
        self.numberInfectedLabel.text = "0"
        self.numberInfectedDescrTopLabel.text = NSLocalizedString("people you've been in contact with are infected", comment: "")
    }

    func setupRiskLevel(riskLevel: RiskLevel) {
        self.view.backgroundColor = riskLevel.backgroundColor()
        self.numberInfectedLabel.backgroundColor = riskLevel.statsColor()
        self.riskBgImageView.image = UIImage(named: riskLevel.bgImageName())
        self.riskTitleLabel.attributedText = riskLevel.riskLevelString()
        self.riskMeterView.setPosition(SessionManager.shared.dashboardData.riskLevelDouble())
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        let underlineAttributedString = NSAttributedString(string: SessionManager.shared.webActionTitle, attributes: underlineAttribute)
        self.whatCanYouDoButton.setAttributedTitle(underlineAttributedString, for: .normal)
        self.whatCanYouDoButton.titleLabel?.attributedText = underlineAttributedString

        if SessionManager.shared.dashboardData.reportedSelfInfection && SessionManager.shared.dashboardData.reportedRecovered {
            self.reportInfectionButton.isHidden = true
            return
        }

        if SessionManager.shared.dashboardData.reportedSelfInfection {
            self.reportInfectionButton.setTitle(NSLocalizedString("Report your recovery", comment: ""), for: .normal)
        } else {
            self.reportInfectionButton.setTitle(NSLocalizedString("Report your infection", comment: ""), for: .normal)
        }
    }

    func configureDebugScreenPresentation() {
        if let titleItem = self.navigationController?.navigationBar.subviews[safeIndex: 1] {
            let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(presentDebugConfiguration))
            doubleTapRecognizer.numberOfTapsRequired = 2

            titleItem.isUserInteractionEnabled = true
            titleItem.addGestureRecognizer(doubleTapRecognizer)
        }
    }

    func bindLabels() {
        realmStorage.peopleMet.bind { (peopleMet) in
            DispatchQueue.main.async {
                self.totalNumberLabel.text = String(format: NSLocalizedString("Out of %d people met", comment: ""), peopleMet)
           }
        }.disposed(by: disposeBag)

        let infecterRecognizer = UITapGestureRecognizer(target: self, action: #selector(seeInfectedDetailsAction(_:)))
        statsStackView.isUserInteractionEnabled = true
        statsStackView.addGestureRecognizer(infecterRecognizer)
        
        let permissionRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(openSettings(_:)))
        permissionRequiredStackVIew.isUserInteractionEnabled = true
        permissionRequiredStackVIew.addGestureRecognizer(permissionRecognizer)
    }

    @IBAction func checkSymptomsAction(_ sender: Any) {
        if SessionManager.shared.dashboardData.reportedSelfInfection == false &&
            FeatureFlagManager.isFeatureFlagEnabled(.requireIntermediateInfoBeforeSelfCheck) == true {
            self.performSegue(withIdentifier: "IntermediateInfoViewControllerSegue", sender: nil)
        } else {
            self.performSegue(withIdentifier: "CheckSymptomsControllerSegue", sender: nil)
        }
    }
    
    @objc func seeInfectedDetailsAction(_ sender: Any) {
        self.performSegue(withIdentifier: "ReportViewControllerSeque", sender: nil)
    }
    
    @objc func openSettings(_ sender: Any) {
        UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
    }
    
    @IBAction func reportImInfectedAction(_ sender: Any) {
        let riskLevel = SessionManager.shared.dashboardData.riskLevelEnum()
        if riskLevel == .infected {
            let reportingHelper = ReportingHelper()
            reportingHelper.confirmReportRecovered(alertPresenter: self, testedAt: Date())
        } else if riskLevel != .recovered {
            self.performSegue(withIdentifier: "InfectionViewControllerSegue", sender: nil)
        }
    }

    @objc func share(sender: UIBarButtonItem) {
        let items: [Any] = [NSLocalizedString("I am using Covid-19 Alert to stop virus spreading. #stayAtHome", comment: ""),
                            URL(string: "https://covid19-alert.eu")!]
        let activityViewController = UIActivityViewController(activityItems: items,
                                                              applicationActivities: nil)

        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.barButtonItem = sender
        }

        present(activityViewController, animated: true)
    }

    @objc func presentDebugConfiguration() {
        self.performSegue(withIdentifier: "ConfigurationViewControllerSeque", sender: nil)
    }
}


