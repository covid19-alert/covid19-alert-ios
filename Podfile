# Uncomment the next line to define a global platform for your project
platform :ios, '11.3'

project 'CoronaFight', 'DebugPersonal' => :debug

def main_pods
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for CoronaFight
  # MIT
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxRealm'
  pod 'SwiftDate', '~> 6.1'
  pod 'JGProgressHUD'
  pod 'Siren'
  pod 'SwiftyJot', :git => 'https://github.com/digitalindiana/SwiftyJot.git'

  #Apache License Version 2.0
  pod 'RealmSwift'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/DynamicLinks'
  pod 'Firebase/Messaging'

  # BSD-3
  pod 'CocoaLumberjack/Swift'

  #'as-is'
  pod 'CryptoSwift', '~> 1.0'
end

target 'CoronaFight' do
    main_pods
end

target 'Covid19Alert-Firebase' do
    main_pods
end
