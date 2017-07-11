//
//  BridgePairingTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 4/20/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth

class BridgePairingTableViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var centralManager: CBCentralManager!
    var peripherals: Array<CBPeripheral> = Array<CBPeripheral>()
    var centralPeripheral: CBPeripheral!
    var remotePeripheral: CBPeripheral!
    var surefiDevices: Array<CBPeripheral> = Array<CBPeripheral>()
    
    var bridgePairTableViewController: BridgePairTableViewController!
    var pairingSystemViewController : PairingSystemViewController!
    
    var centralDeviceID: String?
    var remoteDeviceID: String?
    
    var centralManufacturerDataString: String?
    var remoteManufacturerDataString: String?
    
    var centralCompleted: Bool = false
    var centralConnected: Bool = false
    var centralConfigured: Bool = false
    
    var remoteCompleted: Bool = false
    var remoteConnected: Bool = false
    var remoteConfigured: Bool = false
    
    var centralReady: Int = -1
    var remoteReady: Int = -1
    
    var started: Bool = false
    var startedOnce: Bool = false
    
    var centralTxCharacteristic: CBCharacteristic!
    var remoteTxCharacteristic: CBCharacteristic!
    
    var centralStatusCharacteristic: CBCharacteristic!
    var remoteStatusCharacteristic: CBCharacteristic!
    
    var centralSecHashCharacteristic: CBCharacteristic!
    var remoteSecHashCharacteristic: CBCharacteristic!
    
    var timer: Timer!
    var btTimer: Timer!
    
    var centralStatusString: String = ""
    var remoteStatusString: String = ""
    
    let SUREFI_SERVICE_UUID = CBUUID(string: "98BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_RX_UID_UUID  = CBUUID(string: "98BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_TX_UID_UUID  = CBUUID(string: "98BF000C-0EC5-2536-2143-2D155783CE78")
    let SUREFI_STATUS_UUID  = CBUUID(string: "98BF000D-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_SEC_SERVICE_UUID  = CBUUID(string: "58BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_SEC_HASH_UUID     = CBUUID(string: "58BF000B-0EC5-2536-2143-2D155783CE78")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Pair Sure-Fi Bridge"
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView?.backgroundView = backgroundImageView
        
        let startButton = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(startTimer(sender:)))
        self.navigationItem.rightBarButtonItem = startButton
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        btTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkBluetooth), userInfo: nil, repeats: true);
        
    }
    
    func checkBluetooth() {
        
        if centralPeripheral != nil {
            
            if centralPeripheral.state == .connected {
                centralReady = 1
            } else if centralPeripheral.state == .connecting {
                centralReady = 2
            } else {
                
                if centralReady > 0 {
                    centralManager.connect(centralPeripheral, options: nil)
                }
                centralReady = 0
            }
        } else {
            if centralReady != -2 {
                centralReady = 0
            }
        }
        if remotePeripheral != nil {
            if remotePeripheral.state == .connected {
                remoteReady = 1
            } else if remotePeripheral.state == .connecting {
                remoteReady = 2
            } else {
                
                if remoteReady > 0 {
                    centralManager.connect(remotePeripheral, options: nil)
                }
                
                
                remoteReady = 0
            }
        } else {
            if remoteReady != -2 {
                remoteReady = 0
            }
        }
        self.tableView.reloadData()
    }
    
    @IBAction func startTimer(sender: UIBarButtonItem) {
        
        startedOnce = true
        self.navigationItem.title = ""
        sender.title = "Registering..."
        sender.isEnabled = false
        
        let registerBridgeSystemData = NSMutableDictionary()
        registerBridgeSystemData.setValue("4", forKey: "system_type")
        if bridgePairTableViewController != nil {
            registerBridgeSystemData.setValue(bridgePairTableViewController.newBridgeData["device_id_central"], forKey: "bridge_serial_central")
            registerBridgeSystemData.setValue(bridgePairTableViewController.newBridgeData["device_id_remote"], forKey: "bridge_serial_remote")
            registerBridgeSystemData.setValue(bridgePairTableViewController.newBridgeData["device_title_central"], forKey: "bridge_desc_central")
            registerBridgeSystemData.setValue(bridgePairTableViewController.newBridgeData["device_title_remote"], forKey: "bridge_desc_remote")
            registerBridgeSystemData.setValue(bridgePairTableViewController.newBridgeData["system_title"], forKey: "system_desc")
            registerBridgeSystemData.setValue(bridgePairTableViewController.newBridgeData["system_address"], forKey: "system_address")
        }
        if pairingSystemViewController != nil {
            registerBridgeSystemData.setValue(pairingSystemViewController.pairingTableViewController.centralDeviceID, forKey: "bridge_serial_central")
            registerBridgeSystemData.setValue(pairingSystemViewController.pairingTableViewController.remoteDeviceID, forKey: "bridge_serial_remote")
            registerBridgeSystemData.setValue(pairingSystemViewController.pairingTableViewController.centralDescription, forKey: "bridge_desc_central")
            registerBridgeSystemData.setValue(pairingSystemViewController.pairingTableViewController.remoteDescription, forKey: "bridge_desc_remote")
            registerBridgeSystemData.setValue(pairingSystemViewController.systemDescTextView.text, forKey: "system_title")
            registerBridgeSystemData.setValue("", forKey: "system_address")
            print(registerBridgeSystemData)
        }
        registerBridgeSystemData.setValue("\(appDelegate.currentLongitude!)", forKey: "system_longitude")
        registerBridgeSystemData.setValue("\(appDelegate.currentLatitude!)", forKey: "system_latitude")
        SessionController().postServerRequest(action: "systems/register_bridge_system", postData: registerBridgeSystemData, urlData:"", callback: self.registerBridgeSystemCallback)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = .darkGray
        header.textLabel?.font = UIFont.systemFont(ofSize: 12, weight: 2)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section==0) {
            return "Central Unit"
        }
        if(section==1) {
            return "Remote Unit"
        }
        return ""
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            if centralCompleted {
                return 3
            }
            if started && centralReady == 1{
                return 2
            }
            return 1
        }
        if section == 1 {
            if remoteCompleted {
                return 3
            }
            if started && remoteReady == 1{
                return 2
            }
            return 1
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StepCell", for: indexPath)
        cell.detailTextLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Central Unit Status"
                if centralPeripheral != nil || centralCompleted {
                    
                    if !started {
                        if centralReady == 1{
                            cell.detailTextLabel?.text = "In Range"
                            cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 1)
                            if startedOnce == false {
                                let barButtonItem = self.navigationItem.rightBarButtonItem ?? UIBarButtonItem()
                                //startTimer(sender: barButtonItem)
                            }
                        } else if centralReady == 2 {
                            cell.detailTextLabel?.text = "Connecting"
                            cell.detailTextLabel?.textColor = .blue
                        } else if centralReady == -1 {
                            cell.detailTextLabel?.text = "Scanning"
                            cell.detailTextLabel?.textColor = .orange
                        } else if centralReady == -2 {
                            cell.detailTextLabel?.text = "Pairing From Remote"
                            cell.detailTextLabel?.textColor = .orange
                        } else {
                            cell.detailTextLabel?.text = "Not In Range"
                            cell.detailTextLabel?.textColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)
                        }
                    }
                    else if centralStatusCharacteristic != nil {
                        
                        let status = centralStatusCharacteristic.value ?? Data()
                        if status.count > 0 {
                            
                            if status[0] == 1 {
                                cell.detailTextLabel?.text = "Unpaired"
                                cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0, blue: 0.8, alpha: 1)
                            }
                            if status[0] == 2 {
                                cell.detailTextLabel?.text = "Pairing"
                                cell.detailTextLabel?.textColor = .orange
                            }
                            if status[0] == 3 {
                                cell.detailTextLabel?.text = "Paired"
                                cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 1)
                                
                                remoteCompleted = true
                                remoteConfigured = true
                                remoteConnected = true
                                
                                self.tableView.reloadData()
                            }
                        }
                    }
                } else {
                    cell.detailTextLabel?.text = "Scanning"
                    cell.detailTextLabel?.textColor = .orange
                }
            }
            if indexPath.row == 1 {
                cell.textLabel?.text = "Central Unit Configured"
                if centralConfigured {
                    cell.detailTextLabel?.text = "✓"
                    cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 1)
                } else {
                    cell.detailTextLabel?.text = "↺"
                    cell.detailTextLabel?.textColor = UIColor.orange
                }
            }
            if indexPath.row == 2 {
                cell.textLabel?.text = "Central Unit Paired"
                if centralCompleted {
                    cell.detailTextLabel?.text = "✓"
                    cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 1)
                    
                    remoteCompleted = true
                    remoteConnected = true
                    remoteConfigured = true
                    
                } else {
                    cell.detailTextLabel?.text = "↺"
                    cell.detailTextLabel?.textColor = UIColor.orange
                }
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Remote Unit Status"
                if remotePeripheral != nil || remoteCompleted {
                    
                    if !started {
                        if remoteReady == 1{
                            cell.detailTextLabel?.text = "In Range"
                            cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 1)
                        } else if remoteReady == 2 {
                            cell.detailTextLabel?.text = "Connecting"
                            cell.detailTextLabel?.textColor = .blue
                        } else if remoteReady == -1 {
                            cell.detailTextLabel?.text = "Scanning"
                            cell.detailTextLabel?.textColor = .orange
                        } else if remoteReady == -2 {
                            cell.detailTextLabel?.text = "Pairing From Central"
                            cell.detailTextLabel?.textColor = .orange
                        } else {
                            cell.detailTextLabel?.text = "Not In Range"
                            cell.detailTextLabel?.textColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)
                        }
                    }
                    else if remoteStatusCharacteristic != nil {
                        
                        let status = remoteStatusCharacteristic.value ?? Data()
                        if status.count > 0 {
                            
                            if status[0] == 1 {
                                cell.detailTextLabel?.text = "Unpaired"
                                cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0, blue: 0.8, alpha: 1)
                            }
                            if status[0] == 2 {
                                cell.detailTextLabel?.text = "Pairing"
                                cell.detailTextLabel?.textColor = .orange
                            }
                            if status[0] == 3 {
                                cell.detailTextLabel?.text = "Paired"
                                cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 1)
                                
                                remoteCompleted = true
                                remoteConfigured = true
                                remoteConnected = true
                                
                                self.tableView.reloadData()
                            }
                        }
                    }
                } else {
                    cell.detailTextLabel?.text = "Scanning"
                    cell.detailTextLabel?.textColor = .orange
                }
            }
            if indexPath.row == 1 {
                cell.textLabel?.text = "Remote Unit Configured"
                if remoteConfigured {
                    cell.detailTextLabel?.text = "✓"
                    cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 1)
                } else {
                    cell.detailTextLabel?.text = "↺"
                    cell.detailTextLabel?.textColor = UIColor.orange
                }
            }
            if indexPath.row == 2 {
                cell.textLabel?.text = "Remote Unit Paired"
                if remoteCompleted {
                    cell.detailTextLabel?.text = "✓"
                    cell.detailTextLabel?.textColor = UIColor(red: 0, green: 0.8, blue: 0, alpha: 1)
                    
                    centralCompleted = true
                    centralConnected = true
                    centralConfigured = true
                    
                } else {
                    cell.detailTextLabel?.text = "↺"
                    cell.detailTextLabel?.textColor = UIColor.orange
                }
            }
        }
        return cell
    }
    
    
    func prepareSetup (timer: Timer) {
        
        started = true
        startedOnce = true
        if centralPeripheral != nil && centralReady == 1 {
            
            remoteReady = -2
            
            if(centralConfigured == false) {
                
                if centralTxCharacteristic != nil {
                    
                    let data = remoteDeviceID?.dataFromHexString()
                    centralPeripheral.writeValue(data! as Data, for: centralTxCharacteristic, type: CBCharacteristicWriteType.withResponse)
                    centralConfigured = true
                }
            }
        }
        if remotePeripheral != nil && remoteReady == 1 {
            
            centralReady = -2
            
            if(remoteConfigured == false) {
                
                if remoteTxCharacteristic != nil {
                    let data = centralDeviceID?.dataFromHexString()
                    remotePeripheral.writeValue(data! as Data, for: remoteTxCharacteristic, type: CBCharacteristicWriteType.withResponse)
                    remoteConfigured = true
                }
            }
        }
        
        if centralCompleted || remoteCompleted {
            timer.invalidate()
            self.navigationItem.setHidesBackButton(false, animated: true)
            
            let alert = UIAlertController(title: "Success", message: "Your Sure-Fi Bridge has finished Pairing. Press \"Continue\" to pair another Sure-Fi Bridge", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Continue", style: .default, handler: {
                action in
                self.navigationController!.pop(animated: true)
                if self.bridgePairTableViewController != nil {
                    self.bridgePairTableViewController.navigationController!.pop(animated: true)
                }
                if self.pairingSystemViewController != nil {
                    self.navigationController?.popToViewController(self.pairingSystemViewController.pairingTableViewController, animated: true)
                }
            })
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        self.tableView.reloadData()
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
                
                let boundary = self.generateBoundaryString()
                
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                var central_image_data = Data()
                var remote_image_data = Data()
                
                if self.bridgePairTableViewController != nil {
                    central_image_data = UIImagePNGRepresentation(self.bridgePairTableViewController.centralImage)!
                    remote_image_data = UIImagePNGRepresentation(self.bridgePairTableViewController.remoteImage)!
                }
                if self.pairingSystemViewController != nil {
                    central_image_data = UIImagePNGRepresentation(self.pairingSystemViewController.pairingTableViewController.centralImage)!
                    remote_image_data = UIImagePNGRepresentation(self.pairingSystemViewController.pairingTableViewController.remoteImage)!
                }
                
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
                body.append(central_image_data)
                body.append("\r\n".data(using: String.Encoding.utf8)!)
                body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
                
                body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Disposition:form-data; name=\"remote_image\"; filename=\"remote_image\"\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
                body.append(remote_image_data)
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
                self.present(alertController, animated: true, completion: nil)
                
                let startButton = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(self.startTimer(sender:)))
                self.navigationItem.rightBarButtonItem = startButton
            }
        }
    }
    
    func uploadImageCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                
                print(data)
                
                let startButton = UIBarButtonItem(title: "Configuring...", style: .plain, target: self, action: #selector(self.startTimer(sender:)))
                startButton.isEnabled = false
                self.navigationItem.rightBarButtonItem = startButton
                
                self.navigationItem.setHidesBackButton(true, animated: true)
                self.timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.prepareSetup), userInfo: nil, repeats: true);
                
            } else {
                
                let alertController = UIAlertController(title: "Error", message: "\(msg)\n\nPlease try again.", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
                
                let startButton = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(self.startTimer(sender:)))
                self.navigationItem.rightBarButtonItem = startButton
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
        if name?.uppercased().range(of: "SURE-FI") != nil || name?.uppercased().range(of: "SF BRIDGE") != nil  {
            if(!surefiDevices.contains(peripheral)) {
                
                let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data ?? Data()
                let peripheralDeviceID = manufacturerData.hexStringFromData()
                
                if peripheralDeviceID.uppercased().range(of: centralDeviceID!) != nil {
                    centralManufacturerDataString = peripheralDeviceID
                    centralPeripheral = peripheral
                    centralPeripheral.delegate = self
                    centralReady = -1
                    centralManager.connect(centralPeripheral, options: nil)
                }
                if peripheralDeviceID.uppercased().range(of: remoteDeviceID!) != nil {
                    remoteManufacturerDataString = peripheralDeviceID
                    remotePeripheral = peripheral
                    remotePeripheral.delegate = self
                    remoteReady = -1
                    centralManager.connect(remotePeripheral, options: nil)
                }
                surefiDevices.append(peripheral);
                tableView.reloadData()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if centralPeripheral != nil && peripheral == centralPeripheral {
            centralReady = 1
            centralConnected = true
            centralPeripheral.discoverServices(nil)
        }
        if remotePeripheral != nil && peripheral == remotePeripheral {
            remoteReady = 1
            remoteConnected = true
            remotePeripheral.discoverServices(nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service as CBService
            
            if service.uuid == SUREFI_SERVICE_UUID || service.uuid == SUREFI_SEC_SERVICE_UUID {
                peripheral.discoverCharacteristics(nil,for: thisService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,didDiscoverCharacteristicsFor service: CBService,error: Error?) {
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if(centralPeripheral != nil && peripheral == centralPeripheral) {
                if thisCharacteristic.uuid == SUREFI_TX_UID_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    centralTxCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_STATUS_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    centralStatusCharacteristic = thisCharacteristic
                    peripheral.readValue(for: thisCharacteristic)
                }
                if thisCharacteristic.uuid == SUREFI_SEC_HASH_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    centralSecHashCharacteristic = thisCharacteristic
                    
                    let data = getSecurityHash(manufacturerDataString: centralManufacturerDataString ?? "")
                    self.centralPeripheral.writeValue(data as Data, for: self.centralSecHashCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
            }
            if(remotePeripheral != nil && peripheral == remotePeripheral) {
                if thisCharacteristic.uuid == SUREFI_TX_UID_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    remoteTxCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_STATUS_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    remoteStatusCharacteristic = thisCharacteristic
                    peripheral.readValue(for: thisCharacteristic)
                }
                if thisCharacteristic.uuid == SUREFI_SEC_HASH_UUID {
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    remoteSecHashCharacteristic = thisCharacteristic
                    
                    let data = getSecurityHash(manufacturerDataString: remoteManufacturerDataString ?? "")
                    self.remotePeripheral.writeValue(data as Data, for: self.remoteSecHashCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == SUREFI_STATUS_UUID && centralPeripheral != nil && peripheral == centralPeripheral {
            
            let value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            centralStatusString = value
            if centralStatusString == "03" {
                centralCompleted = true
            }
            print("Central Status:\(value)")
        }
        if characteristic.uuid == SUREFI_STATUS_UUID && remotePeripheral != nil && peripheral == remotePeripheral {
            
            let value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            remoteStatusString = value
            if remoteStatusString == "03" {
                remoteCompleted = true
            }
            print("Remote Status:\(value)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if centralPeripheral != nil {
            centralManager.cancelPeripheralConnection(centralPeripheral)
        }
        if centralPeripheral != nil {
            centralManager.cancelPeripheralConnection(remotePeripheral)
        }
        centralManager?.stopScan()
    }
    
    func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().uuidString)"
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
