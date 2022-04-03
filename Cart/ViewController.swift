//
//  ViewController.swift
//  Cart
//
//  Created by Василий  on 03.04.2022.
//

import UIKit
import Vision
import VisionKit

class ViewController: UIViewController {
    
    private let numberCard: UILabel = {
        let lable = UILabel()
        lable.numberOfLines = 0
        lable.textAlignment = .center
        return lable
    }()
    
    
    private let expiryDateCard: UILabel = {
        let lable = UILabel()
        lable.numberOfLines = 0
        lable.textAlignment = .center
        return lable
    }()
    
    private let button: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "scan"), for: .normal)
        
//        button.titleLabel?.text = "Скан"
        return button
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
//        imageView.image = UIImage(named: "example2")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var imageScan: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(numberCard)
        view.addSubview(expiryDateCard)
        view.addSubview(button)
       
        
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        
//        validateImage(image: imageScan) { [weak self] result in
//            guard let self = self, let result = result else { return }
//            DispatchQueue.main.async {
//                self.numberCard.text = result.number
//                self.expiryDateCard.text = result.expiryDate
//            }
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateImage(image: imageScan) { [weak self] result in
            guard let self = self, let result = result else { return }
            DispatchQueue.main.async {
                self.numberCard.text = result.number
                self.expiryDateCard.text = result.expiryDate
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = CGRect(x: 20,
                                 y: view.safeAreaInsets.top,
                                 width: view.frame.size.width-40,
                                 height: view.frame.size.width-40)
        
        button.frame = CGRect(x: view.safeAreaInsets.top,
                              y: view.safeAreaInsets.top,
                              width: 50,
                              height: 50)
        
        numberCard.frame = CGRect(x: 20,
                                  y: view.frame.size.width + view.safeAreaInsets.top,
                                  width: view.frame.size.width-40,
                                  height: 200)
        
        expiryDateCard.frame = CGRect(x: 20,
                                      y: view.frame.size.width + view.safeAreaInsets.top + 20,
                                      width: view.frame.size.width-40,
                                      height: 200)
    }
    
    
    @objc func didTap() {
        configureDocumetnView()
    }
    func configureDocumetnView() {
        let scaneDocumentVC = VNDocumentCameraViewController()
        scaneDocumentVC.delegate = self
        self.present(scaneDocumentVC, animated: true)
    }
    
    func validateImage(image: UIImage?, completion: @escaping (CardDetails?) -> Void) {
        guard let cgImage = image?.cgImage else { return completion(nil) }
        
        var recognizedText = [String]()
        
        var textRecognitionRequest = VNRecognizeTextRequest()
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = false
        textRecognitionRequest.customWords = CardType.allCases.map { $0.rawValue } + ["Expiry Date"]
        textRecognitionRequest = VNRecognizeTextRequest() { (request, error) in
            guard let results = request.results,
                  !results.isEmpty,
                  let requestResults = request.results as? [VNRecognizedTextObservation]
            else { return completion(nil) }
            recognizedText = requestResults.compactMap { observation in
                return observation.topCandidates(1).first?.string
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
            completion(parseResults(for: recognizedText))
        } catch {
            print(error)
        }
    }
    
    func parseResults(for recognizedText: [String]) -> CardDetails {
        // Credit Card Number
        let creditCardNumber = recognizedText.first(where: { $0.count >= 14 && ["4", "5", "3", "6"].contains($0.first) })
        
        // Expiry Date
        let expiryDateString = recognizedText.first(where: { $0.count > 4 && $0.contains("/") })
        let expiryDate = expiryDateString?.filter({ $0.isNumber || $0 == "/" })
        
        // Name
        let ignoreList = ["GOOD THRU", "GOOD", "THRU", "Gold", "GOLD", "Standard", "STANDARD", "Platinum", "PLATINUM", "WORLD ELITE", "WORLD", "ELITE", "World Elite", "World", "Elite"]
        let wordsToAvoid = [creditCardNumber, expiryDateString] +
            ignoreList +
            CardType.allCases.map { $0.rawValue } +
            CardType.allCases.map { $0.rawValue.lowercased() }
            CardType.allCases.map { $0.rawValue.uppercased() }
        let name = recognizedText.filter({ !wordsToAvoid.contains($0) }).last
        
        return CardDetails(numberWithDelimiters: creditCardNumber, name: name, expiryDate: expiryDate)
    }
}

extension ViewController: VNDocumentCameraViewControllerDelegate {
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        for pageNumber in 0..<scan.pageCount {

            let image = scan.imageOfPage(at: pageNumber)
            self.imageScan = image
        }
        controller.dismiss(animated: true)
    }
}





