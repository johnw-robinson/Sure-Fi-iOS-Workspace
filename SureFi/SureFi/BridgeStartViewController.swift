//
//  BridgeStartViewController.swift
//  SureFi
//
//  Created by John Robinson on 7/5/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import AVFoundation

class BridgeStartViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet var scannerView: UIView!
    @IBOutlet var scannerImageView: UIImageView!
    @IBOutlet var instructionView: UIView!
    @IBOutlet var deviceListViewContainer: UIView!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var continueButton: UIButton!
    @IBOutlet var messageLabel: UILabel!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var bridgeDeviceListTableViewController: BridgeDeviceListTableViewController!
    var sfBridgeController: SFBridgeController!
    
    var scannedDeviceID: String = ""
    
    var captureSession = AVCaptureSession();
    var sessionOutput = AVCapturePhotoOutput();
    var sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG]);
    var previewLayer = AVCaptureVideoPreviewLayer();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sfBridgeController = SFBridgeController.shared
        
        let barButtonItem = UIBarButtonItem(image: UIImage(named: "bluetooth"), style: .plain, target: self, action: #selector(toggleDeviceDisplay(sender:)))
        self.navigationItem.rightBarButtonItem = barButtonItem
        
        self.navigationItem.title = "Scan Sure-Fi Code"
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        updateDeviceList()
        
        let scannerViewFrame = CGRect(x: scannerView.frame.origin.x, y: scannerView.frame.origin.y, width: scannerView.frame.size.width, height: scannerView.frame.size.width)
        scannerView.frame = scannerViewFrame
        scannerView.layer.cornerRadius = 10
        scannerView.clipsToBounds = true
        scannerImageView.frame = scannerViewFrame
        scannerImageView.layer.cornerRadius = 10
        scannerImageView.layer.borderColor = UIColor.gray.cgColor
        scannerImageView.layer.borderWidth = 2
        scannerImageView.clipsToBounds = true
        
        resetButton.layer.cornerRadius = 10
        continueButton.layer.cornerRadius = 10
        
        
        var top = scannerView.frame.origin.y + scannerView.frame.size.height + 8
        continueButton.frame = CGRect(x: continueButton.frame.origin.x, y: top, width: continueButton.frame.size.width, height: continueButton.frame.size.height)
        resetButton.frame = CGRect(x: resetButton.frame.origin.x, y: top, width: resetButton.frame.size.width, height: resetButton.frame.size.height)
        top = scannerView.frame.origin.y + scannerView.frame.size.height + 56
        
        let height = self.view.frame.size.height - top
        deviceListViewContainer.frame = CGRect(x: 0, y: top, width: deviceListViewContainer.frame.size.width, height: height)
        
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
        
        self.scannerView.isHidden = false
        self.scannerView.alpha = 0
        self.scannerImageView.isHidden = false
        self.scannerImageView.alpha = 0
        self.instructionView.isHidden = false
        self.instructionView.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.scannerView.alpha = 1
            self.scannerImageView.alpha = 1
            self.instructionView.alpha = 1
             
        })
        
    }
    
    @IBAction func toggleDeviceDisplay(sender: UIBarButtonItem) {
        
        updateDeviceList()
        deviceListViewContainer.isHidden = !deviceListViewContainer.isHidden
        
    }
    
    @IBAction func continueButtonPress(sender: UIButton) {
        
        var mfgString = ""
        
        let ret = sfBridgeController.selectPeripheral(deviceID: scannedDeviceID)
        if !ret {
            let alert: UIAlertController = UIAlertController(title: "Bluetooth Error", message: "Unable to find Sure-Fi Device (\(scannedDeviceID)).", preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            self.present(alert,animated: true, completion: nil);
            return
        }
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        self.navigationItem.backBarButtonItem = backButton
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceDetailsTableViewController") as! BridgeDeviceDetailsTableViewController
        controller.bridgeStartViewController = self
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func resetButtonPress(sender: UIButton) {
        messageLabel.text = ""
        scannerImageView.layer.borderColor = UIColor.gray.cgColor
        captureSession.startRunning()
        scannedDeviceID = ""
        resetButton.isHidden = true
        continueButton.isHidden = true
    }
    
    @IBAction func infoButtonPress(sender: UIButton) {
        let alert: UIAlertController = UIAlertController(title: "Instructions", message: "1. Locate the QR Code found on your Sure-Fi Bridge.\n\n2. Using the viewfinder on this screen bring the QR Code into focus. You may have to move the bridge closer or farther away from your device.\n\n3. When the code has been scanned, select \"Continue\" to connect the Sure-Fi Bridge", preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
        self.present(alert,animated: true, completion: nil);
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
                scannedDeviceID = metadataObj.stringValue.uppercased() ?? ""
                captureSession.stopRunning()
                resetButton.isHidden = false
                
                let found = sfBridgeController.deviceExists(deviceID: scannedDeviceID)
                setDeviceFound(found: found, deviceID: scannedDeviceID)
            }
        }
    }
    
    func setDeviceFound (found: Bool, deviceID: String) {
        scannedDeviceID = deviceID
        messageLabel.isHidden = false
        print("Found:\(found ? "true" : "false") Selected:\(scannedDeviceID)")
        if found {
            continueButton.isHidden = false
            self.messageLabel.text = "Device (\(deviceID)) Found"
            self.messageLabel.textColor = UIColor.green
            self.scannerImageView.layer.borderColor = UIColor(rgb: 0x009900).cgColor
        }
        else {
            continueButton.isHidden = true
            if(scannedDeviceID != "") {
                self.messageLabel.text = "Device (\(deviceID)) NOT Found"
                self.messageLabel.textColor = UIColor.red
                self.scannerImageView.layer.borderColor = UIColor(rgb: 0x990000).cgColor
            }
        }
    }
    
    func updateDeviceList() {
        
        if bridgeDeviceListTableViewController == nil {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            bridgeDeviceListTableViewController = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceListTableViewController") as! BridgeDeviceListTableViewController
            bridgeDeviceListTableViewController.view.frame = CGRect(x: 0, y: 0, width: deviceListViewContainer.frame.size.width, height: deviceListViewContainer.frame.size.height)
            deviceListViewContainer.addSubview(bridgeDeviceListTableViewController.view)
        }
        bridgeDeviceListTableViewController.surefiDevices = sfBridgeController.surefiDevices
        bridgeDeviceListTableViewController.surefiMfgStrings = sfBridgeController.surefiMfgStrings
        bridgeDeviceListTableViewController.tableView.reloadData()
        
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
