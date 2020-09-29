//
//  DetektController.swift
//  Detekt
//
//  Created by Caden Kowalski on 6/7/19.
//  Copyright © 2019 Caden Kowalski. All rights reserved.
//

import UIKit
import AVKit
import Vision
import Photos
import CoreData

class DetektController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, UIApplicationDelegate {
    
    // Intitializes global variables
    var topImage: UIImage?
    var totalFrames = 0
    var paused = false
    var cameraState = true
    @IBOutlet weak var wikiBtn: UIButton!
    @IBOutlet weak var infoBtn: UIButton!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var cameraBtn: UIButton!
    @IBOutlet weak var settingsBtn: UIButton!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var objectLbl: UILabel!
    @IBOutlet weak var smartNNLbl: UILabel!
    @IBOutlet weak var colorSchemeLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var smartNNSwitch: UISwitch!
    @IBOutlet weak var pictureTakenView: UIView!
    @IBOutlet weak var capturedFramesLbl: UILabel!
    @IBOutlet weak var redColorSchemeBtn: UIButton!
    @IBOutlet weak var grayColorSchemeBtn: UIButton!
    @IBOutlet weak var blueColorSchemeBtn: UIButton!
    @IBOutlet weak var greenColorSchemeBtn: UIButton!
    @IBOutlet var settingsTapGestureRecognizer: UITapGestureRecognizer!
    let captureDevice = AVCaptureDevice.default(for: .video)!
    let photoOutput = AVCapturePhotoOutput()
    let captureSession = AVCaptureSession()
    var textColor = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        setLayout()
        
        // Initializes the capture session
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // Adds the session input
        guard let Input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(Input)
        photoOutput.isHighResolutionCaptureEnabled = true
        
        // Adds the session outputs
        captureSession.addOutput(photoOutput)
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        // Configures capture session
        captureSession.commitConfiguration()
        captureSession.startRunning()
        
        // Adds the output layer
        let outputLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        outputLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        outputLayer.frame = cameraView.layer.bounds
        outputLayer.cornerRadius = 20
        cameraView.layer.addSublayer(outputLayer)
    }
    
    // Formats the UI
    func setLayout() {
        // Hides secondary views
        settingsView.isHidden = true
        pictureTakenView.isHidden = true
        
        // Formats the settings view
        settingsView.layer.cornerRadius = 20
        pictureTakenView.layer.cornerRadius = 20
        redColorSchemeBtn.layer.cornerRadius = 5
        grayColorSchemeBtn.layer.borderWidth = 2
        grayColorSchemeBtn.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        grayColorSchemeBtn.layer.cornerRadius = 5
        blueColorSchemeBtn.layer.cornerRadius = 5
        greenColorSchemeBtn.layer.cornerRadius = 5
        
        // Formats the flash button
        flashBtn.frame = CGRect(x: view.frame.minX + 48, y: cameraView.frame.maxY + 8, width: 33, height: 33)
        flashBtn.setImage(#imageLiteral(resourceName: "cameraFlashOff"), for: .normal)
        flashBtn.addTarget(self, action: #selector(Flash), for: .touchUpInside)
        view.insertSubview(flashBtn, at: 0)
    }
    
    // Image processing
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if cameraState && !paused {
            totalFrames += 1
            updateFrames()
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            // Fetches the model
            guard var Model = try? VNCoreMLModel(for: Resnet50().model) else { return }
            if smartNN! {
                Model = try! VNCoreMLModel(for: Resnet50().model)
            } else {
                Model = try! VNCoreMLModel(for: SqueezeNet().model)
            }
            
            // Requests data from the model and outputs data to display labels
            let Request = VNCoreMLRequest(model: Model) { (finishedReq, err) in
                guard let Results = finishedReq.results as? [VNClassificationObservation] else { return }
                guard let firstObservation = Results.first else {return }
                let Confidence = Int(firstObservation.confidence * 100)
                let Object = firstObservation.identifier
                self.updateObject(Object: Object)
                self.updateConfidence(Confidence: Confidence)
            }
            
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([Request])
        }
    }
    
    // Opens and closes the settings
    @IBAction func Settings(_ sender: Any) {
        if smartNN {
            smartNNSwitch.isOn = true
        } else {
            smartNNSwitch.isOn = false
        }
        if settingsView.isHidden {
            settingsView.isHidden = false
            cameraState = false
        } else {
            settingsView.isHidden = true
            if paused {
                cameraState = false
            } else {
                cameraState = true
            }
        }
    }
    
    // Plays and pauses the image capturing
    @IBAction func playPause(_ sender: Any) {
        if paused {
            paused = false
            cameraState = true
            pauseBtn.setImage(#imageLiteral(resourceName: "pauseImage"), for: .normal)
        } else {
            paused = true
            pauseBtn.setImage(#imageLiteral(resourceName: "playImage"), for: .normal)
        }
    }
    
    // Updates the frames label
    func updateFrames() {
        DispatchQueue.main.async {
            self.capturedFramesLbl.text = "Captured Frames: \(self.totalFrames)"
        }
    }
    
    // Updates the object label
    func updateObject(Object: String) {
        DispatchQueue.main.async {
            self.objectLbl.text = "Object: \(Object)"
        }
    }
    
    // Updates the confidence label
    func updateConfidence(Confidence: Int) {
        DispatchQueue.main.async {
            self.confidenceLbl.text = "Confidence: \(Confidence)%"
        }
    }
    
    // Updates the intelligence of the neural network
    @IBAction func nNIntelligence(_ sender: UISwitch) {
        if sender.isOn == true {
            smartNN = true
        } else {
            smartNN = false
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
        do {
            let fetchResults = try context.fetch(fetchRequest)
            for data in fetchResults as! [NSManagedObject] {
                let smartNeuralNet = data
                smartNeuralNet.setValue(smartNN, forKey: "smartNeuralNet")
            }
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    // Updates the text color
    @IBAction func textColor(_ sender: UIButton) {
        let colorSchemeBtns = [redColorSchemeBtn, grayColorSchemeBtn, blueColorSchemeBtn, greenColorSchemeBtn]
        textColor = sender.backgroundColor!
        sender.layer.borderWidth = 2
        sender.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        for colorSchemeBtn in colorSchemeBtns where colorSchemeBtn != sender {
            switch colorSchemeBtn!.layer.borderColor {
            case #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0):
                colorSchemeBtn!.layer.borderColor = colorSchemeBtn!.layer.backgroundColor
            default:
                break
            }
        }
        
        capturedFramesLbl.textColor = textColor
        objectLbl.textColor = textColor
        confidenceLbl.textColor = textColor
        smartNNLbl.textColor = textColor
        smartNNSwitch.onTintColor = textColor
        colorSchemeLbl.textColor = textColor
    }
    
    // Turns on and off the flash
    @objc func Flash() {
        do {
            try captureDevice.lockForConfiguration()
            if captureDevice.torchMode == .on {
                flashBtn.setImage(#imageLiteral(resourceName: "cameraFlashOff"), for: .normal)
                captureDevice.torchMode = .off
            } else {
                flashBtn.setImage(#imageLiteral(resourceName: "cameraFlashOn"), for: .normal)
                captureDevice.torchMode = .on
            }
            captureDevice.unlockForConfiguration()
        } catch {
            print("Unable to access the flash")
        }
    }
    
    // Takes the user to the wikipedia page on neural networks
    @IBAction func nNWiki(_ sender: Any) {
        if let wikiURL = URL(string: "https://en.wikipedia.org/wiki/Artificial_neural_network") {
            UIApplication.shared.open(wikiURL)
        }
    }
    
    // Takes picture
    @IBAction func Camera(_ sender: Any) {
        pictureTakenView.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.pictureTakenView.isHidden = true
        })
        
        DispatchQueue.global(qos: .background).async {
            let photoSettings: AVCapturePhotoSettings
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format:
                    [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                photoSettings = AVCapturePhotoSettings()
            }
            
            if self.captureDevice.torchMode == .on {
                photoSettings.flashMode = .on
            } else {
                photoSettings.flashMode = .off
            }
            
            photoSettings.isAutoStillImageStabilizationEnabled = self.photoOutput.isStillImageStabilizationSupported
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // Saves the image to photos
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
                
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
            })
        }
    }
}
