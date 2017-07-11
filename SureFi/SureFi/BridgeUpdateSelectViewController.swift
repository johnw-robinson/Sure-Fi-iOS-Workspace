//
//  BridgeUpdateSelectViewController.swift
//  SureFi
//
//  Created by John Robinson on 7/3/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import AVFoundation

class BridgeUpdateSelectViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var bridgeUpdateTableViewController: BridgeUpdateTableViewController!
    
    @IBOutlet var cameraView: UIView!
    //@IBOutlet var deviceListView: UIView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var instructionsLabel: UILabel!
    
    var captureSession = AVCaptureSession();
    var sessionOutput = AVCapturePhotoOutput();
    var sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG]);
    var previewLayer = AVCaptureVideoPreviewLayer();
    
    var selectedDeviceID: String!
    var selectedDeviceStatus: String!
    var scannedDeviceID: String!
    var deviceFound: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        selectedDeviceID = ""
        selectedDeviceStatus = ""
        scannedDeviceID = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                
                if(bridgeUpdateTableViewController.surefiDevices.count==0) {
                    self.setDeviceFound(found: false, deviceID: "", msg: "", status: "")
                } else {
                    
                    for (key,value) in bridgeUpdateTableViewController.surefiAdvertising {
                        
                        let manufacturerDataString = value as? String ?? ""
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
                            self.setDeviceFound(found: true, deviceID: scannedDeviceID, msg: "", status: status)
                            return
                        }
                    }
                    self.setDeviceFound(found: false, deviceID: "", msg: "Device (\(scannedDeviceID!)) Not Found with Bluetooth", status: "XX")
                }
            }
        }
    }
    
    func setDeviceFound (found: Bool, deviceID: String, msg: String, status: String) {
        deviceFound = found
        selectedDeviceID = deviceID
        selectedDeviceStatus = status
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
    
    func getDeviceFound () -> Bool {
        return deviceFound
    }
    
    
    @IBAction func confirmButtonPress (sender: UIButton) {
        
        bridgeUpdateTableViewController.deviceID = selectedDeviceID
        bridgeUpdateTableViewController.tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func clearButtonPress (sender: UIButton) {
        messageLabel.text = ""
        cameraView.layer.borderColor = UIColor.gray.cgColor
        captureSession.startRunning()
        //selectDeviceTableViewController.selectedDeviceID = ""
        //selectDeviceTableViewController.tableView.reloadData()
        scannedDeviceID = ""
        clearButton.isHidden = true
        self.setDeviceFound(found: false, deviceID: "", msg: "", status: "")
    }
    
}
