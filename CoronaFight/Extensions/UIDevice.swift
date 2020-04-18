//
//  UIDevice.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 18/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit

struct ScreenSize
{
  static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
  static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
  static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
  static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH,    ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
  static let IS_IPHONE_4_OR_LESS  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
  static let IS_IPHONE_5          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
  static let IS_IPHONE_6          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
  static let IS_IPHONE_6P         = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
  static let IS_IPAD              = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH   == 1024.0
  static let IS_IPAD_PRO          = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH   == 1366.0
}
