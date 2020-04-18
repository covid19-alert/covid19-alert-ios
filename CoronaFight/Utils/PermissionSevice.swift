//
//  PermissionSevice.swift
//  CoronaFight
//
//  Created by botichelli on 3/25/20.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation
import CoreBluetooth

class PermissionService {
    
    static var permissionsSubject: Observable<(CLAuthorizationStatus, CBManagerState)> {
        get {
            let locationPermission = DataCollectorService.shared.locationService.permissionStatusObservable
            let bluetoothPermission = DataCollectorService.shared.locationService.peripheralManagerObservable
            
            return Observable.combineLatest(locationPermission, bluetoothPermission)
        }
    }
}
