//
//  ConfigureRadioTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 5/25/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConfigureRadioTableViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var configureBridgeData :[String:String] = [:]
    
    var centralManager: CBCentralManager!
    var peripherals: Array<CBPeripheral> = Array<CBPeripheral>()
    var devicePeripheral: CBPeripheral!
    var surefiDevices: Array<CBPeripheral> = Array<CBPeripheral>()
    var surefiAdvertising: NSMutableDictionary = NSMutableDictionary()
    
    var deviceID: String?
    
    var deviceConnecting: Bool = false
    var deviceConnected: Bool = false
    
    var deviceTxCharacteristic: CBCharacteristic!
    var deviceStatusCharacteristic: CBCharacteristic!
    var deviceSecHashCharacteristic: CBCharacteristic!
    
    var deviceCmdWriteCharacteristic: CBCharacteristic!
    var deviceCmdReadCharacteristic: CBCharacteristic!
    
    var deviceManufacturerDataString: String = ""
    var deviceRadioSettingsDataString: String = ""
    
    var deviceApplicationFirmware: String = ""
    var deviceRadioFirmware: String = ""
    
    let SUREFI_SERVICE_UUID = CBUUID(string: "98BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_RX_UID_UUID  = CBUUID(string: "98BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_TX_UID_UUID  = CBUUID(string: "98BF000C-0EC5-2536-2143-2D155783CE78")
    let SUREFI_STATUS_UUID  = CBUUID(string: "98BF000D-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_SEC_SERVICE_UUID  = CBUUID(string: "58BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_SEC_HASH_UUID     = CBUUID(string: "58BF000B-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_CMD_SERVICE_UUID   = CBUUID(string:"C8BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_WRITE_UUID     = CBUUID(string:"C8BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_READ_UUID      = CBUUID(string:"C8BF000C-0EC5-2536-2143-2D155783CE78")
    
    var selectedSection = -1
    var selectedPower = -1
    var selectedSpreadingFactor = -1
    var selectedBandwidth = -1
    var selectedHeartbeat = -1
    var selectedRetry = -1
    var selectedAcks = -1
    
    var getMessageSent: Bool = false
    var updateSent: Bool = false
    
    let powerArray: [String] = ["1/8 Watt","1/4 Watt","1/2 Watt","1 Watt"]
    let spreadingFactorArray: [Int] = [7,8,9,10,11,12]
    let bandwidthArray: [Float] = [31.25,62.50,125,250,500]
    let heartbeatArray: [Int] = [0,15,30,60,90,120]
    let retryArray: [Int] = [0,1,2,3,4,5]
    let acksArray: [String] = ["Disabled","Enabled"]
    
    var deviceType: String! = ""
    
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Configure Radio"
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView?.backgroundView = backgroundImageView
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkConnection), userInfo: nil, repeats: true);

    }
    
    func checkConnection() {
        
        if deviceConnecting {
            
            if devicePeripheral.state == .connecting {
                print("Connecting to \(deviceID!) \(Date().unixTimestamp!)")
                self.tableView.reloadData()
            } else if devicePeripheral.state != .connected {
                deviceConnected = false
                self.tableView.reloadData()
                
            } else if deviceConnected == false && devicePeripheral.state == .connected {

                deviceConnected = true
                tableView.reloadData()
            }
        }
    }
    
    @IBAction func connectButtonPress(sender: UIButton) {
        
        if deviceConnected {
            disconnectDevice()
        } else {
            connectDevice()
        }
    }
    
    @IBAction func refreshButtonPress(sender: UIBarButtonItem) {
        
        let messageBytes: Data = Data([0x09])
        
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.delegate = self
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        
        getMessageSent = true
        
    }
    
    @IBAction func updateButtonPress(sender: UIBarButtonItem) {
        
        updateSent = true
        
        sender.isEnabled = false
        sender.title = "Updating..."
        
        var messageBytes: Data = Data([0x0A])
        
        messageBytes.append( UInt8(selectedSpreadingFactor + 1))
        messageBytes.append( UInt8(selectedBandwidth + 1))
        messageBytes.append( UInt8(selectedPower + 1))
        messageBytes.append( UInt8(retryArray[selectedRetry]))
        messageBytes.append( UInt8(heartbeatArray[selectedHeartbeat]))
        messageBytes.append( UInt8(selectedAcks))
        
        print(messageBytes.hexStringFromData())
        
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if deviceConnected {
            return 7
        }
        //if devicePeripheral == nil || devicePeripheral.state != .connected {
        //    return 1
        //}
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            if devicePeripheral != nil {
                if deviceConnected == true && deviceRadioSettingsDataString != "" && deviceApplicationFirmware != "" && deviceRadioFirmware != "" {
                    return 3
                }
                return 2
            } else {
                return 1
            }
        } else {
            
            if selectedSection == section {
                if section == 1 {
                    return powerArray.count + 1
                }
                if section == 2 {
                    return spreadingFactorArray.count + 1
                }
                if section == 3 {
                    return bandwidthArray.count + 1
                }
                if section == 4 {
                    return retryArray.count + 1
                }
                if section == 5 {
                    return heartbeatArray.count + 1
                }
                if section == 6 {
                    return acksArray.count + 1
                }
            }
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            return 148
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 {
            if indexPath.row == 0
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
                
                let imageView = cell.viewWithTag(100) as! UIImageView
                let label1 = cell.viewWithTag(200) as! UILabel
                let label2 = cell.viewWithTag(300) as! UILabel
                
                if deviceID ?? "" == "" {
                    imageView.image = UIImage(named:"hardware_select")
                    label1.text = "Scan Sure-Fi Unit"
                    label2.text = ""
                } else {
                    imageView.image = UIImage(named:"hardware_bridge")
                    label1.text = "Sure-Fi Bridge Unit"
                    label2.text = deviceID ?? ""
                }
                
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .none
            }
            if indexPath.row == 1
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "StatusCell", for: indexPath)
                
                let statusLabel = cell.viewWithTag(100) as! UILabel
                let statusButton = cell.viewWithTag(200) as! UIButton
                let extraLabel = cell.viewWithTag(300) as! UILabel
                statusButton.setTitleColor(.white, for: .normal)
                statusButton.layer.cornerRadius = 5
                statusButton.clipsToBounds = true
                statusButton.layer.masksToBounds = true
                statusButton.isHidden = false
                
                extraLabel.text = ""
                
                if deviceConnecting {
                    
                    if devicePeripheral.state == .connected {
                        statusLabel.text = "Connected"
                        statusLabel.textColor = UIColor(red: 0, green: 204, blue: 0)
                        statusButton.setTitle("Disconnect", for: .normal)
                        statusButton.backgroundColor = UIColor(red: 204, green: 0, blue: 0)
                    } else if devicePeripheral.state == .connecting {
                        statusLabel.text = "Connecting"
                        statusLabel.textColor = .orange
                        statusButton.isHidden = true
                        extraLabel.textColor = .gray
                        extraLabel.text = "Hold the Test button on the Bridge for 5 seconds"
                    }
                    
                } else {
                    statusLabel.text = "Disconnected"
                    statusLabel.textColor = UIColor(red: 204, green: 0, blue: 0)
                    statusButton.setTitle("Connect", for: .normal)
                    statusButton.backgroundColor = UIColor(red: 0, green: 204, blue: 0)
                }
                statusButton.addTarget(self, action: #selector(connectButtonPress(sender:)), for: .touchUpInside)
                
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
            if indexPath.row == 2
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "TempCell", for: indexPath)
                cell.textLabel?.text = "Firmware - App v\(deviceApplicationFirmware.substring(from: 0).substring(to: 2)).\(deviceApplicationFirmware.substring(from: 2).substring(to: 2)) - Radio v\(deviceRadioFirmware.substring(from: 0).substring(to: 2)).\(deviceRadioFirmware.substring(from: 2).substring(to: 2))"
                cell.textLabel?.adjustsFontSizeToFitWidth = true
                cell.detailTextLabel?.text = ""
                
                if deviceManufacturerDataString != "" {
                    
                    let hardwareType = deviceManufacturerDataString.substring(from: 4).substring(to: 2)
                    let firmwareVersion = deviceManufacturerDataString.substring(from: 6).substring(to: 4)
                    let status = deviceManufacturerDataString.substring(from: 10).substring(to: 2)
                    let deviceID = deviceManufacturerDataString.substring(from: 12).substring(to: 6)
                    let remoteID = deviceManufacturerDataString.substring(from: 18).substring(to: 6)
                    
                    if deviceRadioSettingsDataString != "" {
                        
                        let spreadingFactor = Int(deviceRadioSettingsDataString.substring(from: 0).substring(to: 2).hexaToDecimal) - 1
                        let bandwidth       = Int(deviceRadioSettingsDataString.substring(from: 2).substring(to: 2).hexaToDecimal) - 1
                        let powerAmp        = Int(deviceRadioSettingsDataString.substring(from: 4).substring(to: 2).hexaToDecimal) - 1
                        let retryCount      = Int(deviceRadioSettingsDataString.substring(from: 6).substring(to: 2).hexaToDecimal)
                        let heartbeat       = Int(deviceRadioSettingsDataString.substring(from: 8).substring(to: 2).hexaToDecimal)
                        let acks            = Int(deviceRadioSettingsDataString.substring(from: 10).substring(to: 2).hexaToDecimal)
                        cell.detailTextLabel?.text = "Paired With:\(remoteID) SF\(spreadingFactorArray[spreadingFactor]) \(bandwidthArray[bandwidth])kHz @\(powerArray[powerAmp])"
                    }
                }
                
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        } else {
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
                cell.detailTextLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                if indexPath.section == 1 {
                    cell.textLabel?.text = "Power"
                    if selectedPower >= 0 {
                        cell.detailTextLabel?.text = powerArray[selectedPower]
                    } else {
                        cell.detailTextLabel?.text = "Unknown"
                    }
                }
                if indexPath.section == 2 {
                    cell.textLabel?.text = "Spreading Factor"
                    if selectedSpreadingFactor >= 0 {
                        cell.detailTextLabel?.text = "SF\(spreadingFactorArray[selectedSpreadingFactor])"
                    } else {
                        cell.detailTextLabel?.text = "Unknown"
                    }
                }
                if indexPath.section == 3 {
                    cell.textLabel?.text = "Bandwidth"
                    if selectedBandwidth >= 0 {
                        cell.detailTextLabel?.text = "\(bandwidthArray[selectedBandwidth]) kHz"
                    } else {
                        cell.detailTextLabel?.text = "Unknown"
                    }
                }
                if indexPath.section == 4 {
                    cell.textLabel?.text = "Retry Count"
                    if selectedRetry >= 0 {
                        cell.detailTextLabel?.text = "\(retryArray[selectedRetry])"
                    } else {
                        cell.detailTextLabel?.text = "Unknown"
                    }
                }
                if indexPath.section == 5 {
                    cell.textLabel?.text = "Heartbeat Period"
                    if selectedHeartbeat >= 0 {
                        cell.detailTextLabel?.text = "\(heartbeatArray[selectedHeartbeat]) sec"
                    } else {
                        cell.detailTextLabel?.text = "Unknown"
                    }
                }
                if indexPath.section == 6 {
                    cell.textLabel?.text = "Acknowledments"
                    if selectedAcks >= 0 {
                        cell.detailTextLabel?.text = "\(acksArray[selectedAcks])"
                    } else {
                        cell.detailTextLabel?.text = "Unknown"
                    }
                }
                cell.accessoryType = .disclosureIndicator
                
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
                cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
                
                if indexPath.section == 1 {
                    cell.textLabel?.text = powerArray[indexPath.row - 1]
                    if selectedPower == indexPath.row - 1 {
                        cell.imageView?.image = UIImage(named: "check")
                    } else {
                        cell.imageView?.image = nil
                    }
                }
                if indexPath.section == 2 {
                    cell.textLabel?.text = "SF\(spreadingFactorArray[indexPath.row - 1])"
                    if selectedSpreadingFactor == indexPath.row - 1 {
                        cell.imageView?.image = UIImage(named: "check")
                    } else {
                        cell.imageView?.image = nil
                    }
                }
                if indexPath.section == 3 {
                    cell.textLabel?.text = "\(bandwidthArray[indexPath.row - 1]) kHz"
                    if selectedBandwidth == indexPath.row - 1 {
                        cell.imageView?.image = UIImage(named: "check")
                    } else {
                        cell.imageView?.image = nil
                    }
                }
                if indexPath.section == 4 {
                    cell.textLabel?.text = "\(retryArray[indexPath.row - 1])"
                    if selectedRetry == indexPath.row - 1 {
                        cell.imageView?.image = UIImage(named: "check")
                    } else {
                        cell.imageView?.image = nil
                    }
                }
                if indexPath.section == 5 {
                    cell.textLabel?.text = "\(heartbeatArray[indexPath.row - 1]) sec"
                    if selectedHeartbeat == indexPath.row - 1 {
                        cell.imageView?.image = UIImage(named: "check")
                    } else {
                        cell.imageView?.image = nil
                    }
                }
                if indexPath.section == 6 {
                    cell.textLabel?.text = "\(acksArray[indexPath.row - 1])"
                    if selectedAcks == indexPath.row - 1 {
                        cell.imageView?.image = UIImage(named: "check")
                    } else {
                        cell.imageView?.image = nil
                    }
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "ConfigureRadioSelectViewController") as! ConfigureRadioSelectViewController
            controller.configureRadioTableViewController = self
            controller.bridgeRequiredStatus = "03"
            self.navigationController?.pushViewController(controller, animated: true)
            
        } else {
            if indexPath.row == 0 {
                if indexPath.section == selectedSection {
                    selectedSection = -1
                } else {
                    selectedSection = indexPath.section
                }
            } else {
                if indexPath.section == 1 {
                    selectedPower = indexPath.row - 1
                }
                if indexPath.section == 2 {
                    selectedSpreadingFactor = indexPath.row - 1
                }
                if indexPath.section == 3 {
                    selectedBandwidth = indexPath.row - 1
                }
                if indexPath.section == 4 {
                    selectedRetry = indexPath.row - 1
                }
                if indexPath.section == 5 {
                    selectedHeartbeat = indexPath.row - 1
                }
                if indexPath.section == 6 {
                    selectedAcks = indexPath.row - 1
                }
            }
        }
        
        self.tableView.reloadData()
        
    }
    
    func selectDevicePeripheral() {
        
        for index in 0...(surefiDevices.count-1) {
            
            let peripheral = surefiDevices[index]
            let advertisementData = surefiAdvertising.object(forKey: String(index)) as? [String:Any] ?? [String:Any]()
            let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data ?? Data()
            
            let manufacturerString = manufacturerData.hexStringFromData()
            var deviceStatusString = ""
            var peripheralDeviceID = ""
            
            if manufacturerString.substring(to: 4).uppercased() == "FFFF" {
                deviceStatusString = manufacturerString.substring(from: 4).substring(to: 8)
                peripheralDeviceID = manufacturerString.substring(from: 12).substring(to: 6)
            } else {
                deviceStatusString = manufacturerString.substring(from: 0).substring(to: 8)
                peripheralDeviceID = manufacturerString.substring(from: 8).substring(to: 6)
            }
            
            if peripheralDeviceID.uppercased().range(of: deviceID ?? "") != nil {
                let status = deviceStatusString.substring(from: 6).substring(to: 2)
                if status == "03" {
                    deviceManufacturerDataString = manufacturerString
                    devicePeripheral = peripheral
                    devicePeripheral.delegate = self
                    connectDevice()
                }
            }
        }
        tableView.reloadData()
    }
    
    func connectDevice() {
        
        if devicePeripheral != nil {
            print("Connecting to Device... \(deviceID!)")
            deviceConnecting = true
            centralManager.connect(devicePeripheral, options: nil)
        }
    }
    
    func disconnectDevice() {
        
        if devicePeripheral != nil {
            print("Disconnecting from Device... \(deviceID!)")
            deviceConnecting = false
            deviceConnected = false
            centralManager.cancelPeripheralConnection(devicePeripheral)
        }
    }
    
    func getDeviceApplicationFirmwareData() {
        
        var messageBytes: Data = Data()
        messageBytes.append(0x01)
        
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getDeviceRadioFirmwareData() {
        
        var messageBytes: Data = Data()
        messageBytes.append(0x02)
        
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        
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
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("Disconnected from Device... \(deviceID!)")
        self.tableView.reloadData()
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        let name = peripheral.name;
        if name?.uppercased().range(of: "SURE-FI") != nil || name?.uppercased().range(of: "SF BRIDGE") != nil {
            
            if(!surefiDevices.contains(peripheral)) {
                surefiDevices.append(peripheral);
                
                let index = String(surefiDevices.index(of: peripheral)!)
                surefiAdvertising.setValue(advertisementData, forKey: index)
                
                self.tableView.reloadData()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if devicePeripheral != nil && peripheral == devicePeripheral {
            print("Device Connected...\(deviceID!)")
            devicePeripheral.discoverServices(nil)
            self.tableView.reloadData()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service as CBService
            
            if service.uuid == SUREFI_SERVICE_UUID || service.uuid == SUREFI_SEC_SERVICE_UUID || service.uuid == SUREFI_CMD_SERVICE_UUID {
                print("Discovered Service...\(service.uuid)")
                peripheral.discoverCharacteristics(nil,for: thisService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,didDiscoverCharacteristicsFor service: CBService,error: Error?) {
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if devicePeripheral != nil && peripheral == devicePeripheral {
                if thisCharacteristic.uuid == SUREFI_TX_UID_UUID {
                    print("Discovered Characteristic - SUREFI_TX_UID_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceTxCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_STATUS_UUID {
                    print("Discovered Characteristic - SUREFI_STATUS_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceStatusCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_SEC_HASH_UUID {
                    print("Discovered Characteristic - SUREFI_SEC_HASH_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceSecHashCharacteristic = thisCharacteristic
                    
                    let data = getSecurityHash(manufacturerDataString: deviceManufacturerDataString)
                    print("Writing to Security Characteristic - \(data)")
                    self.devicePeripheral.writeValue(data as Data, for: self.deviceSecHashCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
                if thisCharacteristic.uuid == SUREFI_CMD_WRITE_UUID {
                    print("Discovered Characteristic - SUREFI_CMD_WRITE_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceCmdWriteCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_CMD_READ_UUID {
                    print("Discovered Characteristic - SUREFI_CMD_READ_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceCmdReadCharacteristic = thisCharacteristic
                }
            }
            
            if deviceSecHashCharacteristic != nil && deviceCmdReadCharacteristic != nil && deviceCmdWriteCharacteristic != nil && getMessageSent == false {
                
                print("Getting Current Radio Settings")
                let messageBytes: Data = Data([0x09])
                print("BLE Cmd:\(messageBytes.hexStringFromData())")
                devicePeripheral.delegate = self
                devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
                getMessageSent = true
                
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
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if devicePeripheral != nil {
            centralManager.cancelPeripheralConnection(devicePeripheral)
        }
        centralManager.stopScan()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == SUREFI_CMD_WRITE_UUID {
            
            if updateSent {
                let alert: UIAlertController = UIAlertController(title: "Update Complete", message: "Sure-Fi Radio Settings successfully updated.", preferredStyle: UIAlertControllerStyle.alert);
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                self.present(alert,animated: true, completion: nil);
                updateSent = false
                
                let refreshButton = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refreshButtonPress(sender:)))
                navigationItem.rightBarButtonItem = refreshButton
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
            case "08":
                
                deviceRadioSettingsDataString = data
                
                let spreadingFactor = data.substring(from:  0).substring(to: 2).hexaToDecimal
                let bandwidth       = data.substring(from:  2).substring(to: 2).hexaToDecimal
                let powerAmp        = data.substring(from:  4).substring(to: 2).hexaToDecimal
                let retryCount      = data.substring(from:  6).substring(to: 2).hexaToDecimal
                let heartbeat       = data.substring(from:  8).substring(to: 2).hexaToDecimal
                let acks            = data.substring(from: 10).substring(to: 2).hexaToDecimal
                
                selectedSpreadingFactor = spreadingFactor - 1
                selectedBandwidth = bandwidth - 1
                selectedPower = powerAmp - 1
                selectedRetry = retryArray.index(of: retryCount) ?? -1
                selectedHeartbeat = heartbeatArray.index(of: heartbeat) ?? -1
                selectedAcks = acks
                
                let updateButton = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(updateButtonPress(sender:)))
                navigationItem.rightBarButtonItem = updateButton
                
                getDeviceApplicationFirmwareData()
                self.tableView.reloadData()
                
            case "01": //Application Firmware Version
                
                print("Application Firmware Data: \(data)")
                deviceApplicationFirmware = data
                getDeviceRadioFirmwareData()
                self.tableView.reloadData()
                
            case "09": //Radio Firmware Version
                
                print("Radio Firmware Data: \(data)")
                deviceRadioFirmware = data
                self.tableView.reloadData()
                
            default:
                break
                
            }
        }
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
