//
//  BridgeConfigureTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 5/15/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth

class BridgeConfigureTableViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var configureBridgeData :[String:String] = [:]
    
    let peripheralStatusArray: [String:String] = ["01":"Ready for Pairing","02":"Pairing","03":"Paired"]
    let peripheralTypeArray: [String:String] = ["01":"Central Unit","02":"Remote Unit"]
    
    let powerArray: [String] = ["1/8 Watt","1/4 Watt","1/2 Watt","1 Watt"]
    let spreadingFactorArray: [Int] = [7,8,9,10,11,12]
    let bandwidthArray: [Float] = [31.25,62.50,125,250,500]
    let heartbeatArray: [Int] = [0,15,30,60,90,120]
    let retryArray: [Int] = [0,1,2,3,4,5]
    let acksArray: [String] = ["Disabled","Enabled"]
    
    var centralManager: CBCentralManager!
    var peripherals: Array<CBPeripheral> = Array<CBPeripheral>()
    var centralPeripheral: CBPeripheral!
    var remotePeripheral: CBPeripheral!
    var surefiDevices: Array<CBPeripheral> = Array<CBPeripheral>()
    var surefiAdvertising: NSMutableDictionary = NSMutableDictionary()
    
    var centralDeviceID: String?
    var remoteDeviceID: String?
    
    var centralApplicationFirmware: String = ""
    var remoteApplicationFirmware: String = ""
    
    var centralRadioFirmware: String = ""
    var remoteRadioFirmware: String = ""
    
    var centralRadioSettings: String = ""
    var remoteRadioSettings: String = ""
    
    var centralConnected: Bool = false
    var remoteConnected: Bool = false
    
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
    var disconnectBluetooth: Bool = true
    
    let SUREFI_SERVICE_UUID = CBUUID(string: "98BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_RX_UID_UUID  = CBUUID(string: "98BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_TX_UID_UUID  = CBUUID(string: "98BF000C-0EC5-2536-2143-2D155783CE78")
    let SUREFI_STATUS_UUID  = CBUUID(string: "98BF000D-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_SEC_SERVICE_UUID  = CBUUID(string: "58BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_SEC_HASH_UUID     = CBUUID(string: "58BF000B-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_CMD_SERVICE_UUID = CBUUID(string:"C8BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_WRITE_UUID     = CBUUID(string:"C8BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_READ_UUID      = CBUUID(string:"C8BF000C-0EC5-2536-2143-2D155783CE78")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Configure Sure-Fi Bridge"
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView?.backgroundView = backgroundImageView
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(checkConnection), userInfo: nil, repeats: true);
        
    }
    
    func checkConnection() {
        
        if centralConnected {
            
            if centralPeripheral.state == .connecting {
                self.tableView.reloadData()
            } else if centralPeripheral.state != .connected {
                centralConnected = false
                self.tableView.reloadData()
                
            } else {
                //print("Central Connected")
            }
        }
        if remoteConnected {
            
            if remotePeripheral.state == .connecting {
                self.tableView.reloadData()
            } else if remotePeripheral.state != .connected {
                remoteConnected = false
                self.tableView.reloadData()
                
            } else {
                //print("Remote Connected")
            }
        }
        
    }
    
    func setBridgeDataValue( field: String, value: String) {
        configureBridgeData[field] = value
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if centralPeripheral != nil {
            
            if centralPeripheral.state == .connected {
                
                if remotePeripheral != nil && remotePeripheral.state == .connected {
                    return 5
                }
                return 4
            }
            return 3
        }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            return 148
        }
        if centralPeripheral != nil && centralPeripheral.state == .connected {
            
            if indexPath.section == 2 && indexPath.row == 0 {
                return 148
            }
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            if centralPeripheral != nil {
                if centralApplicationFirmware != "" && centralRadioFirmware != "" {
                     return 3
                }
                return 2
            }
            else {
                return 1
            }
        }
        
        if centralPeripheral != nil && centralPeripheral.state == .connected {
            
            if section == 1 {
                return 4
            }
            if section == 2 {
                if remotePeripheral != nil {
                    if remoteApplicationFirmware != "" && remoteRadioFirmware != "" {
                        return 3
                    }
                    return 2
                }
                else {
                    return 1
                }
            }
            if section == 3 {
                return 2
            }
            if section == 4 {
                return surefiDevices.count
            }
        } else if remotePeripheral != nil && centralPeripheral.state == .connected && section == 3 {
            return 2
        } else {
            
            if section == 1 {
                return surefiDevices.count
            }
            
        }
        
        return 0
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
        if centralPeripheral != nil && centralPeripheral.state == .connected {
            if(section==1) {
                return "Central Configuration"
            }
            if(section==2) {
                return "Remote Unit"
            }
            
            if remotePeripheral != nil && remotePeripheral.state == .connected {
                
                if(section==3) {
                    return "Remote Configuration"
                }
                if(section==4) {
                    return "Sure-Fi Devices"
                }
                
            }
            if(section==3) {
                return "Sure-Fi Devices"
            }
            
        } else {
            if(section==1) {
                return "Sure-Fi Devices"
            }
        }
        return ""
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
                
                if configureBridgeData["device_id_central"]==nil {
                    imageView.image = UIImage(named:"hardware_select")
                    label1.text = "Scan Central Unit"
                    label2.text = ""
                } else {
                    imageView.image = UIImage(named:"hardware_bridge")
                    label1.text = "Sure-Fi Bridge Central"
                    label2.text = configureBridgeData["device_id_central"] ?? ""
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
                
                if centralConnected {
                    
                    if centralPeripheral.state == .connected {
                        statusLabel.text = "Connected"
                        statusLabel.textColor = UIColor(red: 0, green: 204, blue: 0)
                        statusButton.setTitle("Disconnect", for: .normal)
                        statusButton.backgroundColor = UIColor(red: 204, green: 0, blue: 0)
                    } else if centralPeripheral.state == .connecting {
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
                statusButton.addTarget(self, action: #selector(connectCentralButtonPress(sender:)), for: .touchUpInside)
                
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
            if indexPath.row == 2
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "TempCell", for: indexPath)
                cell.textLabel?.text = "Firmware - App v\(centralApplicationFirmware.substring(from: 0).substring(to: 2)).\(centralApplicationFirmware.substring(from: 2).substring(to: 2)) - Radio v\(centralRadioFirmware.substring(from: 0).substring(to: 2)).\(centralRadioFirmware.substring(from: 2).substring(to: 2))"
                cell.textLabel?.adjustsFontSizeToFitWidth = true
                cell.detailTextLabel?.text = ""
                
                for (key, value) in surefiAdvertising {
                    
                    let advertisementData = value as! [String:Any]
                    let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as! Data
                    let manufacturerDataString = manufacturerData.hexStringFromData().uppercased()
                    
                    let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
                    let firmwareVersion = manufacturerDataString.substring(from: 6).substring(to: 4)
                    let status = manufacturerDataString.substring(from: 10).substring(to: 2)
                    let deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
                    let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
                    
                    if deviceID == configureBridgeData["device_id_central"] && centralRadioSettings != "" {
                        
                        let spreadingFactor = Int(centralRadioSettings.substring(from: 0).substring(to: 2).hexaToDecimal) - 1
                        let bandwidth       = Int(centralRadioSettings.substring(from: 2).substring(to: 2).hexaToDecimal) - 1
                        let powerAmp        = Int(centralRadioSettings.substring(from: 4).substring(to: 2).hexaToDecimal) - 1
                        let retryCount      = Int(centralRadioSettings.substring(from: 6).substring(to: 2).hexaToDecimal)
                        let heartbeat       = Int(centralRadioSettings.substring(from: 8).substring(to: 2).hexaToDecimal)
                        let acks            = Int(centralRadioSettings.substring(from: 10).substring(to: 2).hexaToDecimal)
                        cell.detailTextLabel?.text = "Paired With:\(remoteID) SF\(spreadingFactorArray[spreadingFactor]) \(bandwidthArray[bandwidth])kHz @\(powerArray[powerAmp])"
                    }
                }
                
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        } else if ((centralPeripheral == nil || centralPeripheral.state != .connected) && indexPath.section == 1) || (centralPeripheral != nil && centralPeripheral.state == .connected && (remotePeripheral == nil || remotePeripheral.state != .connected) && indexPath.section == 3)  || (centralPeripheral != nil && centralPeripheral.state == .connected && remotePeripheral != nil && remotePeripheral.state == .connected && indexPath.section == 4) {
            
            let surefiDevice = surefiDevices[indexPath.row]
            let advertisementData = surefiAdvertising.object(forKey: String(indexPath.row)) as? [String: Any] ?? [String: Any]()
            let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as! Data
            let manufacturerDataString = manufacturerData.hexStringFromData().uppercased()
            
            //let manufacturerID = manufacturerDataString.substring(from: 0).substring(to: 4)
            let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
            let firmwareVersion = manufacturerDataString.substring(from: 6).substring(to: 4)
            let status = manufacturerDataString.substring(from: 10).substring(to: 2)
            let deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
            let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
            
            cell = tableView.dequeueReusableCell(withIdentifier: "TempCell", for: indexPath)
            
            cell.textLabel?.text = surefiDevice.name ?? ""
            cell.detailTextLabel?.text = "RX:\(deviceID) TX:\(remoteID) TP:\(hardwareType) VER:\(firmwareVersion) STAT:\(status)"
            
            cell.selectionStyle = .none
            
        } else if centralPeripheral != nil && centralPeripheral.state == .connected && indexPath.section == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "CommandCell", for: indexPath)
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Unpair Bridge"
            }
            if indexPath.row == 1 {
                cell.textLabel?.text = "Update Firmware - Application"
            }
            if indexPath.row == 2 {
                cell.textLabel?.text = "Update Firmware - Radio"
            }
            if indexPath.row == 3 {
                cell.textLabel?.text = "Update Firmware - Bluetooth"
            }
            
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .none
            
        } else if indexPath.section == 2 {
            
            if indexPath.row == 0
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
                
                let imageView = cell.viewWithTag(100) as! UIImageView
                let label1 = cell.viewWithTag(200) as! UILabel
                let label2 = cell.viewWithTag(300) as! UILabel
                
                if configureBridgeData["device_id_remote"]==nil {
                    imageView.image = UIImage(named:"hardware_select")
                    label1.text = "Scan Remote Unit"
                    label2.text = ""
                } else {
                    imageView.image = UIImage(named:"hardware_bridge")
                    label1.text = "Sure-Fi Bridge Remote"
                    label2.text = configureBridgeData["device_id_remote"] ?? ""
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
                
                if remoteConnected {
                    
                    if remotePeripheral.state == .connected {
                        statusLabel.text = "Connected"
                        statusLabel.textColor = UIColor(red: 0, green: 204, blue: 0)
                        statusButton.setTitle("Disconnect", for: .normal)
                        statusButton.backgroundColor = UIColor(red: 204, green: 0, blue: 0)
                    } else if remotePeripheral.state == .connecting {
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
                statusButton.addTarget(self, action: #selector(connectRemoteButtonPress(sender:)), for: .touchUpInside)
                
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
            if indexPath.row == 2
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "TempCell", for: indexPath)
                cell.textLabel?.text = "Firmware - App v\(remoteApplicationFirmware.substring(from: 0).substring(to: 2)).\(remoteApplicationFirmware.substring(from: 2).substring(to: 2)) - Radio v\(remoteRadioFirmware.substring(from: 0).substring(to: 2)).\(remoteRadioFirmware.substring(from: 2).substring(to: 2))"
                cell.textLabel?.adjustsFontSizeToFitWidth = true
                cell.detailTextLabel?.text = ""
                
                for (key, value) in surefiAdvertising {
                    
                    let advertisementData = value as! [String:Any]
                    let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as! Data
                    let manufacturerDataString = manufacturerData.hexStringFromData().uppercased()
                    
                    let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
                    let firmwareVersion = manufacturerDataString.substring(from: 6).substring(to: 4)
                    let status = manufacturerDataString.substring(from: 10).substring(to: 2)
                    let deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
                    let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
                    
                    if deviceID == configureBridgeData["device_id_remote"] {
                        cell.detailTextLabel?.text = "Paired With:\(remoteID) \(remoteRadioSettings)"
                    }
                }
                cell.accessoryType = .none
                cell.selectionStyle = .none
           }
        } else if remotePeripheral != nil && remotePeripheral.state == .connected && indexPath.section == 3 {
            cell = tableView.dequeueReusableCell(withIdentifier: "CommandCell", for: indexPath)
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Update Firmware - Application"
            }
            if indexPath.row == 1 {
                cell.textLabel?.text = "Update Firmware - Radio"
            }
            
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .none
            
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        disconnectBluetooth = false
        if indexPath.section == 0 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "BridgeSelectViewController") as! BridgeSelectViewController
            controller.bridgeConfigureTableViewController = self
            controller.bridgeDataField = "device_id_central"
            controller.bridgeRequiredStatus = "03"
            self.navigationController?.pushViewController(controller, animated: true)
        }
        if centralPeripheral != nil && centralPeripheral.state == .connected && indexPath.section == 1 {
            if indexPath.row == 0 {
                unpairBridge()
            }
            if indexPath.row == 1 {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "BridgeFirmwareUpdateViewController") as! BridgeFirmwareUpdateViewController
                controller.bridgeConfigureTableViewController = self
                controller.hardwareType = "CENTRAL"
                controller.firmwareType = "APPLICATION"
                self.navigationController?.pushViewController(controller, animated: true)
            }
            if indexPath.row == 2 {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "BridgeFirmwareUpdateViewController") as! BridgeFirmwareUpdateViewController
                controller.bridgeConfigureTableViewController = self
                controller.hardwareType = "CENTRAL"
                controller.firmwareType = "RADIO"
                self.navigationController?.pushViewController(controller, animated: true)
            }
            if indexPath.row == 3 {
                updateBluetooth()
            }
       }
        if centralPeripheral != nil && centralPeripheral.state == .connected && indexPath.section == 2 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "BridgeSelectViewController") as! BridgeSelectViewController
            controller.bridgeConfigureTableViewController = self
            controller.bridgeDataField = "device_id_remote"
            controller.bridgeRequiredStatus = "03"
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        if remotePeripheral != nil && remotePeripheral.state == .connected && indexPath.section == 3 {
            
            if indexPath.row == 0 {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "BridgeFirmwareUpdateViewController") as! BridgeFirmwareUpdateViewController
                controller.bridgeConfigureTableViewController = self
                controller.hardwareType = "REMOTE"
                controller.firmwareType = "APPLICATION"
                self.navigationController?.pushViewController(controller, animated: true)
            }
            if indexPath.row == 1 {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "BridgeFirmwareUpdateViewController") as! BridgeFirmwareUpdateViewController
                controller.bridgeConfigureTableViewController = self
                controller.hardwareType = "REMOTE"
                controller.firmwareType = "RADIO"
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    func updateBluetooth() {
        
        let data = ("1A").dataFromHexString()
        self.centralPeripheral.writeValue(data! as Data, for: self.centralCmdWriteCharacteristic, type: CBCharacteristicWriteType.withResponse)
        
    }
    
    func selectCentralPeripheral() {
        
        for index in 0...(surefiDevices.count-1) {
            
            let peripheral = surefiDevices[index]
            let advertisementData = surefiAdvertising.object(forKey: String(index)) as? [String:Any] ?? [String:Any]()
            let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data ?? Data()
            
            let manufacturerString = manufacturerData.hexStringFromData()
            var deviceStatusString = ""
            //var remoteDeviceID = ""
            var peripheralDeviceID = ""
            
            if manufacturerString.substring(to: 4).uppercased() == "FFFF" {
                deviceStatusString = manufacturerString.substring(from: 4).substring(to: 8)
                peripheralDeviceID = manufacturerString.substring(from: 12).substring(to: 6)
            } else {
                deviceStatusString = manufacturerString.substring(from: 0).substring(to: 8)
                peripheralDeviceID = manufacturerString.substring(from: 8).substring(to: 6)
            }
            
            if peripheralDeviceID.uppercased().range(of: configureBridgeData["device_id_central"] ?? "") != nil {
                let status = deviceStatusString.substring(from: 6).substring(to: 2)
                if status == "03" {
                    centralManufacturerDataString = manufacturerString
                    centralPeripheral = peripheral
                    centralPeripheral.delegate = self
                    connectCentralDevice()
                }
            }
        }
        tableView.reloadData()
    }
    
    func selectRemotePeripheral() {
        
        for index in 0...(surefiDevices.count-1) {
            
            let peripheral = surefiDevices[index]
            let advertisementData = surefiAdvertising.object(forKey: String(index)) as? [String:Any] ?? [String:Any]()
            let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data ?? Data()
            
            let manufacturerString = manufacturerData.hexStringFromData()
            var deviceStatusString = ""
            //var remoteDeviceID = ""
            var peripheralDeviceID = ""
            
            if manufacturerString.substring(to: 4).uppercased() == "FFFF" {
                deviceStatusString = manufacturerString.substring(from: 4).substring(to: 8)
                peripheralDeviceID = manufacturerString.substring(from: 12).substring(to: 6)
            } else {
                deviceStatusString = manufacturerString.substring(from: 0).substring(to: 8)
                peripheralDeviceID = manufacturerString.substring(from: 8).substring(to: 6)
            }
            
            if peripheralDeviceID.uppercased().range(of: configureBridgeData["device_id_remote"] ?? "") != nil {
                let status = deviceStatusString.substring(from: 6).substring(to: 2)
                if status == "03" {
                    remoteManufacturerDataString = manufacturerString
                    remotePeripheral = peripheral
                    remotePeripheral.delegate = self
                    connectRemoteDevice()
                }
            }
        }
        tableView.reloadData()
    }
    
    func connectCentralDevice() {
        
        if centralPeripheral != nil {
            centralConnected = true
            centralManager.connect(centralPeripheral, options: nil)
        }
    }
    
    func disconnectCentralDevice() {
        
        if centralPeripheral != nil {
            centralManager.cancelPeripheralConnection(centralPeripheral)
            centralConnected = false
            self.tableView.reloadData()
        }
    }
    
    func connectRemoteDevice() {
        
        if remotePeripheral != nil {
            remoteConnected = true
            centralManager.connect(remotePeripheral, options: nil)
        }
    }
    
    func disconnectRemoteDevice() {
        
        if remotePeripheral != nil {
            centralManager.cancelPeripheralConnection(remotePeripheral)
            remoteConnected = false
            self.tableView.reloadData()
        }
    }
    
    @IBAction func connectCentralButtonPress(sender: UIButton) {
        
        if centralConnected {
            disconnectCentralDevice()
        } else {
            connectCentralDevice()
        }
    }
    
    @IBAction func connectRemoteButtonPress(sender: UIButton) {
        
        if remoteConnected {
            disconnectRemoteDevice()
        } else {
            connectRemoteDevice()
        }
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
            
            if centralDeviceID != nil && peripheralDeviceID.uppercased().range(of: centralDeviceID!) != nil {
                centralPeripheral = peripheral
                centralPeripheral.delegate = self
            }
            if remoteDeviceID != nil && peripheralDeviceID.uppercased().range(of: remoteDeviceID!) != nil {
                remotePeripheral = peripheral
                remotePeripheral.delegate = self
            }
            if(!surefiDevices.contains(peripheral)) {
                surefiDevices.append(peripheral);
                
                let index = String(surefiDevices.index(of: peripheral)!)
                surefiAdvertising.setValue(advertisementData, forKey: index)
                
                self.tableView.reloadData()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if centralPeripheral != nil && peripheral == centralPeripheral {
            centralPeripheral.discoverServices(nil)
            self.tableView.reloadData()
        }
        if remotePeripheral != nil && peripheral == remotePeripheral {
            remotePeripheral.discoverServices(nil)
            self.tableView.reloadData()
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
                
                if centralCmdReadCharacteristic != nil && centralCmdWriteCharacteristic != nil {
                    getCentralApplicationFirmwareData()
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
                
                if remoteCmdReadCharacteristic != nil && remoteCmdWriteCharacteristic != nil {
                    getRemoteApplicationFirmwareData()
                }
           }
        }
    }
    
    func getCentralApplicationFirmwareData() {
        
        var messageBytes: Data = Data()
        messageBytes.append(0x01)
        
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        centralPeripheral.writeValue(messageBytes, for: centralCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getCentralRadioFirmwareData() {
        
        var messageBytes: Data = Data()
        messageBytes.append(0x02)
        
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        centralPeripheral.writeValue(messageBytes, for: centralCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getCentralRadioSettingsData() {
        
        var messageBytes: Data = Data()
        messageBytes.append(0x09)
        
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        centralPeripheral.writeValue(messageBytes, for: centralCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getRemoteApplicationFirmwareData() {
        
        var messageBytes: Data = Data()
        messageBytes.append(0x01)
        
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        remotePeripheral.writeValue(messageBytes, for: remoteCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getRemoteRadioFirmwareData() {
        
        var messageBytes: Data = Data()
        messageBytes.append(0x02)
        
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        remotePeripheral.writeValue(messageBytes, for: remoteCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getRemoteRadioSettingsData() {
        
        var messageBytes: Data = Data()
        messageBytes.append(0x09)
        
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        remotePeripheral.writeValue(messageBytes, for: remoteCmdWriteCharacteristic, type: .withResponse)
        
    }
    func getSecurityHash(manufacturerDataString: String) -> Data {
        
        let peripheralRXUUID = manufacturerDataString.substring(from: 12).substring(to: 6)
        let peripheralTXUUID = manufacturerDataString.substring(from:18).substring(to: 6)
        let string = "\(String(peripheralRXUUID.uppercased().characters.reversed()))\(peripheralTXUUID.uppercased())x~sW5-C\"6fu>!!~X"
        let data = string.getMD5()
        return data
    }
    
    func getCentralHash() -> Data {
        
        let peripheralRXUUID = centralManufacturerDataString.substring(from: 12).substring(to: 6)
        let peripheralTXUUID = centralManufacturerDataString.substring(from:18).substring(to: 6)
        let string = "\(String(peripheralRXUUID.uppercased().characters.reversed()))\(peripheralTXUUID.uppercased())x~sW5-C\"6fu>!!~X"
        let data = string.getMD5()
        return data
    }
    
    func unpairBridge() {
        
        if centralTxCharacteristic == nil {
            
            let alertController = UIAlertController(title: "Error", message: "Unable to find correct BLE Characteristic", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .destructive, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        let alertController = UIAlertController(title: "Un-Pair Bridge", message: "Are you sure you want to Un-Pair this Sure-Fi Bridge", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Un-Pair", style: .destructive, handler: {
            action in
            
            let unpairBridgeSystemData = NSMutableDictionary()
            unpairBridgeSystemData.setValue(self.configureBridgeData["device_id_central"] ?? "", forKey: "bridge_serial_central")
            unpairBridgeSystemData.setValue(self.configureBridgeData["device_id_remote"] ?? "", forKey: "bridge_serial_remote")
            SessionController().postServerRequest(action: "systems/unpair_bridge_system", postData: unpairBridgeSystemData, urlData:"", callback: self.unpairBridgeSystemCallback)
            
        })
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func unpairBridgeSystemCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        print("Data:\(data)")
        DispatchQueue.main.async {
            if status {
                
                let data = ("000000").dataFromHexString()
                self.centralPeripheral.writeValue(data! as Data, for: self.centralTxCharacteristic, type: CBCharacteristicWriteType.withResponse)
                
                let alertController = UIAlertController(title: "Success", message: "Un-Pair Message successfully sent", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .destructive, handler: {
                    action in
                    self.navigationController?.pop(animated: true)
                })
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
            else
            {
                let alertController = UIAlertController(title: "Error", message: "\(msg)\n\nPlease try again.", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        if disconnectBluetooth {
            
            print("Disconnecting Bluetooth")
            if centralPeripheral != nil {
                centralManager.cancelPeripheralConnection(centralPeripheral)
            }
            if remotePeripheral != nil {
                centralManager.cancelPeripheralConnection(remotePeripheral)
            }
            centralManager.stopScan()
        }
        disconnectBluetooth = true
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == SUREFI_CMD_WRITE_UUID {
            
            print("Command Send")
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if centralCmdReadCharacteristic != nil && characteristic == centralCmdReadCharacteristic {
            
            let value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            print("BLE Read:\(value)")
            
            let response = value.substring(to: 2)
            let data = value.substring(from: 2)
            
            switch (response) {
            case "01": //Application Firmware Version
                
                print("Application Firmware Data: \(data)")
                centralApplicationFirmware = data
                getCentralRadioFirmwareData()
                self.tableView.reloadData()
                
            case "09": //Radio Firmware Version
                
                print("Radio Firmware Data: \(data)")
                centralRadioFirmware = data
                getCentralRadioSettingsData()
                self.tableView.reloadData()
                
            case "08":
                
                centralRadioSettings = data
                self.tableView.reloadData()
                
            default:
                break
                
            }
        }
        if remoteCmdReadCharacteristic != nil && characteristic == remoteCmdReadCharacteristic {
            
            let value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            print("BLE Read:\(value)")
            
            let response = value.substring(to: 2)
            let data = value.substring(from: 2)
            
            switch (response) {
            case "01": //Application Firmware Version
                
                print("Application Firmware Data: \(data)")
                remoteApplicationFirmware = data
                getRemoteRadioFirmwareData()
                self.tableView.reloadData()
                
            case "09": //Radio Firmware Version
                
                print("Radio Firmware Data: \(data)")
                remoteRadioFirmware = data
                getRemoteRadioSettingsData()
                self.tableView.reloadData()
                
            case "08":
                
                remoteRadioSettings = data
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
