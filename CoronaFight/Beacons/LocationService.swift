//
//  BluetoothService.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth
import RxSwift
import RxCocoa
import CocoaLumberjack

struct BeaconsServiceConfiguration {
    let uuidString: String
    let regionId: String
    let major: Int
    let minor: Int

    func uuid() -> UUID? {
        return UUID(uuidString: uuidString)
    }
}

class LocationService: NSObject {

    var permissionStatusObservable: Observable<CLAuthorizationStatus> {
        return permissionStatusSubject.asObserver()
    }

    var beaconsObservable: Observable<[CLBeacon]> {
        return beaconsSubject.share(replay: 1, scope: .forever).asObservable()
    }

    var peripheralManagerObservable: Observable<CBManagerState> {
        return peripheralManagerSubject.asObserver()
    }

    var configuration: BeaconsServiceConfiguration?

    private let beaconsSubject = PublishSubject<[CLBeacon]>()

    private let permissionStatusSubject = BehaviorSubject<CLAuthorizationStatus>(value: .notDetermined)

    private let peripheralManagerSubject = BehaviorSubject<CBManagerState>(value: .unknown)

    private var peripheralManager: CBPeripheralManager?

    private let locationManager = CLLocationManager()

    private let disposeBag = DisposeBag()

    private var scanningDisposable: Disposable!

    override init() {
        super.init()
        self.locationManager.delegate = self
    }

    func askForBluetoothPermission() {
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.main, options: nil)
    }

    func askForLocationPermission() {
        self.locationManager.requestAlwaysAuthorization()
    }

    func startLocationServices() {
        DDLogDebug("Starting monitoringSignificantLocationChanges")
        self.askForLocationPermission()
    }

    func start(with configuration: BeaconsServiceConfiguration) {
        self.configuration = configuration
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.main, options: nil)
        // Wait for CBPeripheralManager to power on
    }

    private func continueStart() {
        guard let configuration = self.configuration else { return }

        peripheralManager?.stopAdvertising()

        guard let beaconRegion = createBeaconRegion(configuration: configuration) else {
            DDLogDebug("Cannot create beacon region")
            return
        }

        advertiseDevice(region: beaconRegion)
        startRangingBeacons(with: configuration)
    }

    func createBeaconRegion(configuration: BeaconsServiceConfiguration) -> CLBeaconRegion? {
        guard let uuid = configuration.uuid() else {
                DDLogDebug("Cannot initalize BeaconsService")
                return nil
        }

        let major : CLBeaconMajorValue = UInt16(configuration.major)
        let minor : CLBeaconMinorValue = UInt16(configuration.minor)

        if #available(iOS 13.0, *) {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: major, minor: minor)
            return CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: configuration.regionId)
        } else {
            return CLBeaconRegion(proximityUUID: uuid, major: major, minor: minor, identifier: configuration.regionId)
        }
    }

    func advertiseDevice(region: CLBeaconRegion) {
        let peripheralData = region.peripheralData(withMeasuredPower: nil)
        let peripheralDictionary = ((peripheralData as NSDictionary) as! [String : Any])

        DDLogDebug("Starting advertising...")
        peripheralManager?.startAdvertising(peripheralDictionary)

        if let major = region.major, let minor = region.minor {
            DDLogDebug("Beacon created with: \(major):\(minor)")
        }
    }

    func startRangingBeacons(with configuration: BeaconsServiceConfiguration) {
        guard let uuid = configuration.uuid() else { return }

        self.askForLocationPermission()

        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: configuration.regionId)
        beaconRegion.notifyOnEntry = true
        beaconRegion.notifyEntryStateOnDisplay = true
        beaconRegion.notifyOnExit = true
        
        self.locationManager.stopMonitoring(for: beaconRegion)
        self.locationManager.startMonitoring(for: beaconRegion)
        DDLogDebug("Starting rangingBeacons...")
    }

    func startRanging() {
        guard let config = configuration else { return }
        guard let uuid = config.uuid() else { return }

          if #available(iOS 13.0, *) {
              let constraint = CLBeaconIdentityConstraint(uuid: uuid)
              self.locationManager.stopRangingBeacons(satisfying: constraint)
              self.locationManager.startRangingBeacons(satisfying: constraint)
              DDLogDebug("Starting rangingBeacons...")
          } else {
              let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: configuration!.regionId)
              self.locationManager.stopRangingBeacons(in: beaconRegion)
              self.locationManager.startRangingBeacons(in: beaconRegion)
              DDLogDebug("Starting rangingBeacons...")
          }
    }

    func stopRanging() {
        guard let config = configuration else { return }
        guard let uuid = config.uuid() else { return }

        if #available(iOS 13.0, *) {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid)
            self.locationManager.stopRangingBeacons(satisfying: constraint)
            DDLogDebug("Stopping rangingBeacons...")
        } else {
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: configuration!.regionId)
            self.locationManager.stopRangingBeacons(in: beaconRegion)
            DDLogDebug("Stopping rangingBeacons...")
        }
    }
}

extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DDLogDebug("didEnterRegion \(region)")
        self.startRanging()
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DDLogDebug("DidExitRegion \(region)")
        self.stopRanging()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DDLogDebug("locationManager didChangeAuthorization \(status.rawValue)")
        permissionStatusSubject.onNext(status)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        DDLogDebug("locationManager Region state changed \(state.rawValue)")

        if state == .inside {
            self.startRanging()
        } else if state == .outside {
            self.stopRanging()
        }
    }

    @available(iOS 13.0, *)
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        DDLogDebug("locationManager didRange beacon")
        beaconsSubject.onNext(beacons)
    }

    @available(iOS 13.0, *)
    func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
        DDLogDebug("locationManager didFailRangingFor \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        DDLogDebug("locationManager didRangeBeacons")
        beaconsSubject.onNext(beacons)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DDLogDebug("locationManager didFailWithError \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        DDLogDebug("locationManager didVisit \(visit)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DDLogDebug("locationManager didUpdateLocations")
    }
}

extension LocationService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            self.continueStart()
        }
        DDLogDebug("peripheralManagerDidUpdateState \(peripheral.state)")
        peripheralManagerSubject.onNext(peripheral.state)
    }
}
