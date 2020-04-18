//
//  IntermediateInfoViewController.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 30/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit

class IntermediateInfoViewController: UIViewController {
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var noteHeader: UILabel!
    @IBOutlet weak var noteText: UILabel!

    override func viewDidLoad() {
        self.setupStrings()
    }

    private func setupStrings() {
        self.title = NSLocalizedString("Self-assesment information", comment: "")

        self.cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        self.continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        self.noteHeader.text = NSLocalizedString("Note", comment: "")
        self.noteText.text = NSLocalizedString("Result of self-assessment won't influence Risk measurement", comment: "")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.continueButton.layer.cornerRadius = self.continueButton.frame.height / 2.0
        self.cancelButton.layer.cornerRadius = self.cancelButton.frame.height / 2.0
        self.cancelButton.layer.borderWidth = 2
        self.cancelButton.layer.borderColor = UIColor(red: 0.298, green: 0.271, blue: 0.953, alpha: 1).cgColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let smallDevice = (DeviceType.IS_IPHONE_5 || DeviceType.IS_IPHONE_4_OR_LESS)
        self.navigationController?.navigationBar.prefersLargeTitles = !smallDevice
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }

    @IBAction func continueAction(_ sender: Any) {
        self.openWebViewAnimated()
    }

    @IBAction func cancelAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    private func openWebViewAnimated() {
        self.performSegue(withIdentifier: "WebViewSegueAnimated", sender: self)
    }
}
