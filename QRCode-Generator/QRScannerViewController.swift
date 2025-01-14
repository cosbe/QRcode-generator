//
//  QRScannerViewController.swift
//  QRCode-Generator
//
//  Created by Janet Liu on 3/31/18.
//  Copyright © 2018 Janet Liu. All rights reserved.
//

import AVFoundation
import UIKit
import Firebase

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer!
    var firebase: DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        firebase = Database.database().reference()
        
        let videoCaptureDevice = AVCaptureDevice.default(for: .video)
        
        if let videoCaptureDevice = videoCaptureDevice {
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                captureSession = AVCaptureSession()
                captureSession!.addInput(videoInput)
                
                let metadataOutput = AVCaptureMetadataOutput()
                captureSession!.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.frame = view.layer.bounds
                previewLayer.videoGravity = .resizeAspectFill
                view.layer.addSublayer(previewLayer)
                
                captureSession!.startRunning()
            } catch {
                return
            }
        }
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession!.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession!.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession!.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
        dismiss(animated: true)
    }
    
    func found(code: String) {
        print(code)
        let pipeKey = code.index(of: "|")
        let firebaseKey = code.substring(to: pipeKey!)
        firebase!.child("TempQRTeamInMatchDatas").observeSingleEvent(of: .value, with: { (snap) in
            self.firebase!.child("TempQRTeamInMatchDatas").child("\(firebaseKey)").setValue("\(code)")
            self.navigationController!.popViewController(animated: true)
        })
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
