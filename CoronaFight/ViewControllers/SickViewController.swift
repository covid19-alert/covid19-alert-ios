//
//  SickViewController.swift
//  CoronaFight
//
//  Created by Przemysław Szurmak on 14/03/2020.
//  Copyright © 2020 Przemysław Szurmak. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import SwiftDate
import SwiftyJot

class SickViewController: UIViewController {
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    var datePicker: UIDatePicker!
    @IBOutlet weak var reportInfectionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateInputField: UITextField!

    @IBOutlet weak var proofLabel: UILabel!
    @IBOutlet weak var proofExplanationLabel: UILabel!
    @IBOutlet weak var proofImageView: UIImageView!

    private var disposeBag = DisposeBag()
    private var imagePicker: UIImagePickerController?
    private var proofSubjectValidation = BehaviorSubject<Bool>(value: false)

    var completion: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.bindButtons()
        self.setupStrings()
        self.setupDatePickers()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(collectProof(sender:)))
        proofImageView.isUserInteractionEnabled = true
        proofImageView.addGestureRecognizer(tapGestureRecognizer)

        if !FeatureFlagManager.isFeatureFlagEnabled(.photoProof) {
            proofLabel.isHidden = true
            proofExplanationLabel.isHidden = true
            proofImageView.isHidden = true
            self.proofSubjectValidation.onNext(true)
        }
    }
    
    private func setupStrings() {
        self.title = NSLocalizedString("Reported infection details", comment: "")
        reportInfectionLabel.text = NSLocalizedString("Add the date of your labatory diagnosis", comment: "")
        dateLabel.text = NSLocalizedString("Date", comment: "")
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        sendButton.setTitle(NSLocalizedString("Confirm", comment: ""), for: .normal)
        proofLabel.text = NSLocalizedString("Add a photo proof of your infection", comment: "")
        proofExplanationLabel.text = NSLocalizedString("It could be document from hospital. Do not worry, you can hide sensitive data", comment: "")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.sendButton.layer.cornerRadius = self.sendButton.frame.height / 2.0
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

    func bindButtons() {
        self.sendButton.isEnabled = false

        self.cancelButton.rx.tap.bind {
            self.dismissItself()
        }.disposed(by: self.disposeBag)

        self.sendButton.rx.tap.bind {
            self.sendSickInfo()
        }.disposed(by: self.disposeBag)

        let dateValidation = dateInputField.rx
            .text
            .map { $0?.isEmpty == false }
            .share(replay: 1)

        let proofValidation = proofSubjectValidation.asObserver()

        let enableButton = Observable.combineLatest(dateValidation, proofValidation)
        enableButton
            .map { $0.0 && $0.1 }
            .subscribe({ (event) in
                if let isEnabled = event.element {
                    self.sendButton.isEnabled = isEnabled
                    self.sendButton.alpha = isEnabled ? 1.0 : 0.3
                }
            })
            .disposed(by: disposeBag)
    }

    fileprivate func setupDatePickers() {
        self.datePicker = UIDatePicker()

        self.datePicker.datePickerMode = .date
        self.datePicker.minimumDate = "2020-01-01 12:00:00".toDate()?.date
        self.datePicker.maximumDate = Date()

        self.dateInputField.setInputView(datePicker: self.datePicker, target: self, selector: #selector(doneDate))
        self.dateInputField.placeholder = NSLocalizedString("dd/mm/yyyy", comment: "")
    }

    func dismissItself(inform: Bool = false) {
        self.navigationController?.popViewController(animated: true)
    }

    func sendSickInfo() {
        let errorText = NSLocalizedString("Error when sending informations", comment: "")
        let selectedTime = self.datePicker.date
        ReportInfectedService.report(testTime: selectedTime)
            .subscribe(
            onNext: { response in
                   if let dashboardData = response {
                        SessionManager.shared.dashboardData = dashboardData
                   }
            },
            onError: { error in
                print("Error when sending info \(error)")
                UIApplication.sharedDelegate
                    .showConfirmationHUD(with: errorText, time: 5.0, success: false)
            }) {
                print("successfully sent info!")
                self.dismissItself(inform: true)
        }
        .disposed(by: self.disposeBag)
    }

    @objc func collectProof(sender: Any) {
        let alert:UIAlertController = UIAlertController(title: NSLocalizedString("Choose image source", comment: ""),
                                                        message: nil,
                                                        preferredStyle: .actionSheet)

        let cameraAction = UIAlertAction(title: NSLocalizedString("Camera", comment: ""), style: .default) {
           _ in self.openCamera()
        }
        let galleryAction = UIAlertAction(title: NSLocalizedString("Photo library", comment: ""), style: .default) {
            _ in self.openPhotoLibrary()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) {
            _ in alert.dismiss(animated: true, completion: nil)
        }

        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.sourceView = self.view
        self.present(alert, animated: true, completion: nil)

        self.imagePicker = UIImagePickerController()
        self.imagePicker?.delegate = self
        self.imagePicker?.allowsEditing = false
    }

    func openCamera() {
        guard let imagePicker = self.imagePicker else { return }

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera;
            self.present(imagePicker, animated: true, completion: nil)
        }
    }

    func openPhotoLibrary() {
        guard let imagePicker = self.imagePicker else { return }

        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.sourceType = .savedPhotosAlbum;
            self.present(imagePicker, animated: true, completion: nil)
        }
    }

    @objc func doneDate() {
        self.handleDateInput(inputField: self.dateInputField, dateFormat: "dd/MM/yyyy")
    }

    func handleDateInput(inputField: UITextField, dateFormat: String) {
        if let datePicker = inputField.inputView as? UIDatePicker {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = dateFormat

            inputField.text = dateFormatter.string(from: datePicker.date)
        }
        inputField.resignFirstResponder()
    }
}

extension UITextField {

    func setInputView(datePicker: UIDatePicker, target: Any, selector: Selector) {
        self.inputView = datePicker

        let toolbar = UIToolbar()
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancel = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .plain, target: nil, action: #selector(tapCancel))
        let barButton = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .done, target: target, action: selector)
        toolbar.setItems([cancel, flexible, barButton], animated: false)

        toolbar.barStyle = .default
        toolbar.sizeToFit()

        self.inputAccessoryView = toolbar
    }

    @objc func tapCancel() {
        self.resignFirstResponder()
    }

}

extension SickViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        proofSubjectValidation.onNext(false)
        self.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.proofImageView.image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage)
        self.proofSubjectValidation.onNext(true)

        self.dismiss(animated: true) {
            let swiftyJot = SwiftyJot()
            var config = SwiftyJot.Config()
            config.backgroundColor = .white
            config.title = NSLocalizedString("Hide sensitive data if you want", comment: "")
            config.tintColor = .darkGray
            config.buttonBackgroundColor = .white
            config.brushColor = .black
            config.brushSize = 15.0
            config.showMenuButton = true
            config.showPaletteButton = false
            swiftyJot.config = config
            swiftyJot.present(sourceImageView: self.proofImageView, presentingViewController: self)

        }
    }
}
