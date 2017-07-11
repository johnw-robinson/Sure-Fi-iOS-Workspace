//
//  PairingTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 6/14/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth

class PairingTableViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var pairingSystemViewController: PairingSystemViewController!
    var configureBridgeData :[String:String] = [:]
    
    var centralManager: CBCentralManager!
    var peripherals: Array<CBPeripheral> = Array<CBPeripheral>()
    var centralPeripheral: CBPeripheral!
    var remotePeripheral: CBPeripheral!
    var surefiDevices: Array<CBPeripheral> = Array<CBPeripheral>()
    var surefiDevicesData: Array<[String:Any]> = Array<[String:Any]>()
    var surefiAdvertising: NSMutableDictionary = NSMutableDictionary()
    
    var centralDeviceID: String = ""
    var remoteDeviceID: String = ""
    var centralDescription: String = ""
    var remoteDescription: String = ""
    var centralImage: UIImage!
    var remoteImage: UIImage!
    var systemName: String = ""
    
    var centralTxCharacteristic: CBCharacteristic!
    var centralStatusCharacteristic: CBCharacteristic!
    var centralSecHashCharacteristic: CBCharacteristic!
    
    var centralCmdWriteCharacteristic: CBCharacteristic!
    var centralCmdReadCharacteristic: CBCharacteristic!
    
    var centralManufacturerDataString: String = ""
    
    var remoteTxCharacteristic: CBCharacteristic!
    var remoteStatusCharacteristic: CBCharacteristic!
    var remoteSecHashCharacteristic: CBCharacteristic!
    
    var remoteCmdWriteCharacteristic: CBCharacteristic!
    var remoteCmdReadCharacteristic: CBCharacteristic!
    
    var remoteManufacturerDataString: String = ""
    
    var timer: Timer!
    
    let SUREFI_SERVICE_UUID = CBUUID(string: "98BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_RX_UID_UUID  = CBUUID(string: "98BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_TX_UID_UUID  = CBUUID(string: "98BF000C-0EC5-2536-2143-2D155783CE78")
    let SUREFI_STATUS_UUID  = CBUUID(string: "98BF000D-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_SEC_SERVICE_UUID  = CBUUID(string: "58BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_SEC_HASH_UUID     = CBUUID(string: "58BF000B-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_CMD_SERVICE_UUID = CBUUID(string:"C8BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_WRITE_UUID     = CBUUID(string:"C8BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_READ_UUID      = CBUUID(string:"C8BF000C-0EC5-2536-2143-2D155783CE78")
    
    var pairingStarted: Bool = false
    var centralCompleted: Bool = false
    var centralConnected: Bool = false
    var centralConfigured: Bool = false
    
    var remoteCompleted: Bool = false
    var remoteConnected: Bool = false
    var remoteConfigured: Bool = false
    
    var centralReady: Int = -1
    var remoteReady: Int = -1
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Pair Sure-Fi Bridge"
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView?.backgroundView = backgroundImageView
        self.tableView?.separatorStyle = .none
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startButtonPress(sender: UIButton) {
        
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "PairingCentralViewController") as! PairingCentralViewController
        controller.pairingTableViewController = self
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 1 {
            return "Sure-Fi Devices"
        }
        return ""
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            return 256
        }
        
        return 44
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        if section == 1 {
            return surefiDevices.count
        }
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath)
            cell.backgroundColor = .clear
            
            
            
        } else if indexPath.section == 1 {
            let surefiDevice = surefiDevices[indexPath.row]
            let advertisementData = surefiAdvertising.object(forKey: String(indexPath.row)) as? [String: Any] ?? [String: Any]()
            let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as! Data
            let manufacturerDataString = manufacturerData.hexStringFromData()
            
            //let manufacturerID = manufacturerDataString.substring(from: 0).substring(to: 4)
            let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
            let firmwareVersion = manufacturerDataString.substring(from: 6).substring(to: 4)
            let status = manufacturerDataString.substring(from: 10).substring(to: 2)
            let deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
            let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
            
            cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothItemCell", for: indexPath)
                        
            cell.textLabel?.text = surefiDevice.name ?? ""
            cell.detailTextLabel?.text = "RX:\(deviceID) TX:\(remoteID) TP:\(hardwareType) VER:\(firmwareVersion) STAT:\(status)"
            
            cell.selectionStyle = .none
        }
        return cell
    }
    

    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        if (central.state == CBManagerState.poweredOn)
        {
            self.centralManager!.scanForPeripherals(withServices: nil, options: nil)
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
            
            let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as! Data
            let peripheralDeviceID = manufacturerData.hexStringFromData()
            
            if centralDeviceID != "" && peripheralDeviceID.uppercased().range(of: centralDeviceID) != nil {
                centralPeripheral = peripheral
                centralPeripheral.delegate = self
            }
            if remoteDeviceID != "" && peripheralDeviceID.uppercased().range(of: remoteDeviceID) != nil {
                remotePeripheral = peripheral
                remotePeripheral.delegate = self
            }
            if(!surefiDevices.contains(peripheral)) {
                surefiDevices.append(peripheral);
                surefiDevicesData.append(advertisementData);
                
                let index = String(surefiDevices.index(of: peripheral)!)
                surefiAdvertising.setValue(advertisementData, forKey: index)
                self.tableView.reloadData()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if centralPeripheral != nil && peripheral == centralPeripheral {
            centralPeripheral.discoverServices(nil)
        }
        if remotePeripheral != nil && peripheral == remotePeripheral {
            remotePeripheral.discoverServices(nil)
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
            
            if centralPeripheral != nil && peripheral == centralPeripheral {
                if thisCharacteristic.uuid == SUREFI_TX_UID_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    centralTxCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_STATUS_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    centralStatusCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_SEC_HASH_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    centralSecHashCharacteristic = thisCharacteristic
                    
                    let data = getSecurityHash(manufacturerDataString: centralManufacturerDataString)
                    self.centralPeripheral.writeValue(data as Data, for: self.centralSecHashCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
                if thisCharacteristic.uuid == SUREFI_CMD_WRITE_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    centralCmdWriteCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_CMD_READ_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    centralCmdReadCharacteristic = thisCharacteristic
                }
            }
            if remotePeripheral != nil && peripheral == remotePeripheral {
                if thisCharacteristic.uuid == SUREFI_TX_UID_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    remoteTxCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_STATUS_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    remoteStatusCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_SEC_HASH_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    remoteSecHashCharacteristic = thisCharacteristic
                    
                    let data = getSecurityHash(manufacturerDataString: remoteManufacturerDataString)
                    self.remotePeripheral.writeValue(data as Data, for: self.remoteSecHashCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
                if thisCharacteristic.uuid == SUREFI_CMD_WRITE_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    remoteCmdWriteCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_CMD_READ_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    remoteCmdReadCharacteristic = thisCharacteristic
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
    
    func pairBridge(sender: PairingSystemViewController) {
        
        if centralPeripheral != nil {
            centralManager.cancelPeripheralConnection(centralPeripheral)
        }
        if centralPeripheral != nil {
            centralManager.cancelPeripheralConnection(remotePeripheral)
        }

        pairingStarted = false
        centralCompleted = false
        centralConnected = false
        centralConfigured = false
        
        remoteCompleted = false
        remoteConnected = false
        remoteConfigured = false
        
        centralReady = -1
        remoteReady = -1
        
        pairingSystemViewController = sender
        let registerBridgeSystemData = NSMutableDictionary()
        registerBridgeSystemData.setValue("4", forKey: "system_type")
        registerBridgeSystemData.setValue(centralDeviceID, forKey: "bridge_serial_central")
        registerBridgeSystemData.setValue(remoteDeviceID, forKey: "bridge_serial_remote")
        registerBridgeSystemData.setValue(centralDescription, forKey: "bridge_desc_central")
        registerBridgeSystemData.setValue(remoteDescription, forKey: "bridge_desc_remote")
        registerBridgeSystemData.setValue(systemName, forKey: "system_desc")
        registerBridgeSystemData.setValue("\(appDelegate.currentLongitude!)", forKey: "system_longitude")
        registerBridgeSystemData.setValue("\(appDelegate.currentLatitude!)", forKey: "system_latitude")
        SessionController().postServerRequest(action: "systems/register_bridge_system", postData: registerBridgeSystemData, urlData:"", callback: self.registerBridgeSystemCallback)
            
    }
        
    func registerBridgeSystemCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                
                var system_id = String(data.object(forKey: "system_id") as? Int ?? -1)
                if system_id == "-1" {
                    system_id = data.object(forKey: "system_id") as? String ?? ""
                }
                print("New System ID:\(system_id)")
                
                let postData: NSMutableDictionary = NSMutableDictionary()
                postData.setValue(system_id, forKey: "system_id")
                postData.setValue(self.appDelegate.sessionController.session_key, forKey: "session_key")
                postData.setValue(self.appDelegate.deviceNotificationToken, forKey: "device_token")
                
                var params: [String] = [String]()
                for (key,value) in postData {
                    params.append("\(key)=\(value)")
                }
                
                let url = URL(string: "https://admin.sure-fi.com/mobile_api/upload_system_images")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                let boundary = "Boundary-\(NSUUID().uuidString)"
                
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                let central_image_data = UIImagePNGRepresentation(self.centralImage)
                let remote_image_data = UIImagePNGRepresentation(self.remoteImage)
                
                let body = NSMutableData()
                let mimetype = "image/png"
                
                //define the data post parameter
                
                for (key,value) in postData {
                    body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
                    body.append("Content-Disposition:form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
                    body.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
                }
                
                body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Disposition:form-data; name=\"central_image\"; filename=\"central_image\"\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
                body.append(central_image_data!)
                body.append("\r\n".data(using: String.Encoding.utf8)!)
                body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
                
                body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Disposition:form-data; name=\"remote_image\"; filename=\"remote_image\"\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
                body.append(remote_image_data!)
                body.append("\r\n".data(using: String.Encoding.utf8)!)
                body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
                
                request.httpBody = body as Data
                
                let session = URLSession.shared
                let task = session.dataTask(with: request) {
                    (data, response, error) in
                    
                    guard let data = data, let _:URLResponse = response, error == nil else {
                        print("http callback error")
                        return
                    }
                    return self.uploadImageCallback(result: data)
                }
                task.resume()
            } else {
                
                let alertController = UIAlertController(title: "Error", message: "\(msg)\n\nPlease try again.", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.pairingSystemViewController.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func uploadImageCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                
                print(data)
                self.connectDevices()
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.prepareSetup), userInfo: nil, repeats: true);
                
            } else {
                
                let alertController = UIAlertController(title: "Error", message: "\(msg)\n\nPlease try again.", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.pairingSystemViewController.present(alertController, animated: true, completion: nil)

            }
        }
    }
    
    func connectDevices() {
        
        for (key,temp) in surefiAdvertising {
            
            let advertisementData = temp as! [String:Any]
            let index = Int(key as? String ?? "-1")!
            let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as! Data
            let manufacturerDataString = manufacturerData.hexStringFromData()
            let peripheral = surefiDevices[index]

            if manufacturerDataString.uppercased().range(of: centralDeviceID) != nil {
                centralManufacturerDataString = manufacturerDataString
                centralPeripheral = peripheral
                centralPeripheral.delegate = self
                centralReady = -1
                centralManager.connect(centralPeripheral, options: nil)
            }
            if manufacturerDataString.uppercased().range(of: remoteDeviceID) != nil {
                remoteManufacturerDataString = manufacturerDataString
                remotePeripheral = peripheral
                remotePeripheral.delegate = self
                remoteReady = -1
                centralManager.connect(remotePeripheral, options: nil)
            }
            
            
        }
        
    }
    
    func checkBluetooth() {
        
        print("Checking Bluetooth")
        if centralPeripheral != nil && centralReady != -2 {
            
            if centralPeripheral.state == .connected {
                print("Central Ready")
                centralReady = 1
            } else if centralPeripheral.state == .connecting {
                print("Central Connecting")
                centralReady = 2
            } else {
                print("Central Disconnected")
                centralReady = 0
            }
        } else {
            print("Central Not Connected")
            if centralReady != -2 {
                centralReady = 0
            }
        }
        if remotePeripheral != nil && remoteReady != -2 {
            if remotePeripheral.state == .connected {
                print("Remote Ready")
                remoteReady = 1
            } else if remotePeripheral.state == .connecting {
                print("Remote Connecting")
                remoteReady = 2
            } else {
                print("Remote Disconnected")
                remoteReady = 0
            }
        } else {
            print("Remote Not Connected")
            if remoteReady != -2 {
                remoteReady = 0
            }
        }
        print("")
        print("")
        print("")
        print("")
    }

    func prepareSetup (timer: Timer) {
        
        checkBluetooth()
        pairingStarted = true
        if centralPeripheral != nil && centralReady == 1 &&  centralTxCharacteristic != nil {
            
            remoteReady = -2
            if centralConfigured == false {
                DispatchQueue.main.async {
                    print("Sending Remote ID to Central \(self.remoteDeviceID)")
                    let data = self.remoteDeviceID.dataFromHexString()
                    self.centralPeripheral.writeValue(data! as Data, for: self.centralTxCharacteristic, type: CBCharacteristicWriteType.withResponse)
                    self.centralConfigured = true
                    
                }
            }
        }
        /*if remotePeripheral != nil && remoteReady == 1 && remoteTxCharacteristic != nil {
            
            centralReady = -2
            if remoteConfigured == false {
                DispatchQueue.main.async {
                    print("Sending Central ID to Remote \(self.centralDeviceID)")
                    let data = self.centralDeviceID.dataFromHexString()
                    self.remotePeripheral.writeValue(data! as Data, for: self.remoteTxCharacteristic, type: CBCharacteristicWriteType.withResponse)
                    self.remoteConfigured = true
                }
            }
        }*/
        
        if centralCompleted && remoteCompleted {
            
            timer.invalidate()
            self.navigationItem.setHidesBackButton(false, animated: true)
            
            let alert = UIAlertController(title: "Success", message: "Your Sure-Fi Bridge has finished Pairing", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
            alert.addAction(okAction)
            self.pairingSystemViewController.present(alert, animated: true, completion: nil)
            
        }
        
        self.tableView.reloadData()
    }


}
