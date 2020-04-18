//
//  ViewController.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxRealm
import SwiftDate
import CocoaLumberjack

enum CellIdentifier: String {
    case beacon = "BeaconCell"
    case discover = "DiscoveryCell"
    case trace = "TraceCell"
}

class ConfigurationViewController: UIViewController {

    @IBOutlet weak var myUuidTextField: UITextField!
    @IBOutlet weak var uuidTextField: UITextField!
    @IBOutlet weak var regionIdentifierTextField: UITextField!
    @IBOutlet weak var majorTextField: UITextField!
    @IBOutlet weak var minorTextField: UITextField!
    @IBOutlet weak var beaconsTableView: UITableView!
    @IBOutlet weak var dataTableView: UITableView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    @IBOutlet weak var startButton: UIButton!

    fileprivate let locationService = LocationService()
    fileprivate let realmStorage = RealmStorage()
    fileprivate var disposeBag = DisposeBag()
    fileprivate var autoSendDisposeBag: DisposeBag!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupDiscoveredBeacons()

        self.bindTextFields()
        self.bindButtons()
        self.bindEnabledFields()

        self.setupDataEntries()
    }

    func bindTextFields() {
        self.myUuidTextField.text = SessionManager.shared.deviceIdentifier
        self.majorTextField.isEnabled = false
        self.majorTextField.text = "\(DataCollectorService.shared.currentConfiguration!.major)"
        self.majorTextField.isEnabled = false
        self.minorTextField.text = "\(DataCollectorService.shared.currentConfiguration!.minor)"
    }

    func bindButtons() {
        self.deleteButton.rx.tap
            .bind {
                UIApplication.sharedDelegate.showConfirmationHUD(with: "Database cleaned")
                let allObjects = self.realmStorage.realm.objects(BeaconDiscovery.self)
                self.realmStorage.cleanupDiscoveries()
            }
            .disposed(by: self.disposeBag)

        DataCollectorService.shared.isScanning
            .map { $0 ? "Stop scanning/advertising" : "Start scanning/advertising" }
            .bind(to: self.startButton.rx.title()).disposed(by: self.disposeBag)
    }

    func bindEnabledFields() {
        let controlsGroup: [UITextField] = [
            self.uuidTextField,
            self.regionIdentifierTextField
        ]
        DataCollectorService.shared.isScanning.subscribe(onNext: { enabled in
            controlsGroup.forEach { $0.isEnabled = !enabled }
        }).disposed(by: self.disposeBag)
    }

    func setupDiscoveredBeacons() {
        DataCollectorService.shared.locationService.beaconsObservable
            .bind(to: beaconsTableView.rx.items(cellIdentifier: CellIdentifier.beacon.rawValue,
                                                cellType: UITableViewCell.self)) { (row, element, cell) in
                cell.textLabel?.text = "Major: \(element.major) Minor: \(element.minor)"
                cell.detailTextLabel?.text = "\(element.rssi) dB"
            }
            .disposed(by: disposeBag)
    }

    func setupDataEntries() {

        Observable.array(from: DataCollectorService.shared.sortedDiscoveries)
            .bind(to: dataTableView.rx.items(cellIdentifier: CellIdentifier.discover.rawValue,
                                                cellType: UITableViewCell.self)) { (row, element, cell) in
                let style = RelativeFormatter.Style(flavours: [.longConvenient, .long],
                                                    gradation: .convenient(),
                                                    allowedUnits: [.now, .second, .minute, .hour, .day, .week, .month, .year])
                cell.textLabel?.text = "Major: \(element.major) Minor: \(element.minor)"
                cell.detailTextLabel?.text = "\(element.date.toRelative(style: style))"
            }
            .disposed(by: disposeBag)
    }

    @IBAction func exitApp(_ sender: Any) {
        DDLogDebug("About to exit(0) of app")
        exit(0)
    }

    @IBAction func clearAppData(_ sender: Any) {
        realmStorage.cleanAllData()
        SessionManager.shared.clearAllSessionData()
        UIApplication.sharedDelegate.showConfirmationHUD(with: "Cleared all data. \nApp will now close itself, please start again.", time: 2.0, success: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            exit(0)
        }
    }

    func configureBeaconsService() {
        guard let uuid = uuidTextField.text,
              let regionId = regionIdentifierTextField.text,
              let majorText = majorTextField.text,
              let major = Int(majorText),
              let minorText = minorTextField.text,
              let minor = Int(minorText) else {
            return
        }

        let configuration = BeaconsServiceConfiguration(uuidString: uuid, regionId: regionId, major: major, minor: minor)
        locationService.start(with: configuration)
    }

    @IBAction func startScanningButtonTapped(sender: UIButton) {
        if DataCollectorService.shared.isScanning.value == false {
            configureBeaconsService()
            DataCollectorService.shared.startSavingBeaconData()
        } else {
            DataCollectorService.shared.stopSavingBeaconData()
        }
    }

}

