//
//  RealmStorage.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm
import CoreLocation
import CocoaLumberjack

class RealmStorage {
    private static let preEncryptionConfiguration = Realm.Configuration(schemaVersion: 1) // used only to open db in non encrypted version
    private static var commonConfiguration: Realm.Configuration!
    private let encryptedRealmName = "encrypted.realm"
    private lazy var encryptedRealmPath = {
        FileManager.default.documentsUrl.appendingPathComponent(self.encryptedRealmName)}()

    private(set) lazy var realm: Realm = self.constructRealm()

    private lazy var allDiscoveredUsers = {
        return Observable.array(from: realm.objects(BeaconDiscovery.self).distinct(by: ["uuid", "major", "minor"]))
    }()

    private lazy var allInfectedIds: Observable<[InfectedIdentifierRealm]> = {
         return Observable.array(from: realm.objects(InfectedIdentifierRealm.self))
    }()

    private lazy var infectedIdsMet: [InfectedIdentifierRealm] = {
        let allDiscoveries: [String] = Array(realm.objects(BeaconDiscovery.self).distinct(by: ["uuid", "major", "minor"])).map({ $0.seenUserId() })
        return Array(realm.objects(InfectedIdentifierRealm.self).filter( { allDiscoveries.contains($0.identifier) } ))
    }()

    var peopleMet: Observable<Int> {
        return allDiscoveredUsers.map { $0.count }
    }

    var infectedPeopleMetValue: Int {
        return infectedIdsMet.count
    }

    private var encryptionKey: Data

    required init(encryptionKey: Data) {
        self.encryptionKey = encryptionKey

        // Get our Realm file's parent directory
        let folderPath = realm.configuration.fileURL!.deletingLastPathComponent().path

        // Disable file protection for this directory
        try! FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: folderPath)
    }

    convenience init() {
        self.init(encryptionKey: SessionManager.shared.databaseKey)
    }

    private func loadCommonConfiguration() {
        if Self.commonConfiguration == nil {

            /*
            0 <= 1.0 (15)
            1 = 1.0 (16)
            1 = 1.0 (17) encryption enabled -> file path changed
            */
            Self.commonConfiguration = Realm.Configuration(
                fileURL: self.encryptedRealmPath,
                encryptionKey: self.encryptionKey,
                schemaVersion: 1,
                migrationBlock: { _, _ in
                // Nothing to do, new properties added
            })
        }
    }

    private func constructRealm() -> Realm {

        self.loadCommonConfiguration()
        self.migrateUnEncryptedIfNeeded()

        // Attempt to open the encrypted Realm
        do {
            return try Realm(configuration: Self.commonConfiguration)
        } catch {
            // If the encryption key was not accepted, the error will state that the database was invalid
            DDLogError("Cannot open Realm! Will stop app execution: \(error)")
            preconditionFailure("Cannot open Realm! \(error)")
        }
    }

    private func doesUnencryptedRealmExist() -> Bool {
        return FileManager.default.fileExists(atPath: Self.preEncryptionConfiguration.fileURL!.path)
    }

    private func doesEncryptedRealmExist() -> Bool {
        return FileManager.default.fileExists(atPath: self.encryptedRealmPath.path)
    }

    fileprivate func rewriteOldRealmToEncrypted() throws {
        // autoreleasepool here so that we're 101% sure all stuff inside realm will be released
        // at the moment of leaving this method!
        try autoreleasepool {
            DDLogDebug("opening unencrypted realm and trying to rewrite it...")
            let unencryptedRealm = try Realm(configuration: Self.preEncryptionConfiguration)
            try unencryptedRealm.writeCopy(toFile: self.encryptedRealmPath, encryptionKey: self.encryptionKey)
        }
    }

    fileprivate func deleteOldRealmFiles() throws {
        DDLogDebug("okay, we can now remove old database...")
        let realmURL = Self.preEncryptionConfiguration.fileURL!
        let realmURLs = [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("note"),
            realmURL.appendingPathExtension("management")
        ]
        for URL in realmURLs {
            do {
                try FileManager.default.removeItem(at: URL)
            } catch {
                DDLogError("We won't mind but couldn't remove file: \(URL) -> error \(error)")
            }
        }
    }

    private func migrateUnEncryptedIfNeeded() {
        // migrate when unencrypted exits but encrypted NOT
        if self.doesUnencryptedRealmExist() && self.doesEncryptedRealmExist() == false {
            DDLogDebug("okay, let's try to load old realm, convert it to encrypted one and delete...")
            do {
                try rewriteOldRealmToEncrypted()
                try deleteOldRealmFiles()
            } catch {
                // If the encryption key was not accepted, the error will state that the database was invalid
                DDLogError("Cannot open unencrypted realm... Don't worry, be happy, let's just go with new empty db...")
            }
        }
    }

    func store(beacon: CLBeacon) {
        let beaconDiscovery = BeaconDiscovery()
        beaconDiscovery.minor = beacon.minor.intValue
        beaconDiscovery.major = beacon.major.intValue
        beaconDiscovery.uuid = beacon.proximityUUID.uuidString
        beaconDiscovery.date = Date()
        beaconDiscovery.accuracy = beacon.rssi
        beaconDiscovery.proximityRaw = beacon.proximity.rawValue

        DDLogDebug("Realm is saving new BeaconDiscovery \(beacon.major.intValue):\(beacon.minor.intValue)...")

        try? realm.write() {
            realm.add(beaconDiscovery)
        }
    }

    func store(infectedIdentifiersMet: [String]) {
        let infectedPeopleMetRealm: [InfectedIdentifierRealm] = infectedIdentifiersMet.map {
            let infectedIdentifier = InfectedIdentifierRealm()
            infectedIdentifier.identifier = $0
            return infectedIdentifier
        }

        try? realm.write() {
            realm.add(infectedPeopleMetRealm, update: .all)
        }
    }

    func cleanupInfected() {
        let allObjects = realm.objects(InfectedIdentifierRealm.self)
        try! realm.write {
            realm.delete(allObjects)
        }
    }

    func cleanupDiscoveries() {
        let fourteenDays = TimeInterval(14 * 24 * 60 * 60)
        let cleanupDate = Date(timeIntervalSinceNow: -fourteenDays)
        let discoveriesToRemove = realm.objects(BeaconDiscovery.self).filter( { $0.date < cleanupDate } )
        DDLogDebug("Removing \(discoveriesToRemove.count) beacon discoveries")

        try! realm.write {
            realm.delete(discoveriesToRemove)
        }
    }

    func cleanAllData() {
        try! realm.write {
            realm.deleteAll()
        }
    }
}
