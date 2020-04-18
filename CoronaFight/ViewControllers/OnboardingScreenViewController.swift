//
//  OnboardingScreenViewController.swift
//  CoronaFight
//
//  Created by botichelli on 3/18/20.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit

class OnboardingScreenViewController: UIViewController {
    @IBOutlet weak var featureImageView: UIImageView!
    @IBOutlet weak var featureTitleLabel: UILabel!
    @IBOutlet weak var featureDescriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupStrings()
        self.setupFonts()
    }

    func setupFonts() {
        featureTitleLabel.font = UIFont.boldMetricFont(size: 26)
        featureTitleLabel.adjustsFontForContentSizeCategory = true
        featureTitleLabel.adjustsFontSizeToFitWidth = true

        featureDescriptionLabel.font = UIFont.regularMetricFont(size: 23)
        featureDescriptionLabel.adjustsFontForContentSizeCategory = true
        featureDescriptionLabel.adjustsFontSizeToFitWidth = true
    }
    
    func setupStrings() {
        DispatchQueue.main.async {
            guard let id = self.restorationIdentifier else {
                 return
            }

            if id == "id1" {
                self.view.tag = 0
                self.featureImageView?.image = UIImage(named: "onboarding_1")
                self.featureTitleLabel?.text = NSLocalizedString("About Covid-19 Alert!", comment: "")
                self.featureDescriptionLabel?.text = NSLocalizedString("This app warns about possible infection with Covid-19. We inform you when you have been near an infected person and provide you with important and useful information about the pandemic. This way you can help to delay the further spread of Covid-19.", comment: "")
            } else if id == "id2" {
                self.view.tag = 1
                self.featureImageView?.image = UIImage(named: "onboarding_2")
                self.featureTitleLabel?.text = NSLocalizedString("Secure & Anonymous", comment: "")
                self.featureDescriptionLabel?.text = NSLocalizedString("The Covid-19 Alert! app works with bluetooth data. It registers if your mobile phone has been near a mobile phone of an infected person who is using the app. This app also provides health authorities insight into the geographical spread of the virus. However, privacy is guaranteed: the use of the app is completely anonymous and it’s impossible to trace either you or your phone.", comment: "")
            } else if id == "id3" {
                self.view.tag = 3
                self.featureImageView?.image = UIImage(named: "onboarding_3")
                self.featureTitleLabel?.text = NSLocalizedString("What should you do?", comment: "")
                self.featureDescriptionLabel?.text = NSLocalizedString("Keep the app running in the background all the time and check it from time to time. In order to stay healthy, wash your hands, practice social distancing, don’t touch your face and #stayathome as much as possible.", comment: "")
            }
        }
    }
}
