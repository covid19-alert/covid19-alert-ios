//
//  OnScreenAlertPresentationController.swift
//  CoronaFight
//
//  Created by Piotr Adamczak on 15/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit

class OnScreenAlertPresentationController: UIPresentationController {

    var blackView = UIView()

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerBounds = containerView?.bounds else { return CGRect(x: 0, y: 0, width: 300, height: 300)}
        let oneThirdOfContainer = containerBounds.height / 2.5
        return  CGRect(x: 28, y: containerBounds.midY - (oneThirdOfContainer * 0.5),
                       width: containerBounds.width - 60, height: oneThirdOfContainer)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        guard let containerView = containerView else { return }

        blackView.alpha = 0.0
        blackView.backgroundColor = UIColor.black
        blackView.frame = containerView.bounds
        containerView.addSubview(blackView)

        UIView.animate(withDuration: 0.3) {
            self.blackView.alpha = 0.8
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        UIView.animate(withDuration: 0.3, animations: {
            self.blackView.alpha = 0.0
        }) { (complete) in
            self.blackView.removeFromSuperview()
        }
    }
}
