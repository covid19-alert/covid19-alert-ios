//
//  RegisterViewController.swift
//  CoronaFight
//
//  Created by Dima on 15/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxRealm
import SwiftDate
import JGProgressHUD
import CocoaLumberjack

enum PermissionPerView: Int {
    case pushNotification = 0
    case bluetooth
    case location
}
 
// TODO that one need to be opened only if user is not registered,
class OnboardingViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var onboardingButton: UIButton!
    var askedForPermissions: [PermissionPerView] = []
    private let disposableBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        if SessionManager.shared.isRegistered == true ||
           !FeatureFlagManager.isFeatureFlagEnabled(.onboarding) {
            onboardingFinished(animated: false)
        }
    }

    func onboardingFinished(animated: Bool) {
        DDLogDebug("Open register")
        let identifier = animated ? "RegisterViewControllerSeque" : "RegisterViewControllerStaticSeque"
        self.performSegue(withIdentifier: identifier, sender: nil)
    }

    func pageChanged(currentPage: Int) {
        if let permissionToAsk = PermissionPerView(rawValue: currentPage),
               askedForPermissions.contains(permissionToAsk) == false {

            DDLogDebug("Ask for permission \(permissionToAsk)")

            switch permissionToAsk {
            case .pushNotification:
                 if FeatureFlagManager.isFeatureFlagEnabled(.pushNotifications) {
                    UIApplication.sharedDelegate.setupPushNotifications()
                 }
            case .bluetooth:
                DataCollectorService.shared.locationService.askForBluetoothPermission()
            case .location:
                DataCollectorService.shared.locationService.askForLocationPermission()
            }

            askedForPermissions.append(permissionToAsk)
        }
    }

    @IBAction func onboardingNextButtonAction(_ sender: Any) {

        if let pageViewController = self.children.first as? OnboardingPageViewController {
            let pagesCount = pageViewController.pages.count
            let currentPage = pageViewController.currentPageIndex
            if currentPage == pagesCount - 1 {
                pageChanged(currentPage: currentPage)
                onboardingFinished(animated: true)
            } else {
                pageViewController.goToNextPage()
            }
        }

    }
}

class OnboardingPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pages = [UIViewController]()
    var lastPageIndex: Int = 0
    var currentPageIndex: Int {
        get {
            return pages.firstIndex(of: self.viewControllers!.first!)!
        }
        set {
            guard newValue >= 0, newValue < pages.count else {
                return
            }

            let vc = pages[newValue]
            let direction: UIPageViewController.NavigationDirection = newValue > currentPageIndex ? .forward : .reverse
            self.setViewControllers([vc], direction: direction, animated: true, completion: nil)
            self.updateParent()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.dataSource = self

        let p1: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "id1")
        let p2: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "id2")
        let p3: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "id3")

        pages.append(p1)
        pages.append(p2)
        pages.append(p3)

        setViewControllers([p1], direction: .forward, animated: false, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateParent()
    }

    func updateParent() {
        if let parentOnboarding = self.parent as? OnboardingViewController {
            parentOnboarding.pageControl.numberOfPages = pages.count
            parentOnboarding.pageControl.currentPage = self.currentPageIndex

            if self.lastPageIndex != self.currentPageIndex {
                parentOnboarding.pageChanged(currentPage: self.lastPageIndex)
            }

            self.lastPageIndex = self.currentPageIndex
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        self.updateParent()
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController)-> UIViewController? {
        let cur = pages.firstIndex(of: viewController)!
        var prev = (cur - 1) % pages.count
        if prev < 0 {
            prev = pages.count - 1
        }
        return pages[prev]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController)-> UIViewController? {
        let cur = pages.firstIndex(of: viewController)!
        let nxt = abs((cur + 1) % pages.count)
        if cur == pages.count - 1 {
            return nil
        }
        return pages[nxt]
    }

    func presentationIndex(for pageViewController: UIPageViewController)-> Int {
        return pages.count
    }

    func goToNextPage(){
        self.currentPageIndex += 1
    }
}
