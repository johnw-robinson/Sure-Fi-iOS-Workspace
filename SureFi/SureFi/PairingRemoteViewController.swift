//
//  PairingRemoteViewController.swift
//  SureFi
//
//  Created by John Robinson on 6/15/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation

class PairingRemoteViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate  {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var pairingTableViewController: PairingTableViewController!
    
    var captureSession = AVCaptureSession();
    var sessionOutput = AVCapturePhotoOutput();
    var sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG]);
    var previewLayer = AVCaptureVideoPreviewLayer();
    
    var selectedDeviceID: String!
    var selectedDeviceStatus: String!
    var scannedDeviceID: String!
    var deviceFound: Bool = false
    
    var remoteImage: UIImage!
    
    @IBOutlet var scannerContainerView: UIView!
    @IBOutlet var cameraView: UIView!
    @IBOutlet var cameraBackgroundImageView: UIImageView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var instructionsLabel: UILabel!
    @IBOutlet var takeImageButton: UIButton!
    
    @IBOutlet var configureContainerView: UIView!
    @IBOutlet var remoteImageView: UIImageView!
    
    @IBOutlet var remoteDescTextView: UITextView!
    @IBOutlet var continueButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Step 2 - Setup Remote"
        
        configureContainerView.isHidden = true
        
        remoteImageView.layer.borderColor = UIColor.gray.cgColor
        remoteImageView.layer.borderWidth = 0.5
        remoteImageView.layer.cornerRadius = 5
        remoteImageView.clipsToBounds = true
        
        takeImageButton.layer.cornerRadius = 5
        takeImageButton.clipsToBounds = true
        
        remoteDescTextView.layer.borderColor = UIColor.gray.cgColor
        remoteDescTextView.layer.borderWidth = 0.5
        
        remoteDescTextView.text = "Please provide a description...\n\nExample - This Sure-Fi Remote Unit is connected to a weigand keypad from XYZ Company"
        remoteDescTextView.textColor = .gray

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        let deviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInTelephotoCamera,AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified)
        for device in (deviceDiscoverySession?.devices)! {
            if(device.position == AVCaptureDevicePosition.back){
                do{
                    let input = try AVCaptureDeviceInput(device: device)
                    if(captureSession.canAddInput(input)){
                        captureSession.addInput(input);
                        
                        let captureMetadataOutput = AVCaptureMetadataOutput()
                        captureSession.addOutput(captureMetadataOutput)
                        
                        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
                        
                        if(captureSession.canAddOutput(sessionOutput)){
                            captureSession.addOutput(sessionOutput);
                            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
                            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                            previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait;
                            cameraView.layer.addSublayer(previewLayer);
                            previewLayer.frame = cameraView.bounds
                            captureSession.startRunning()
                        }
                    }
                }
                catch{
                    print("exception!");
                }
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            //let barCodeObject = previewLayer.transformedMetadataObject(for: metadataObj ) as! AVMetadataMachineReadableCodeObject
            //cameraView?.frame = barCodeObject.bounds;
            
            if metadataObj.stringValue != nil {
                scannedDeviceID = metadataObj.stringValue.uppercased()
                captureSession.stopRunning()
                clearButton.isHidden = false
                
                if(pairingTableViewController.surefiDevices.count==0) {
                    self.setDeviceFound(found: false, deviceID: "", msg: "", status: "")
                } else {
                    
                    for device in pairingTableViewController.surefiDevicesData {
                        
                        let advertisementData = device
                        
                        let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data ?? Data()
                        let manufacturerDataString = manufacturerData.hexStringFromData()
                        var peripheralDeviceID = manufacturerDataString
                        var deviceStatusString = ""
                        
                        
                        if peripheralDeviceID.substring(to: 4).uppercased() == "FFFF" {
                            deviceStatusString = peripheralDeviceID.substring(from: 4).substring(to: 8)
                            peripheralDeviceID = peripheralDeviceID.substring(from: 12).substring(to: 6)
                        } else {
                            deviceStatusString = peripheralDeviceID.substring(from: 0).substring(to: 8)
                            peripheralDeviceID = peripheralDeviceID.substring(from: 8).substring(to: 6)
                        }
                        
                        if peripheralDeviceID.uppercased().range(of: scannedDeviceID.uppercased()) != nil {
                            
                            let status = deviceStatusString.substring(from: 6).substring(to: 2)
                            if  status != "01" {
                                self.setDeviceFound(found: false, deviceID: "", msg: "Device is not in Pairing Mode", status: status)
                                return
                            }
                            if deviceStatusString.substring(to: 2) == "02" {
                                self.setDeviceFound(found: true, deviceID: scannedDeviceID, msg: "", status: "01")
                                return
                            } else {
                                self.setDeviceFound(found: false, deviceID: "", msg: "Device (\(scannedDeviceID!)) Not Sure-Fi Bridge Remote Unit", status: "01")
                                return
                            }
                        } else {
                            self.setDeviceFound(found: false, deviceID: "", msg: "Device (\(scannedDeviceID!)) Not Found with Bluetooth", status: "XX")
                        }
                    }
                }
            }
        }
    }
    
    func setDeviceFound (found: Bool, deviceID: String, msg: String, status: String) {
        deviceFound = found
        selectedDeviceID = deviceID
        selectedDeviceStatus = status
        print("Selected:\(selectedDeviceID) Status:\(selectedDeviceStatus)")
        if deviceFound {
            confirmButton.isHidden = false
            self.messageLabel.text = "Device Found (\(deviceID))"
            self.messageLabel.textColor = UIColor.green
        }
        else {
            confirmButton.isHidden = true
            if(scannedDeviceID != "") {
                self.messageLabel.text = msg
                self.messageLabel.textColor = UIColor.red
            }
        }
    }
    
    @IBAction func confirmButtonPress (sender: UIButton) {
        
        self.configureContainerView.alpha = 0
        self.configureContainerView.isHidden = false
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.scannerContainerView.alpha = 0
            self.configureContainerView.alpha = 1
        })
    }
    
    @IBAction func clearButtonPress (sender: UIButton) {
        messageLabel.text = ""
        cameraView.layer.borderColor = UIColor.gray.cgColor
        captureSession.startRunning()
        scannedDeviceID = ""
        clearButton.isHidden = true
        self.setDeviceFound(found: false, deviceID: "", msg: "", status: "")
    }
    
    @IBAction func takePictureButtonPress(sender: UIButton) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func exampleButtonPress(sender: UIButton) {
        
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PairingExamplesViewController") as! PairingExamplesViewController
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
    @IBAction func continueButtonPress (sender: UIButton) {
        
        pairingTableViewController.remoteImage = remoteImage
        pairingTableViewController.remoteDescription = remoteDescTextView.text
        pairingTableViewController.remoteDeviceID = selectedDeviceID
        
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PairingSystemViewController") as! PairingSystemViewController
        controller.pairingTableViewController = pairingTableViewController
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.text.range(of: "Please provide a description...") != nil {
            textView.text = ""
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        var text = remoteDescTextView.text
        if text?.range(of: "Please provide a description...") != nil {
            text = ""
        }
        
        if text != "" && remoteImage != nil {
            continueButton.isHidden = false
        } else {
            continueButton.isHidden = true
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info["UIImagePickerControllerEditedImage"] as? UIImage
        self.dismiss(animated: true, completion: nil)
        
        if image != nil {
            remoteImage = image
            remoteImageView.image = image
        }
        
        var text = remoteDescTextView.text
        if text?.range(of: "Please provide a description...") != nil {
            text = ""
        }
        
        if text != "" && remoteImage != nil {
            continueButton.isHidden = false
        } else {
            continueButton.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
