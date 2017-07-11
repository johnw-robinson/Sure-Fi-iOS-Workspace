//
//  BridgeDevicePairTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 7/7/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import AVFoundation
import CoreBluetooth

class BridgeDevicePairTableViewController: UITableViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var sfBridgeController: SFBridgeController!
    var centralScannerView: UIView!
    var remoteScannerView: UIView!
    var centralStatusLabel: UILabel!
    var remoteStatusLabel: UILabel!
    
    var centralDeviceID: String = ""
    var centralDeviceMfgString: String = ""
    var remoteDeviceID: String = ""
    var remoteDeviceMfgString: String = ""
    
    var currentDeviceState: CBPeripheralState!
    var currentDeviceStatus: String = ""
    
    var captureSession: AVCaptureSession!
    var sessionOutput: AVCapturePhotoOutput!
    var sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG])
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sfBridgeController = SFBridgeController.shared
        currentDeviceState = sfBridgeController.devicePeripheral.state
        currentDeviceStatus = sfBridgeController.selectedDeviceStatus
        
        if sfBridgeController.selectedDeviceType == 1 {
            centralDeviceID = sfBridgeController.selectedDeviceID
            centralDeviceMfgString = sfBridgeController.getMfgString(deviceID: centralDeviceID)
        }
        else if sfBridgeController.selectedDeviceType == 2 {
            remoteDeviceID = sfBridgeController.selectedDeviceID
            remoteDeviceMfgString = sfBridgeController.getMfgString(deviceID: remoteDeviceID)
        }
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerTick(sender:)), userInfo: nil, repeats: true)
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = backgroundImageView
        
        self.navigationItem.title = "Pair Sure-Fi Bridge"
    }
    
    @IBAction func timerTick(sender: Timer) {
        
        if sfBridgeController.devicePeripheral.state != currentDeviceState {
            
            if currentDeviceState == .connected && sfBridgeController.devicePeripheral.state == .disconnected {
                sfBridgeController.connectDevice()
            }
        }
        if currentDeviceStatus != sfBridgeController.selectedDeviceStatus {
            print("Current Status:\(currentDeviceStatus) New Status:\(sfBridgeController.selectedDeviceStatus)")
            if currentDeviceStatus == "01" && sfBridgeController.selectedDeviceStatus == "02" {
                    let alertController = UIAlertController(title: "Pairing Complete", message: "The Pairing command has been sucessfully sent. Please test your Bridge and Confirm that it is functioning correctly.", preferredStyle: .alert)
                    let continueAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                        action in
                        self.navigationController?.pop(animated: true)
                    })
                    alertController.addAction(continueAction)
                    self.present(alertController, animated: true, completion: nil)
            }
            currentDeviceStatus = sfBridgeController.selectedDeviceStatus
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if centralDeviceID != "" && remoteDeviceID != "" {
            return 3
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 && (indexPath.section == 0 || indexPath.section == 1) {
            return 144
        }
        if indexPath.section == 2 && indexPath.row == 0 {
            return 48
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "DeviceDetailsCell", for: indexPath)
            let imageView = cell.viewWithTag(100) as! UIImageView!
            let titleLabel = cell.viewWithTag(200) as! UILabel
            let deviceIDLabel = cell.viewWithTag(300) as! UILabel
            centralStatusLabel = cell.viewWithTag(400) as! UILabel
            centralScannerView = cell.viewWithTag(500) as! UIView
            
            imageView!.layer.cornerRadius = 5
            imageView!.clipsToBounds = true
            titleLabel.text = "Central Unit"
            
            if centralDeviceID != "" && centralDeviceMfgString != "" {
                
                let manufacturerDataString = centralDeviceMfgString
                let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
                var hardwareStatus = manufacturerDataString.substring(from: 10).substring(to: 2)
                var deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
                let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
                
                var detailsString = ""
                switch hardwareType {
                case "01":
                    detailsString = "\(detailsString)Central Unit "
                case "02":
                    detailsString = "\(detailsString)Remote Unit "
                default:
                    detailsString = ""
                }
                if deviceID.uppercased()  == "FFFFFF" {
                    deviceID = "N/A"
                    hardwareStatus = "00"
                }
                
                switch hardwareStatus {
                case "00":
                    detailsString = "\(detailsString)Unregistered "
                case "01":
                    detailsString = "\(detailsString)Unpaired "
                case "02":
                    detailsString = "\(detailsString)Pairing to \(remoteID.uppercased()) "
                case "03":
                    detailsString = "\(detailsString)Paired to \(remoteID.uppercased()) "
                case "04":
                    detailsString = "\(detailsString)Deployed with \(remoteID.uppercased()) "
                default:
                    detailsString = ""
                }
                
                imageView!.image = UIImage(named: "central_unit_icon")
                
                deviceIDLabel.text = sfBridgeController.selectedDeviceID
                centralDeviceID = sfBridgeController.selectedDeviceID
                centralDeviceMfgString = sfBridgeController.getMfgString(deviceID: centralDeviceID)
                centralStatusLabel.text = detailsString
                stopScannerView(scannerView: centralScannerView)
            } else if centralDeviceID == "" {
                deviceIDLabel.text = "Scan Central Unit"
                centralStatusLabel.text = ""
                
                imageView!.image = UIImage(named: "scanner_background")
                startScannerView(scannerView: centralScannerView)
            }
        }
        if indexPath.section == 1 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "DeviceDetailsCell", for: indexPath)
            let imageView = cell.viewWithTag(100) as! UIImageView!
            let titleLabel = cell.viewWithTag(200) as! UILabel
            let deviceIDLabel = cell.viewWithTag(300) as! UILabel
            remoteStatusLabel = cell.viewWithTag(400) as! UILabel
            remoteScannerView = cell.viewWithTag(500) as! UIView
            
            imageView!.layer.cornerRadius = 5
            imageView!.clipsToBounds = true
            titleLabel.text = "Remote Unit"
            
            if remoteDeviceID != "" && remoteDeviceMfgString != "" {
                
                let manufacturerDataString = remoteDeviceMfgString
                let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
                var hardwareStatus = manufacturerDataString.substring(from: 10).substring(to: 2)
                var deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
                let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
                
                var detailsString = ""
                switch hardwareType {
                case "01":
                    detailsString = "\(detailsString)Central Unit "
                case "02":
                    detailsString = "\(detailsString)Remote Unit "
                default:
                    detailsString = ""
                }
                if deviceID.uppercased()  == "FFFFFF" {
                    deviceID = "N/A"
                    hardwareStatus = "00"
                }
                
                switch hardwareStatus {
                case "00":
                    detailsString = "\(detailsString)Unregistered "
                case "01":
                    detailsString = "\(detailsString)Unpaired "
                case "02":
                    detailsString = "\(detailsString)Pairing to \(remoteID.uppercased()) "
                case "03":
                    detailsString = "\(detailsString)Paired to \(remoteID.uppercased()) "
                case "04":
                    detailsString = "\(detailsString)Deployed with \(remoteID.uppercased()) "
                default:
                    detailsString = ""
                }
                
                imageView!.image = UIImage(named: "remote_unit_icon")
                
                deviceIDLabel.text = remoteDeviceID
                remoteStatusLabel.text = detailsString
                stopScannerView(scannerView: remoteScannerView)
            } else if remoteDeviceID == "" {
                deviceIDLabel.text = "Scan Remote Unit"
                remoteStatusLabel.text = ""
                
                imageView!.image = UIImage(named: "scanner_background")
                startScannerView(scannerView: remoteScannerView)
            }
        }
        if indexPath.section == 2 {
            cell = tableView.dequeueReusableCell(withIdentifier: "ContinueCell", for: indexPath)
            let continueButton = cell.viewWithTag(100) as! UIButton
            let resetButton = cell.viewWithTag(200) as! UIButton
            
            continueButton.addTarget(self, action: #selector(continueButtonPress(sender:)), for: .touchUpInside)
            continueButton.layer.cornerRadius = 5
            continueButton.clipsToBounds = true
            
            resetButton.addTarget(self, action: #selector(resetButtonPress(sender:)), for: .touchUpInside)
            resetButton.layer.cornerRadius = 5
            resetButton.clipsToBounds = true
        }
        cell.selectionStyle = .none
        return cell
    }
    
    @IBAction func continueButtonPress(sender: UIButton) {
        
        let alertController = UIAlertController(title: "Continue Pairing", message: "Are you sure you wish to Pair the following Sure-Fi Devices:\n\nCentral:\(centralDeviceID)\nto\nRemote:\(remoteDeviceID)", preferredStyle: .alert)
        let pairAction = UIAlertAction(title: "PAIR", style: .default, handler: {
            action in
            self.pairBridge()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(pairAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
        
        
    }
    
    func pairBridge() {
        let ret = sfBridgeController.pairBridge(centralDeviceID: centralDeviceID, remoteDeviceID: remoteDeviceID)
    }
    
    @IBAction func resetButtonPress(sender: UIButton) {
        
        if sfBridgeController.selectedDeviceID == centralDeviceID {
            remoteDeviceID = ""
            remoteDeviceMfgString = ""
            tableView.reloadData()
        }
        if sfBridgeController.selectedDeviceID == remoteDeviceID {
            centralDeviceID = ""
            centralDeviceMfgString = ""
            tableView.reloadData()
        }
    }
    
    func startScannerView(scannerView: UIView) {
        
        captureSession = AVCaptureSession()
        sessionOutput = AVCapturePhotoOutput()
        
        scannerView.layer.cornerRadius = 5
        scannerView.layer.borderColor = UIColor.gray.cgColor
        scannerView.layer.borderWidth = 2
        scannerView.clipsToBounds = true
        
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
                            scannerView.layer.addSublayer(previewLayer);
                            previewLayer.frame = scannerView.bounds
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
    
    func stopScannerView(scannerView: UIView) {
        
        scannerView.layer.cornerRadius = 5
        scannerView.layer.borderWidth = 0
        scannerView.clipsToBounds = true
        previewLayer.removeFromSuperlayer()
        
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            print("No QR code is detected")
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            //let barCodeObject = previewLayer.transformedMetadataObject(for: metadataObj ) as! AVMetadataMachineReadableCodeObject
            //cameraView?.frame = barCodeObject.bounds;
            
            if metadataObj.stringValue != nil {
                let scannedDeviceID = metadataObj.stringValue.uppercased()
                captureSession.stopRunning()
                //resetButton.isHidden = false
                
                let found = sfBridgeController.deviceExists(deviceID: scannedDeviceID)
                setDeviceFound(found: found, scannedDeviceID: scannedDeviceID)
            }
        }
    }
    
    func setDeviceFound(found: Bool, scannedDeviceID: String) {
        
        if sfBridgeController.selectedDeviceType == 1 {
            
            let manufacturerDataString = sfBridgeController.getMfgString(deviceID: scannedDeviceID)
            let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
            let hardwareStatus = manufacturerDataString.substring(from: 10).substring(to: 2)
            //let deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
            //let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
            
            if hardwareType == "01" {
                let alertController = UIAlertController(title: "Pairing Error", message: "Device \(scannedDeviceID) is a Sure-Fi Central Unit. You need to pair to a Sure-Fi Remote Unit.", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: {
                    action in
                    self.captureSession.startRunning()
                })
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            } else if hardwareStatus != "01" {
                let alertController = UIAlertController(title: "Pairing Error", message: "Device \(scannedDeviceID) is not currently in Pairing Mode. Please Unpair this device before proceeding.", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: {
                    action in
                    self.captureSession.startRunning()
                })
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                
                remoteDeviceID = scannedDeviceID
                remoteDeviceMfgString = sfBridgeController.getMfgString(deviceID: remoteDeviceID)
                self.tableView.reloadData()
                
            }
        }
        if sfBridgeController.selectedDeviceType == 2 {
            
            let manufacturerDataString = sfBridgeController.getMfgString(deviceID: scannedDeviceID)
            let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
            let hardwareStatus = manufacturerDataString.substring(from: 10).substring(to: 2)
            //let deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
            //let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
            
            if hardwareType == "02" {
                let alertController = UIAlertController(title: "Pairing Error", message: "Device \(scannedDeviceID) is a Sure-Fi Central Unit. You need to pair to a Sure-Fi Remote Unit.", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: {
                    action in
                    self.captureSession.startRunning()
                })
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            } else if hardwareStatus != "01" {
                let alertController = UIAlertController(title: "Pairing Error", message: "Device \(scannedDeviceID) is not currently in Pairing Mode. Please Unpair this device before proceeding.", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: {
                    action in
                    self.captureSession.startRunning()
                })
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                
                centralDeviceID = scannedDeviceID
                centralDeviceMfgString = sfBridgeController.getMfgString(deviceID: centralDeviceID)
                self.tableView.reloadData()
                
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer.invalidate()
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
