//
//  ACBG2FlashSerialViewController.swift
//  SureFiManufacturing
//
//  Created by John Robinson on 6/20/17.
//  Copyright © 2017 Sure-Fi. All rights reserved.
//

import UIKit
import CoreBluetooth
import iOSDFULibrary

class ACBG2FlashSerialViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var deviceTableViewController: ACBG2DevicesTableViewController!
    
    @IBOutlet var headerContainerView: UIView!
    @IBOutlet var headerLabel: UILabel!
    
    @IBOutlet var statusDisplayLabel: UILabel!
    @IBOutlet var processView: UIView!
    @IBOutlet var deviceTableView: UIView!
    @IBOutlet var instructionsLabel: UILabel!
    
    @IBOutlet var startButton: UIButton!
    @IBOutlet var processButton: UIButton!
    
    @IBOutlet var appMfgCodeLabel: UILabel!
    @IBOutlet var appMfgCodeField: UITextField!
    @IBOutlet var radioMfgCodeLabel: UILabel!
    @IBOutlet var radioMfgCodeField: UITextField!
    @IBOutlet var surefiCodeLabel: UILabel!
    @IBOutlet var surefiCodeField: UITextField!
    
    @IBOutlet var appTestLogTextView: UITextView!
    @IBOutlet var radioTestLogTextView: UITextView!
    
    var scannedUUID: String = ""
    var scannedAppMfgSerial: String = ""
    var scannedRadioMfgSerial: String = ""
    var scanStep: String = ""
    
    var readyToProcess: Bool = false
    var isStarted: Bool = false
    var isProcessing: Bool = false
    var regNameRec: Bool = false
    var regAppRec: Bool = false
    var regRadRec: Bool = false
    var registered: Bool = false
    var processingBusy: Bool = false
    
    var centralManager: CBCentralManager!
    var peripherals: Array<CBPeripheral> = Array<CBPeripheral>()
    var devicePeripheral: CBPeripheral!
    var surefiDevices: Array<CBPeripheral> = Array<CBPeripheral>()
    var surefiAdvertising: [String: String] = [:]
    
    var deviceTxCharacteristic: CBCharacteristic!
    var deviceStatusCharacteristic: CBCharacteristic!
    var deviceSecHashCharacteristic: CBCharacteristic!
    
    var deviceCmdWriteCharacteristic: CBCharacteristic!
    var deviceCmdReadCharacteristic: CBCharacteristic!
    
    var deviceManufacturerDataString: String = ""
    
    var bluetoothTimers: [String:Int] = [:]
    
    var btTimer: Timer!
    var processTimer: Timer!
    
    let SUREFI_SERVICE_UUID = CBUUID(string: "98BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_RX_UID_UUID  = CBUUID(string: "98BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_TX_UID_UUID  = CBUUID(string: "98BF000C-0EC5-2536-2143-2D155783CE78")
    let SUREFI_STATUS_UUID  = CBUUID(string: "98BF000D-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_SEC_SERVICE_UUID  = CBUUID(string: "58BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_SEC_HASH_UUID     = CBUUID(string: "58BF000B-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_CMD_SERVICE_UUID   = CBUUID(string:"C8BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_WRITE_UUID     = CBUUID(string:"C8BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_READ_UUID      = CBUUID(string:"C8BF000C-0EC5-2536-2143-2D155783CE78")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerContainerView.layer.cornerRadius = 32
        headerContainerView.clipsToBounds = true
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        processView.clipsToBounds = true
        processView.layer.borderColor = UIColor.lightGray.cgColor
        processView.layer.borderWidth = 1
        processView.backgroundColor = .white
        processView.layer.cornerRadius = 32
        statusDisplayLabel.text = "Ready to Process"
        instructionsLabel.layer.borderColor = UIColor.lightGray.cgColor
        instructionsLabel.layer.borderWidth = 1
        
        self.navigationItem.title = "Register / Flash Serial Numbers"
        self.statusDisplayLabel.text = "Ready to Process"
        
        btTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(refreshBluetooth(sender:)), userInfo: nil, repeats: true)
        
        appMfgCodeField.addTarget(self, action: #selector(appMfgCodeChanged(sender:)), for: [.editingDidEnd,.editingDidEndOnExit])
        radioMfgCodeField.addTarget(self, action: #selector(radioMfgCodeChanged(sender:)), for: [.editingDidEnd,.editingDidEndOnExit])
        surefiCodeField.addTarget(self, action: #selector(surefiCodeChanged(sender:)), for: [.editingDidEnd,.editingDidEndOnExit])
        
    }
    
    func refreshBluetooth(sender: Timer) {
        
        if deviceTableViewController == nil {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            deviceTableViewController = storyboard.instantiateViewController(withIdentifier: "ACBG2DevicesTableViewController") as! ACBG2DevicesTableViewController
            deviceTableViewController.flashFirmwareViewController = self
            deviceTableViewController.devicesList = self.getDeviceList()
            deviceTableViewController.view.layer.borderColor = UIColor.lightGray.cgColor
            deviceTableViewController.view.layer.borderWidth = 1
            deviceTableViewController.view.frame = CGRect(x: 0, y: processView.frame.height - 200, width: processView.frame.width, height: 200)
            processView.addSubview(deviceTableViewController.view)
        }
        
        for (key,value) in bluetoothTimers {
            
            let newValue = value - 1
            bluetoothTimers[key] = newValue
            
            if newValue < 0 {
                for tempDevice in surefiDevices {
                    
                    if tempDevice.identifier.uuidString == key {
                        surefiDevices.remove(at: surefiDevices.index(of: tempDevice)!)
                        bluetoothTimers.removeValue(forKey: key)
                        surefiAdvertising.removeValue(forKey: key)
                    }
                }
            }
        }
        if deviceTableViewController != nil {
            deviceTableViewController.devicesList = self.getDeviceList()
            deviceTableViewController.tableView.reloadData()
        }
        
        if isStarted {
            startButton.isHidden = true
            appMfgCodeField.isHidden = false
            appMfgCodeLabel.isHidden = false
            radioMfgCodeField.isHidden = false
            radioMfgCodeLabel.isHidden = false
            surefiCodeField.isHidden = false
            surefiCodeLabel.isHidden = false
            
        } else {
            startButton.isHidden = false
            appMfgCodeField.isHidden = true
            appMfgCodeLabel.isHidden = true
            radioMfgCodeField.isHidden = true
            radioMfgCodeLabel.isHidden = true
            surefiCodeField.isHidden = true
            surefiCodeLabel.isHidden = true
            processButton.isHidden = true
            
            startButton.isHidden = true
            switch surefiDevices.count {
            case 0:
                instructionsLabel.backgroundColor = UIColor(rgb: 0xFFEEEE)
                instructionsLabel.text = "No Unregistered Bridge Units Found"
            case 1:
                
                let uuid = surefiDevices.first?.identifier.uuidString ?? ""
                var mfgString = surefiAdvertising[uuid] ?? ""
                
                if mfgString.substring(to: 4).uppercased() == "FFFF" {
                    mfgString = mfgString.substring(from: 4).substring(to: 8)
                } else {
                    mfgString = mfgString.substring(from: 0).substring(to: 8)
                }
                let type = mfgString.substring(from: 0).substring(to: 2)
                var typeDesc = ""
                switch type {
                case "01":
                    typeDesc = "Central Unit"
                case "02":
                    typeDesc = "Remote Unit"
                default:
                    typeDesc = "Unknown"
                }
                startButton.isHidden = false
                instructionsLabel.backgroundColor = UIColor(rgb: 0xEEFFEE)
                instructionsLabel.text = "Bridge \(typeDesc) Found"
            default:
                instructionsLabel.backgroundColor = UIColor(rgb: 0xFFEEEE)
                instructionsLabel.text = "More than One Unregistered Bridge Units Found"
            }
        }
    }
    
    
    @IBAction func startButtonTouch(sender: UIButton) {
        isStarted = true
        surefiCodeField.text = ""
        appMfgCodeField.text = ""
        radioMfgCodeField.text = ""
        appMfgCodeField.becomeFirstResponder()
        
        
    }
    
    @IBAction func processingButtonTouch(sender: UIButton) {
        
        processButton.setTitle("Processing...", for: .normal)
        processButton.backgroundColor = .orange
        processButton.isEnabled = false
        
        isProcessing = true
        devicePeripheral = surefiDevices[0]
        devicePeripheral.delegate = self
        centralManager.connect(devicePeripheral, options: nil)
        
    }
    
    @IBAction func appMfgCodeChanged(sender: UITextField) {
        
        if sender.isFirstResponder {
            radioMfgCodeField.becomeFirstResponder()
            getAppBoardLog()
        }
        
    }
    @IBAction func radioMfgCodeChanged(sender: UITextField) {
        if sender.isFirstResponder {
            surefiCodeField.becomeFirstResponder()
            getRadioBoardLog()
        }
    }
    @IBAction func surefiCodeChanged(sender: UITextField) {
        if sender.isFirstResponder {
            
            processButton.setTitle("Process", for: .normal)
            processButton.backgroundColor = UIColor(rgb: 0x009900)
            processButton.isEnabled = true
            
            
            processButton.isHidden = false
        }
    }
    
    @IBAction func resetButtonPress (sender: UIButton) {
        scannedUUID = ""
        scannedAppMfgSerial = ""
        scannedRadioMfgSerial = ""
        scanStep = "uuid"
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getAppBoardLog() {
        let postData = NSMutableDictionary()
        postData.setValue(appMfgCodeField.text ?? "", forKey: "test_key")
        SessionController().postServerRequest(action: "testing/get_test_results", postData: postData, urlData:"", callback: self.getAppBoardLogCallback)
    }
    
    func getAppBoardLogCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                self.appTestLogTextView.text = (data.object(forKey: "log") as? NSMutableDictionary ?? NSMutableDictionary()).object(forKey: "test_log_content") as? String ?? ""
            } else {
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    func getRadioBoardLog() {
        let postData = NSMutableDictionary()
        postData.setValue(radioMfgCodeField.text ?? "", forKey: "test_key")
        SessionController().postServerRequest(action: "testing/get_test_results", postData: postData, urlData:"", callback: self.getRadioBoardLogCallback)
    }
    
    func getRadioBoardLogCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                self.radioTestLogTextView.text = (data.object(forKey: "log") as? NSMutableDictionary ?? NSMutableDictionary()).object(forKey: "test_log_content") as? String ?? ""
            } else {
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        if (central.state == CBManagerState.poweredOn)
        {
            self.centralManager!.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
        else
        {
            let alert: UIAlertController = UIAlertController(title: "Bluetooth Error", message: "Bluetooth is not turned on.", preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            self.present(alert,animated: true, completion: nil);
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        let name = peripheral.name;
        if name?.uppercased().range(of: "SURE-FI") != nil || name?.uppercased().range(of: "SF BRIDGE") != nil {
            
            let uuid = peripheral.identifier.uuidString
            let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as! Data
            var peripheralDeviceID = manufacturerData.hexStringFromData()
            var deviceStatusString = ""
            
            if peripheralDeviceID.substring(to: 4).uppercased() == "FFFF" {
                deviceStatusString = peripheralDeviceID.substring(from: 4).substring(to: 8)
                peripheralDeviceID = peripheralDeviceID.substring(from: 12).substring(to: 6)
            } else {
                deviceStatusString = peripheralDeviceID.substring(from: 0).substring(to: 8)
                peripheralDeviceID = peripheralDeviceID.substring(from: 8).substring(to: 6)
            }
            if peripheralDeviceID.lowercased() == "ffffff" {
                if !surefiDevices.contains(peripheral) {
                    peripheral.delegate = self
                    surefiDevices.append(peripheral);
                    surefiAdvertising[uuid] = manufacturerData.hexStringFromData()
                }
                bluetoothTimers[uuid] = 10
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if devicePeripheral != nil && peripheral == devicePeripheral {
            devicePeripheral.discoverServices(nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service as CBService
            
            if service.uuid == SUREFI_SERVICE_UUID || service.uuid == SUREFI_SEC_SERVICE_UUID || service.uuid == SUREFI_CMD_SERVICE_UUID {
                peripheral.discoverCharacteristics(nil,for: thisService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,didDiscoverCharacteristicsFor service: CBService,error: Error?) {
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if devicePeripheral != nil && peripheral == devicePeripheral && isProcessing {
                if thisCharacteristic.uuid == SUREFI_TX_UID_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceTxCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_STATUS_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceStatusCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_SEC_HASH_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceSecHashCharacteristic = thisCharacteristic
                    
                    let uuid = peripheral.identifier.uuidString
                    let data = getSecurityHash(manufacturerDataString: surefiAdvertising[uuid]!)
                    print("Sending Sec Hash:\(data.hexStringFromData())")
                    self.devicePeripheral.writeValue(data as Data, for: self.deviceSecHashCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
                if thisCharacteristic.uuid == SUREFI_CMD_WRITE_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceCmdWriteCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_CMD_READ_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceCmdReadCharacteristic = thisCharacteristic
                }
                
                if deviceCmdReadCharacteristic != nil && deviceCmdWriteCharacteristic != nil && deviceSecHashCharacteristic != nil {
                    
                    processTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(refreshProcess(sender:)), userInfo: nil, repeats: true)
                }
            }
        }
    }
    
    func getSecurityHash(manufacturerDataString: String) -> Data {
        
        let peripheralRXUUID = manufacturerDataString.substring(from: 12).substring(to: 6)
        let peripheralTXUUID = manufacturerDataString.substring(from:18).substring(to: 6)
        let string = "\(String(peripheralRXUUID.uppercased().characters.reversed()))\(peripheralTXUUID.uppercased())x~sW5-C\"6fu>!!~X"
        let data = string.getMD5()
        return data
    }
    
    func getDeviceList() -> [String:String] {
        
        var deviceList: [String:String] = [:]
        
        for tempPeripherial in surefiDevices {
            
            let uuid = tempPeripherial.identifier.uuidString
            let manufacturerDataString = surefiAdvertising[uuid] ?? ""
            deviceList[uuid] = "\(tempPeripherial.name!)|\(manufacturerDataString)"
        }
        return deviceList
    }
    
    func identifyPeripheral(deviceUUID: String) {
        
        for tempDevice in surefiDevices {
            
            if tempDevice.identifier.uuidString == deviceUUID {
                
                isStarted = false
                centralManager.connect(tempDevice, options: nil)
                
            }
        }
    }
    
    @IBAction func refreshProcess(sender: Timer) {
        
        if !processingBusy {
            
            if !regNameRec {
                processingBusy = true
                
                var packageBytes: Data = Data()
                packageBytes.append(0x12)
                
                let userName = appDelegate.userData.object(forKey: "user_login") as? String ?? ""
                packageBytes.append(userName.data(using: .utf8)!)
                print("BLE Cmd:\(packageBytes.hexStringFromData())")
                devicePeripheral.writeValue(packageBytes, for: deviceCmdWriteCharacteristic, type: .withoutResponse)
                
                regNameRec = true
                processingBusy = false
            }
            else if !regAppRec {
                processingBusy = true
                
                var packageBytes: Data = Data()
                packageBytes.append(0x13)
                packageBytes.append(appMfgCodeField.text!.data(using: .utf8)!)
                print("BLE Cmd:\(packageBytes.hexStringFromData())")
                devicePeripheral.writeValue(packageBytes, for: deviceCmdWriteCharacteristic, type: .withoutResponse)
                
                regAppRec = true
                processingBusy = false
            }
            else if !regRadRec {
                processingBusy = true
                
                var packageBytes: Data = Data()
                packageBytes.append(0x14)
                packageBytes.append(radioMfgCodeField.text!.data(using: .utf8)!)
                print("BLE Cmd:\(packageBytes.hexStringFromData())")
                devicePeripheral.writeValue(packageBytes, for: deviceCmdWriteCharacteristic, type: .withoutResponse)
                
                regRadRec = true
                processingBusy = false
            }
            else if !registered {
                processingBusy = true
                
                var packageBytes: Data = Data()
                packageBytes.append(0x15)
                packageBytes.append(surefiCodeField.text?.dataFromHexString() as! Data)
                print("BLE Cmd:\(packageBytes.hexStringFromData())")
                devicePeripheral.writeValue(packageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
            } else {
                sender.invalidate()
                let alertController = UIAlertController(title: "Success", message: "Finished", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
                centralManager.cancelPeripheralConnection(devicePeripheral)
                isStarted = false
                isProcessing = false
                regNameRec = false
                regAppRec = false
                regRadRec = false
                registered = false
                processingBusy = false
                
                appTestLogTextView.text = ""
                radioTestLogTextView.text = ""
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == SUREFI_CMD_READ_UUID {
            
            let value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            print("BLE Read:\(value)")
            
            let response = value.substring(to: 2)
            let data = value.substring(from: 2)
            
            switch (response) {
            case "0E":
                registered = true
                processingBusy = false
                break
            case "0F":
                regNameRec = true
                processingBusy = false
                break
            case "10":
                regAppRec = true
                processingBusy = false
                break
            case "11":
                regRadRec = true
                processingBusy = false
                break
            case "E7":
                let alertController = UIAlertController(title: "Error", message: "Error Flashing Serials", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
                
                processTimer.invalidate()
                
                isStarted = true
                isProcessing = false
                regNameRec = false
                regAppRec = false
                regRadRec = false
                registered = false
                processingBusy = false
                
                appTestLogTextView.text = ""
                radioTestLogTextView.text = ""
                
            default:
                break
                
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        btTimer.invalidate()
        if devicePeripheral != nil {
            centralManager.cancelPeripheralConnection(devicePeripheral)
        }
        centralManager.stopScan()
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
