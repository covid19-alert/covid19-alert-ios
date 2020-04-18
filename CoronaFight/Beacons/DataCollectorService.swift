//
//  DataCollectorService.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import CocoaLumberjack

class DataCollectorService {

    static var shared: DataCollectorService = DataCollectorService()

    var currentConfiguration: BeaconsServiceConfiguration?

    private let saveBeaconsThrottleInSeconds = 5
    private var saveBeaconsDisposable: Disposable?
    private var lastLocationDisposable: Disposable?
    private var storeBeaconsDisposable: Disposable?

    private let hardcodedRegionId = "CoronaFightZone"

    private var autoFetchTime = 60
    private var autoFetchDisposeBag: DisposeBag!
    private let disposeBag = DisposeBag()
    private var notificationService: LocalNotificationService?

    lazy var sortedDiscoveries = {
        return realmStorage.realm.objects(BeaconDiscovery.self).sorted(byKeyPath: "date", ascending: false)
    }()

    var locationService: LocationService = LocationService()
    var realmStorage: RealmStorage = RealmStorage()

    var isScanning = BehaviorRelay(value: false)
    let firebaseTokenSubject = BehaviorSubject<String>(value: "")

    func startLocationUpdates() {
        self.locationService.startLocationServices()

        self.firebaseTokenSubject.asObserver()
            .filter { !$0.isEmpty }
            .subscribe(onNext: { (firebaseToken) in
            FirebaseTokenUpdateService.updateToken(firebaseToken)
                .subscribe(onNext: {
                print("Firebase token updated to API")
            }, onError: { error in
                print("[Error] Error occured while sending firebase token \(error)")
            }).disposed(by: self.disposeBag)
            
        }).disposed(by: disposeBag)
    }

    func start(major: Int, minor: Int) {
        self.startAutoFetchOfInfectedPeople()
        self.startSavingBeaconData()
        self.startBeaconDiscovery(major: major, minor: minor)
        self.notificationService = LocalNotificationService()
//        self.addRandomData()
    }

    private func addRandomData() {
        try? self.realmStorage.realm.write {
            for i in 351...400 {
                let infectedIdRealm = InfectedIdentifierRealm()
                infectedIdRealm.identifier = "\(i):1"
                self.realmStorage.realm.add(infectedIdRealm)

                let beaconsDiscovery = BeaconDiscovery()
                beaconsDiscovery.uuid = GlobalConfig.beaconUUID
                beaconsDiscovery.major = i
                beaconsDiscovery.minor = 1
                beaconsDiscovery.accuracy = -80
                beaconsDiscovery.date = Date()
                self.realmStorage.realm.add(beaconsDiscovery)
            }
        }
    }

    private func startBeaconDiscovery(major: Int, minor: Int) {
        let configuration = BeaconsServiceConfiguration(uuidString: GlobalConfig.beaconUUID,
                                                        regionId: hardcodedRegionId,
                                                        major: major,
                                                        minor: minor)
        locationService.start(with: configuration)
        self.currentConfiguration = configuration
    }

    func startSavingBeaconData() {
        self.isScanning.accept(true)

        self.storeBeaconsDisposable = locationService.beaconsObservable
            .throttle(RxTimeInterval.seconds(saveBeaconsThrottleInSeconds), scheduler: MainScheduler.instance)
            .subscribe(onNext: { (beacons) in
                                beacons.forEach { (beacon) in
                                    self.realmStorage.store(beacon: beacon)
                                }
            }, onCompleted: {
                self.isScanning.accept(false)
            }, onDisposed: {
                self.isScanning.accept(false)
            })
    }

    func stopSavingBeaconData() {
        self.saveBeaconsDisposable?.dispose()
        self.saveBeaconsDisposable = nil
    }

    func startAutoFetchOfInfectedPeople() {
        DDLogDebug("Enabling auto fetcher")
        self.autoFetchDisposeBag = DisposeBag()
        Observable
            .array(from: self.sortedDiscoveries)
            .filter { $0.count > 0 }
            .throttle(RxTimeInterval.seconds(self.autoFetchTime), scheduler: MainScheduler.instance)
            .flatMap { _ in self.fetchAllInfectedIdentifiers() }
            .subscribe(onNext: { [weak self] response in
                self?.updateDashboardData(response: response)
                DDLogDebug("Next fetch \(Date())")
            }, onError: { error in
                DDLogDebug("error occured while fetch identifiers \(error)")
                
            }, onCompleted: {
                DDLogDebug("Auto fetch complited successfully")
            }, onDisposed: {
                DDLogDebug("Auto fetch disposed")
            })
            .disposed(by: self.autoFetchDisposeBag)
    }

    func stopAutoFetchOfInfectedPeople() {
        DDLogDebug("Stopping auto fetcher")
        self.autoFetchDisposeBag = nil
    }

    func reloadInfectedIds() {
        self.fetchAllInfectedIdentifiers().subscribe(onNext: { [weak self] (response) in
            self?.updateDashboardData(response: response)
        }).disposed(by: disposeBag)
    }

    private func fetchAllInfectedIdentifiers() -> Observable<InfectedIdsResponse> {
        return InfectedIdsService.fetchInfectedIds()
    }

    private func updateDashboardData(response: InfectedIdsResponse) {
        self.realmStorage.cleanupDiscoveries()

        if let infectedIdentifiersToStore = response.metInfectedIds {
            self.realmStorage.store(infectedIdentifiersMet: infectedIdentifiersToStore)
        }
        // Match ids with local database
        let oldDashboardData = SessionManager.shared.dashboardData
        let infectedMetCounter = self.realmStorage.infectedPeopleMetValue
        let status = DashboardData(riskLevel: infectedMetCounter,
                                   numberOfInfectedMet: infectedMetCounter,
                                   reportedSelfInfection: oldDashboardData.reportedSelfInfection,
                                   reportedRecovered: oldDashboardData.reportedRecovered)
        SessionManager.shared.dashboardData = status
    }
}
