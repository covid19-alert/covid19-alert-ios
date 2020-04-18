//
//  AppDelegate.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import UIKit
import RxSwift
import JGProgressHUD
import Siren
import Firebase
import FirebaseDynamicLinks
import FirebaseMessaging
import CocoaLumberjack
import Security

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let logHelper = LogHelper.shared
    let disposableBag = DisposeBag()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        LogHelper.fancyBanner(forMessage: "CoronaFight has started")

        UIApplication.shared.isIdleTimerDisabled = true
        self.adjustGlobalNavigationBarAppearance()
//        FirebaseApp.configure()
        setupAppUpdate()

        return true
    }

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamicLink, error) in
            print("Dynamic link \(String(describing: dynamicLink?.url?.absoluteString))")
        }

        return handled
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let dynamicLinkUrl = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url)?.url {
            print("Recived deeplink: \(dynamicLinkUrl.absoluteString))")
            DeeplinkManager.shared.storeDeeplink(url: dynamicLinkUrl)
            return true
        }
        return false
    }

    func setupPushNotifications() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })

        Messaging.messaging().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }

    func adjustGlobalNavigationBarAppearance() {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(named: "dashboardText")!,
            .font: UIFont.boldSystemFont(ofSize: 26.0)
        ]

        if #available(iOS 13.0, *) {
            let coloredAppearance = UINavigationBarAppearance()
            coloredAppearance.configureWithTransparentBackground()
            coloredAppearance.largeTitleTextAttributes = textAttributes
            UINavigationBar.appearance().standardAppearance = coloredAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        } else {
            let img = UIImage()
            UINavigationBar.appearance().shadowImage = img
            UINavigationBar.appearance().setBackgroundImage(img, for: .default)
            UINavigationBar.appearance().backgroundColor = UIColor.clear
            UINavigationBar.appearance().titleTextAttributes = textAttributes
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        DDLogDebug("willEnterForeground")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        DDLogDebug("didEnterBackground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DDLogDebug("didBecomeActive")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        DDLogDebug("willResignActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DDLogDebug("willTerminate")
    }

    static func generateSecureKey() -> Data {
        let keySize = 64
        var key = Data(count: keySize)
        let status = key.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, keySize, $0.baseAddress!)
        }
        if status != errSecSuccess {
            DDLogError("Couldn't generate secure random key, status: \(status)")
            assertionFailure("Couldn't generate secure random key, status: \(status)")
        }
        return key
    }

    static func setupDataCollector() {
        guard let minor = SessionManager.shared.minor,
              let major = SessionManager.shared.major else {
            DDLogDebug("Cannot start data collection without minor and major data")
            return
        }
        DataCollectorService.shared.start(major: major, minor: minor)
        DataCollectorService.shared.startLocationUpdates()
    }

    func setupAppUpdate() {
        let siren = Siren.shared
        let rule = Rules(promptFrequency: .daily, forAlertType: .option)
        siren.rulesManager = .init(globalRules: rule, showAlertAfterCurrentVersionHasBeenReleasedForDays: 1)
        siren.wail()
    }

    /// temporarly here...
    func showConfirmationHUD(with text: String, time: TimeInterval = 1.5, success: Bool = true) {
        let topView = self.getTopViewController()!.view
        let hud = JGProgressHUD(style: .light)
        hud.textLabel.text = text
        if success {
            hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        } else {
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
        }
        hud.show(in: topView!)
        hud.dismiss(afterDelay: time)
    }

    func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)

        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)

        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("[Notifications] Got notification \(userInfo)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[Notifications] Failed to register: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken as Data
        print("[Notifications] Registered for notification")
    }
}

extension UIApplication {
    static var sharedDelegate: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("[Notifications] Got token FCM \(fcmToken)")
        DataCollectorService.shared.firebaseTokenSubject.onNext(fcmToken)
    }
}
