//
//  WebViewController.swift
//  CoronaFight
//
//  Created by botichelli on 3/19/20.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class WebViewController: UIViewController {

    var webView: WKWebView?
    var urlToLoad: URL? = SessionManager.shared.webActionUrl

    override func viewDidLoad() {
        super.viewDidLoad()
        let configuration = WKWebViewConfiguration()
        webView = WKWebView.init(frame: view.bounds, configuration: configuration)
        webView?.translatesAutoresizingMaskIntoConstraints = false
        webView?.allowsBackForwardNavigationGestures = true

        //To Avoid going back
        if let rootVC = navigationController?.viewControllers.first {
            navigationController?.viewControllers = [rootVC, self]
        }

        self.view.addSubview(webView!)
        self.title = SessionManager.shared.webActionTitle
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let urlToLoad = urlToLoad {
            webView?.load(URLRequest(url: urlToLoad))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView?.stopLoading()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        guard let webView = self.webView else { return }

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
