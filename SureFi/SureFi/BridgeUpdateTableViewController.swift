//
//  BridgeUpdateTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 7/3/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth
import iOSDFULibrary

class BridgeUpdateTableViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate, LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var deviceIDTextField: UITextField!
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var progressLabel: UILabel!
    
    var selectedFirmwareType = -1
    var deviceID = ""
    var deviceType = 0
    var timerAction = ""
    
    var connected: Bool = false
    var readyToFlash: Bool = false
    var isUpdatingFirmware: Bool = false
    var currentProgress: Int = 0
    var currentState: String = ""
    
    var selectedFirmwareFile: Int = -1
    
    var centralApplicationFiles: NSMutableArray = NSMutableArray()
    var centralRadioFiles: NSMutableArray = NSMutableArray()
    var centralBluetoothFiles: NSMutableArray = NSMutableArray()
    var remoteApplicationFiles: NSMutableArray = NSMutableArray()
    var remoteRadioFiles: NSMutableArray = NSMutableArray()
    var remoteBluetoothFiles: NSMutableArray = NSMutableArray()
    
    var firmwareFiles: NSMutableArray = NSMutableArray()
    
    var centralManager: CBCentralManager!
    var peripherals: Array<CBPeripheral> = Array<CBPeripheral>()
    var devicePeripheral: CBPeripheral!
    var surefiDevices: Array<CBPeripheral> = Array<CBPeripheral>()
    var surefiAdvertising: [String:String] = [:]
    
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
    
    var appFirmwareDataString: String = ""
    var radioFirmwareDataString: String = ""
    var btFirmwareDataString: String = ""
    var bootloaderDataString: String = ""
    
    let SUREFI_SERVICE_UUID = CBUUID(string: "98BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_RX_UID_UUID  = CBUUID(string: "98BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_TX_UID_UUID  = CBUUID(string: "98BF000C-0EC5-2536-2143-2D155783CE78")
    let SUREFI_STATUS_UUID  = CBUUID(string: "98BF000D-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_SEC_SERVICE_UUID  = CBUUID(string: "58BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_SEC_HASH_UUID     = CBUUID(string: "58BF000B-0EC5-2536-2143-2D155783CE78")
    
    let SUREFI_CMD_SERVICE_UUID   = CBUUID(string:"C8BF000A-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_WRITE_UUID     = CBUUID(string:"C8BF000B-0EC5-2536-2143-2D155783CE78")
    let SUREFI_CMD_READ_UUID      = CBUUID(string:"C8BF000C-0EC5-2536-2143-2D155783CE78")
    
    let BT_UPDATE_SERVICE_UUID      = CBUUID(string:"FE59")
    
    var timer: Timer!
    var btTimer: Timer!
    
    let pageSize: Int = 2048
    let packageSize: Int = 19
    var pageCount: Int = -1
    var currentPage: Int = -1
    var currentPackage: Int = -1
    
    var totalPackages = -1
    var currentPackageCount = 0
    
    var fileData: Data = Data()
    
    var processingBusy = false
    
    var startTime:Double = 0
    
    var peripheralReady = false
    var rowReady = false
    var rowDone = false
    var rowStarted = false
    var firmwareFinished = false
    var imageNumberLoaded = false
    var lowerImageOK = false
    var upperImageOK = false
    var writeImageNumber: String = ""
    
    var getMessageSent = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getCentralApplicationFirmware()
        getCentralRadioFirmware()
        getCentralBluetoothFirmware()
        getRemoteApplicationFirmware()
        getRemoteRadioFirmware()
        getRemoteBluetoothFirmware()
        
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
                print("Connecting to \(deviceID) \(Date().unixTimestamp!)")
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            return 64
        }
        if indexPath.section == 0 && indexPath.row == 1 {
            return 168
        }
        return 44
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            if connected {
                return 2
            }
            return 1
        }
        
        if section == 1 && isUpdatingFirmware {
            return 1
        }
        
        if section == 2 && selectedFirmwareType >= 0 {
            if isUpdatingFirmware {
                return 1
            }
            return firmwareFiles.count
        }
        
        if section == 3 {
            return surefiDevices.count
        }
        
        return 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeviceHeaderView", for: indexPath)
                let titleLabel = cell.viewWithTag(100) as! UILabel
                connectButton = cell.viewWithTag(200) as! UIButton
                
                if deviceID == "" {
                    titleLabel.text = "Scan Sure-Fi Device"
                    
                    connectButton.isHidden = true
                } else {
                    titleLabel.text = deviceID
                    
                    connectButton.layer.cornerRadius = 5
                    connectButton.clipsToBounds = true
                    connectButton.addTarget(self, action: #selector(connectButtonPress(sender:)), for: .touchUpInside)
                    
                    connectButton.isHidden = false
                    connectButton.isEnabled = true
                }
                
                if devicePeripheral != nil && devicePeripheral.state == .connected {
                    connectButton.setTitle("Connected", for: .normal)
                    connectButton.backgroundColor = UIColor(rgb: 0x009900)
                } else if devicePeripheral != nil && devicePeripheral.state == .connecting {
                    connectButton.setTitle("Connecting...", for: .normal)
                    connectButton.backgroundColor = .orange
                    connectButton.isEnabled = false
                } else {
                    connectButton.setTitle("Disconnected", for: .normal)
                    connectButton.backgroundColor = UIColor(rgb: 0x990000)
                }
                
                
                
                cell.accessoryType = .disclosureIndicator
            }
            if indexPath.row == 1 {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeviceDetailCell", for: indexPath)
                let bootloaderLabel = cell.viewWithTag(100) as! UILabel
                let appFirmwareDataLabel = cell.viewWithTag(200) as! UILabel
                let radioFirmwareDataLabel = cell.viewWithTag(300) as! UILabel
                let btFirmwareDataLabel = cell.viewWithTag(400) as! UILabel
                let selectSegmentedControl = cell.viewWithTag(500) as! UISegmentedControl
                
                bootloaderLabel.text = bootloaderDataString
                appFirmwareDataLabel.text = appFirmwareDataString
                radioFirmwareDataLabel.text = radioFirmwareDataString
                btFirmwareDataLabel.text = btFirmwareDataString
                
                selectSegmentedControl.addTarget(self, action: #selector(selectSegmentedControlChanged(sender:)), for: .valueChanged)
                selectSegmentedControl.backgroundColor = .white
                selectSegmentedControl.clipsToBounds = true
                selectSegmentedControl.layer.cornerRadius = 4
                if selectedFirmwareType >= 0 {
                    selectSegmentedControl.selectedSegmentIndex = selectedFirmwareType
                } else {
                    selectSegmentedControl.selectedSegmentIndex = -1
                }
                
            }
        }
        if indexPath.section == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "ProgressCell", for: indexPath)
            
            progressBar = cell.viewWithTag(100) as! UIProgressView
            progressLabel = cell.viewWithTag(200) as! UILabel
        }
        if indexPath.section == 2 {
            
            var firmwareData = firmwareFiles.object(at: indexPath.row) as? NSMutableDictionary ?? NSMutableDictionary()
            if isUpdatingFirmware {
                firmwareData = firmwareFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
            }
            
            cell = tableView.dequeueReusableCell(withIdentifier: "FirmwareFileCell", for: indexPath)
            
            let statusLabel = cell.viewWithTag(100) as! UILabel
            let titleLabel = cell.viewWithTag(200) as! UILabel
            let subtitleLabel = cell.viewWithTag(300) as! UILabel
            let flashButton = cell.viewWithTag(400) as! UIButton
            
            if isUpdatingFirmware {
                cell.backgroundColor = UIColor(rgb: 0x21ABDC)
                flashButton.backgroundColor = UIColor.orange
                flashButton.isEnabled = false
                flashButton.isHidden = false
            }
            else if indexPath.row == selectedFirmwareFile {
                cell.backgroundColor = UIColor(rgb: 0x21ABDC)
                flashButton.backgroundColor = UIColor(rgb: 0x990000)
                flashButton.isEnabled = true
                flashButton.isHidden = false
                flashButton.addTarget(self, action: #selector(flashButtonPress(sender:)), for: .touchUpInside)
            } else {
                cell.backgroundColor = UIColor.white
                flashButton.backgroundColor = UIColor(rgb: 0x990000)
                flashButton.isHidden = true
            }
            
            titleLabel.text = "\(firmwareData.object(forKey: "firmware_title") as? String ?? "") \(firmwareData.object(forKey: "firmware_version") as? String ?? "")"
            var firmwareStatus: Int = Int(firmwareData.object(forKey: "firmware_status") as? String ?? "-1")!
            if firmwareStatus == -1 {
                firmwareStatus = firmwareData.object(forKey: "firmware_status") as? Int ?? -1
            }
            switch (firmwareStatus) {
            case 1:
                statusLabel.text = "Development"
                statusLabel.backgroundColor = UIColor(rgb: 0x000099)
            case 2:
                statusLabel.text = "Release"
                statusLabel.backgroundColor = UIColor(rgb: 0x009900)
            case 3:
                statusLabel.text = "Beta"
                statusLabel.backgroundColor = UIColor.orange
            case 4:
                statusLabel.text = "Depricated"
                statusLabel.backgroundColor = UIColor(rgb: 0x990000)
            default:
                statusLabel.text = "Unknown Status"
                statusLabel.backgroundColor = UIColor.purple
            }
            statusLabel.textColor = .white
            
            //flashButton.clipsToBounds = true
            //flashButton.layer.cornerRadius = 3
            
            subtitleLabel.text = firmwareData.object(forKey: "firmware_description") as? String ?? ""
        }
        if indexPath.section == 3 {
            
            let deviceData = surefiDevices[indexPath.row]
            let uuid = deviceData.identifier.uuidString
            
            cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
            cell.textLabel?.text = deviceData.name ?? ""
            cell.detailTextLabel?.text = surefiAdvertising[uuid] ?? ""
        }
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "BridgeUpdateSelectViewController") as! BridgeUpdateSelectViewController
            controller.bridgeUpdateTableViewController = self
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        if indexPath.section == 2 {
            
            if selectedFirmwareFile == indexPath.row {
                selectedFirmwareFile = -1
            } else {
                selectedFirmwareFile = indexPath.row
            }
            self.tableView.reloadData()
        }
        
    }
    
    @IBAction func connectButtonPress(sender: UIButton) {
        
        print("Looking for \(deviceID)")
        if !connected {
            devicePeripheral = nil
            for peripheral in surefiDevices {
                
                let uuid = peripheral.identifier.uuidString
                var peripheralDeviceID = surefiAdvertising[uuid] ?? ""
                var deviceStatusString = ""
                
                if peripheralDeviceID.substring(to: 4).uppercased() == "FFFF" {
                    deviceStatusString = peripheralDeviceID.substring(from: 4).substring(to: 8)
                    peripheralDeviceID = peripheralDeviceID.substring(from: 12).substring(to: 6)
                } else {
                    deviceStatusString = peripheralDeviceID.substring(from: 0).substring(to: 8)
                    peripheralDeviceID = peripheralDeviceID.substring(from: 8).substring(to: 6)
                }
                
                print("Device List \(peripheralDeviceID)")
                
                if peripheralDeviceID.uppercased() == deviceID.uppercased() {
                    
                    print("Device Selected")
                    
                    let deviceTypeString = deviceStatusString.substring(to: 2) ?? "0"
                    deviceType = Int(deviceTypeString) ?? 0
                    devicePeripheral = peripheral
                    devicePeripheral.delegate = self
                    centralManager.connect(devicePeripheral, options: nil)
                    
                    connectButton.backgroundColor = .orange
                    connectButton.setTitle("Connecting...", for: .normal)
                    connectButton.isEnabled = false
                }
            }
            if devicePeripheral == nil {
                let alert: UIAlertController = UIAlertController(title: "Bluetooth Error", message: "Unable to find Device \(deviceID.uppercased())", preferredStyle: UIAlertControllerStyle.alert);
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                self.present(alert,animated: true, completion: nil);
            }
            
        } else {
            connected = false
            selectedFirmwareType = -1
            centralManager.cancelPeripheralConnection(devicePeripheral)
            devicePeripheral = nil
            firmwareFiles.removeAllObjects()
            isUpdatingFirmware = false
            tableView.reloadData()
        }
    }
    
    func connectDevicePeripheral() {
        
        if deviceID != "" {
            
            for index in 0...(surefiDevices.count-1) {
                
                let peripheral = surefiDevices[index]
                let uuid = peripheral.identifier.uuidString
                let manufacturerString = surefiAdvertising[uuid] ?? ""
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
                    deviceManufacturerDataString = manufacturerString
                    devicePeripheral = peripheral
                    devicePeripheral.delegate = self
                    centralManager.connect(devicePeripheral, options: nil)
                }
            }
            tableView.reloadData()
            
        }
    }
    
    @IBAction func selectSegmentedControlChanged(sender: UISegmentedControl) {
        selectedFirmwareType = sender.selectedSegmentIndex
        print("SelectedType:\(selectedFirmwareType)")
        
        if selectedFirmwareType >= 0 {
            
            if deviceType == 1 { //Central
                
                if selectedFirmwareType == 0 { //App
                    firmwareFiles = centralApplicationFiles
                }
                if selectedFirmwareType == 1 { //Radio
                    firmwareFiles = centralRadioFiles
                }
                if selectedFirmwareType == 2 { //Bluetooth
                    firmwareFiles = centralBluetoothFiles
                }
            }
            if deviceType == 2 { //Remote
                
                if selectedFirmwareType == 0 { //App
                    firmwareFiles = remoteApplicationFiles
                }
                if selectedFirmwareType == 1 { //Radio
                    firmwareFiles = remoteRadioFiles
                }
                if selectedFirmwareType == 2 { //Bluetooth
                    firmwareFiles = remoteBluetoothFiles
                }
            }
            
        } else {
            firmwareFiles = NSMutableArray()
        }
        tableView.reloadData()
    }
    
    @IBAction func flashButtonPress(sender: UIButton) {
        
        //sender.setTitle("Flashing...", for: .normal)
        sender.backgroundColor = UIColor.orange
        sender.isEnabled = false
        
        readyToFlash = false
        if selectedFirmwareFile >= 0 {
            if deviceType == 1 { //Central
                if selectedFirmwareType == 0 { //App
                    print("Flash Central Application")
                    startCentralApplicationUpdate()
                }
                if selectedFirmwareType == 1 { //Radio
                    print("Flash Central Radio")
                    startCentralRadioUpdate()
                }
                if selectedFirmwareType == 2 { //Bluetooth
                    print("Flash Central Bluetooth")
                    startCentralBluetoothUpdate()
                }
            }
            if deviceType == 2 { //Remote
                if selectedFirmwareType == 0 { //App
                    print("Flash Remote Application")
                    startRemoteApplicationUpdate()
                }
                if selectedFirmwareType == 1 { //Radio
                    print("Flash Remote Radio")
                    startRemoteRadioUpdate()
                }
                if selectedFirmwareType == 2 { //Bluetooth
                    print("Flash Remote Bluetooth")
                    startRemoteBluetoothUpdate()
                }
            }
        }
    }
    
    func startCentralApplicationUpdate() {
        
        timerAction = "flash_application"
        
        let firmwareData = centralApplicationFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
        print(firmwareData)
        
        let firmwareURL = URL(string: firmwareData.object(forKey: "firmware_path") as? String ?? "")!
        do {
            fileData = try Data.init(contentsOf: firmwareURL)
        } catch {
            print(error)
        }
        if fileData.count > 0 {
            pageCount = Int(ceil(Float(fileData.count) / Float(pageSize)))
            
            let byte1 = fileData[2]
            print("Byte1:\(byte1)")
            let byte2 = fileData[3]
            print("Byte2:\(byte2)")
            
            let tempBytes = writeImageNumber.dataFromHexString()! as Data
            print("TempBytes:\(tempBytes)")
            print("TempBytes1:\(tempBytes[0])")
            print("TempBytes2:\(tempBytes[1])")
            fileData.replaceSubrange(Range(2...2), with: [tempBytes[1]])
            fileData.replaceSubrange(Range(3...3), with: [tempBytes[0]])
            
            fileData[2] = tempBytes[1]
            fileData[3] = tempBytes[0]
            
            self.btTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(bluetoothTimerTick(sender:)), userInfo: nil, repeats: true)
        } else {
            print("Error Downloading File")
        }
    }
    
    func startRemoteApplicationUpdate() {
        
        timerAction = "flash_application"
        
        let firmwareData = remoteApplicationFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
        print(firmwareData)
        
        let firmwareURL = URL(string: firmwareData.object(forKey: "firmware_path") as? String ?? "")!
        do {
            fileData = try Data.init(contentsOf: firmwareURL)
        } catch {
            print(error)
        }
        if fileData.count > 0 {
            pageCount = Int(ceil(Float(fileData.count) / Float(pageSize)))
            
            let byte1 = fileData[2]
            print("Byte1:\(byte1)")
            let byte2 = fileData[3]
            print("Byte2:\(byte2)")
            
            let tempBytes = writeImageNumber.dataFromHexString()! as Data
            print("TempBytes:\(tempBytes)")
            print("TempBytes1:\(tempBytes[0])")
            print("TempBytes2:\(tempBytes[1])")
            fileData.replaceSubrange(Range(2...2), with: [tempBytes[1]])
            fileData.replaceSubrange(Range(3...3), with: [tempBytes[0]])
            
            fileData[2] = tempBytes[1]
            fileData[3] = tempBytes[0]
            
            self.btTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(bluetoothTimerTick(sender:)), userInfo: nil, repeats: true)
        } else {
            print("Error Downloading File")
        }
    }
    
    func startCentralRadioUpdate() {
        
        timerAction = "flash_radio"
        
        let firmwareData = centralRadioFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
        print(firmwareData)
        
        let firmwareURL = URL(string: firmwareData.object(forKey: "firmware_path") as? String ?? "")!
        do {
            fileData = try Data.init(contentsOf: firmwareURL)
        } catch {
            print(error)
        }
        if fileData.count > 0 {
            pageCount = Int(ceil(Float(fileData.count) / Float(pageSize)))
            self.btTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(bluetoothTimerTick(sender:)), userInfo: nil, repeats: true)
        } else {
            print("Error Downloading File")
        }
    }
    
    func startRemoteRadioUpdate() {
        
        timerAction = "flash_radio"
        
        let firmwareData = remoteRadioFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
        print(firmwareData)
        
        let firmwareURL = URL(string: firmwareData.object(forKey: "firmware_path") as? String ?? "")!
        do {
            fileData = try Data.init(contentsOf: firmwareURL)
        } catch {
            print(error)
        }
        if fileData.count > 0 {
            pageCount = Int(ceil(Float(fileData.count) / Float(pageSize)))
            self.btTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(bluetoothTimerTick(sender:)), userInfo: nil, repeats: true)
        } else {
            print("Error Downloading File")
        }
    }
    
    func startCentralBluetoothUpdate() {
        
        timerAction = "flash_bluetooth"
        let messageBytes: Data = Data([0x1A])
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        self.btTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(bluetoothTimerTick(sender:)), userInfo: nil, repeats: true)
        tableView.reloadData()
    }
    
    func startRemoteBluetoothUpdate() {
        
        timerAction = "flash_bluetooth"
        let messageBytes: Data = Data([0x1A])
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        self.btTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(bluetoothTimerTick(sender:)), userInfo: nil, repeats: true)
        tableView.reloadData()
    }
    
    func flashCentralBluetoothFirmware() {
        
        readyToFlash = false
        
        let firmwareData = centralBluetoothFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
        print(firmwareData)
        
        let firmwareURL = URL(string: firmwareData.object(forKey: "firmware_path") as? String ?? "")!
        print("Downloading Firmware File:\(firmwareURL.absoluteString)")
        var firmwareZipFile: Data = Data()
        do {
            firmwareZipFile = try Data.init(contentsOf: firmwareURL)
        } catch {
            print(error)
        }
        
        if firmwareZipFile.count > 0 {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath = documentsPath.appending("/").appending(firmwareData.object(forKey: "firmware_filename") as? String ?? "")
            do {
                try firmwareZipFile.write(to: URL(fileURLWithPath: filePath))
            } catch {
                print(error)
            }
            
            
            let selectedFirmware = DFUFirmware(urlToZipFile:URL(fileURLWithPath: filePath))!
            
            let initiator = DFUServiceInitiator(centralManager: centralManager, target: devicePeripheral).with(firmware: selectedFirmware)
            initiator.logger = self
            initiator.delegate = self
            initiator.progressDelegate = self
            let controller = initiator.start()
            isUpdatingFirmware = true
            tableView.reloadData()
        } else {
            print("Error Downloading File")
        }
    }
    
    func flashRemoteBluetoothFirmware() {
        
        readyToFlash = false
        
        let firmwareData = remoteBluetoothFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
        print(firmwareData)
        
        let firmwareURL = URL(string: firmwareData.object(forKey: "firmware_path") as? String ?? "")!
        print("Downloading Firmware File:\(firmwareURL.absoluteString)")
        var firmwareZipFile: Data = Data()
        do {
            firmwareZipFile = try Data.init(contentsOf: firmwareURL)
        } catch {
            print(error)
        }
        
        if firmwareZipFile.count > 0 {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath = documentsPath.appending("/").appending(firmwareData.object(forKey: "firmware_filename") as? String ?? "")
            do {
                try firmwareZipFile.write(to: URL(fileURLWithPath: filePath))
            } catch {
                print(error)
            }
            
            
            let selectedFirmware = DFUFirmware(urlToZipFile:URL(fileURLWithPath: filePath))!
            
            let initiator = DFUServiceInitiator(centralManager: centralManager, target: devicePeripheral).with(firmware: selectedFirmware)
            initiator.logger = self
            initiator.delegate = self
            initiator.progressDelegate = self
            let controller = initiator.start()
            isUpdatingFirmware = true
            tableView.reloadData()
        } else {
            print("Error Downloading File")
        }
    }
    
    @IBAction func bluetoothTimerTick(sender: Timer) {
        
        //print("Timer Tick")
        if timerAction == "flash_application" || timerAction == "flash_radio" {
            
            if !processingBusy {
                
                if peripheralReady == false {
                    
                    isUpdatingFirmware = true
                    processingBusy = true
                    var messageBytes: Data = Data()
                    if selectedFirmwareType == 0 { // Application
                        messageBytes.append(0x03)
                    } else if selectedFirmwareType == 1 { // Radio
                        messageBytes.append(0x0D)
                    }
                    print("BLE Cmd:\(messageBytes.hexStringFromData())")
                    devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
                } else {
                    
                    if currentPackage == -1 {
                        
                        if currentPage >= 0 && rowDone == true {
                            
                            processingBusy = true
                            var messageBytes: Data = Data()
                            if selectedFirmwareType == 0 { // Application
                                messageBytes.append(0x06)
                            } else if selectedFirmwareType == 1 { // Radio
                                messageBytes.append(0x10)
                            }
                            print("BLE Cmd:\(messageBytes.hexStringFromData())")
                            devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
                            return
                        }
                        currentPackage = 0
                        currentPage += 1
                        return
                    }
                    
                    if currentPage >= pageCount {
                        
                        var messageBytes: Data = Data()
                        if selectedFirmwareType == 0 { // Application
                            messageBytes.append(0x07)
                        } else if selectedFirmwareType == 1 { // Radio
                            messageBytes.append(0x11)
                        }
                        print("BLE Cmd:\(messageBytes.hexStringFromData())")
                        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
                        btTimer.invalidate()
                        
                    } else {
                        
                        //if currentPackageCount % 32 == 0 {
                        DispatchQueue.main.async {
                            self.currentProgress = Int((Float(self.currentPackageCount) / Float(self.totalPackages)) * 100)
                            
                            if self.progressLabel != nil {
                                self.progressLabel.text = "Uploading - \(self.currentProgress)%"
                            }
                            if self.progressBar != nil {
                                self.progressBar.progress = Float(self.currentProgress) / 100
                            }
                            self.tableView.reloadData()
                        }
                        //}
                        processingBusy = true
                        let pageByteStart = currentPage * pageSize
                        var pageByteEnd = pageByteStart + pageSize
                        if pageByteEnd >= fileData.count {
                            pageByteEnd = fileData.count
                        }
                        let pageBytes = fileData.subdata(in: pageByteStart..<pageByteEnd)
                        
                        if !rowStarted {
                            
                            //let pageCRC: UInt32 = crc32(0, data: pageBytes)
                            var messageBytes: Data = Data()
                            if selectedFirmwareType == 0 { // Application
                                messageBytes.append(0x04)
                            } else if selectedFirmwareType == 1 { // Radio
                                messageBytes.append(0x0E)
                            }
                            
                            let crc = pageBytes.crc16()
                            
                            let pageIndexBytes = String(format:"%X", currentPage.littleEndian).leftPadding(toLength: 4, withPad: "0").dataFromHexString() as Data? ?? Data()
                            let crcBytes = String(format:"%X", crc).leftPadding(toLength: 4, withPad: "0").dataFromHexString() as Data? ?? Data()
                            let pageSizeBytes = String(format: "%X", pageBytes.count.littleEndian).leftPadding(toLength: 4, withPad: "0").dataFromHexString() as Data? ?? Data()
                            messageBytes.append(pageIndexBytes)
                            messageBytes.append(crcBytes)
                            messageBytes.append(pageSizeBytes)
                            print("BLE Cmd:\(messageBytes.hexStringFromData())")
                            devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
                            rowReady = false
                            rowStarted = true
                            return
                        }
                        
                        if rowReady {
                            
                            let packageCount = Int(ceil(Float(pageBytes.count) / Float(packageSize)))
                            
                            if totalPackages == -1 {
                                totalPackages = packageCount * pageCount
                            }
                            
                            let pageProgress:Float = Float(currentPage+1) / Float(pageCount)
                            
                            if currentPackage >= 0 && currentPackage <= packageCount {
                                
                                let packageByteStart = currentPackage * packageSize
                                var packageByteEnd = packageByteStart + packageSize
                                if packageByteEnd >= pageBytes.count {
                                    packageByteEnd = pageBytes.count
                                }
                                var packageBytes: Data = Data()
                                if selectedFirmwareType == 0 { // Application
                                    packageBytes.append(0x05)
                                } else if selectedFirmwareType == 1 { // Radio
                                    packageBytes.append(0x0F)
                                }
                                
                                
                                packageBytes.append(pageBytes.subdata(in: packageByteStart..<packageByteEnd))
                                print("BLE Cmd:\(packageBytes.hexStringFromData())")
                                devicePeripheral.writeValue(packageBytes, for: deviceCmdWriteCharacteristic, type: .withoutResponse)
                                let packageProgress:Float = Float(currentPackage+1) / Float(packageCount)
                                currentPackageCount += 1
                                
                                DispatchQueue.main.async {
                                    self.currentPackage += 1
                                    if self.currentPackage >= packageCount {
                                        self.currentPackage = -1
                                        self.rowDone = true
                                    }
                                    self.processingBusy = false
                                }
                            }
                        }
                    }
                }
            }
        }
        if timerAction == "flash_bluetooth" {
            if devicePeripheral != nil && devicePeripheral.state == .connected {
                
                if readyToFlash && deviceType == 1 {
                    flashCentralBluetoothFirmware()
                }
                if readyToFlash && deviceType == 2 {
                    flashRemoteBluetoothFirmware()
                }
            }
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
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("Disconnected from Device... \(deviceID)")
        self.tableView.reloadData()
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        let name = peripheral.name;
        let uuid = peripheral.identifier.uuidString
        
        var peripheralDeviceID = ""
        var manufacturerString = ""
        
        if advertisementData["kCBAdvDataManufacturerData"] != nil && name != nil {
            let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as! Data
            manufacturerString = manufacturerData.hexStringFromData()
            peripheralDeviceID = manufacturerString
        }
        
        if name?.uppercased().range(of: "DFUT") != nil {
            
            print("DFUT Device Found \(name!) \(peripheralDeviceID)")
           if peripheralDeviceID.uppercased().range(of: deviceID.uppercased()) != nil {
                
                print("DFUT Device Found \(name!)")
                devicePeripheral = peripheral
                devicePeripheral.delegate = self
                centralManager.connect(devicePeripheral, options: nil)
            }
            
        }
        
        if name?.uppercased().range(of: "SURE-FI") != nil || name?.uppercased().range(of: "SF BRIDGE") != nil {
            
            let uuid = peripheral.identifier.uuidString
            
            var deviceStatusString = ""
            
            if peripheralDeviceID.substring(to: 4).uppercased() == "FFFF" {
                deviceStatusString = peripheralDeviceID.substring(from: 4).substring(to: 8)
                peripheralDeviceID = peripheralDeviceID.substring(from: 12).substring(to: 6)
            } else {
                deviceStatusString = peripheralDeviceID.substring(from: 0).substring(to: 8)
                peripheralDeviceID = peripheralDeviceID.substring(from: 8).substring(to: 6)
            }
            if !surefiDevices.contains(peripheral) {
                print("Device Found \(peripheralDeviceID)")
                peripheral.delegate = self
                surefiDevices.append(peripheral);
                surefiAdvertising[uuid] = manufacturerString
            }
            
            self.tableView.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if devicePeripheral != nil && peripheral == devicePeripheral {
            print("Device Connected...\(deviceID)")
            deviceCmdReadCharacteristic = nil
            deviceCmdWriteCharacteristic = nil
            deviceSecHashCharacteristic = nil
            devicePeripheral.discoverServices(nil)
            self.tableView.reloadData()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service as CBService
            
            if service.uuid == BT_UPDATE_SERVICE_UUID {
                readyToFlash = true
            }
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
            
            if deviceSecHashCharacteristic != nil && deviceCmdReadCharacteristic != nil && deviceCmdWriteCharacteristic != nil {
                connected = true
                tableView.reloadData()
                getDeviceData()
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
                
            case "01":
                let version = data.dataFromHexString()
                var major: Int = 0
                var minor: Int = 0
                version?.getBytes(&major, range: NSRange(location: 0, length: 1))
                version?.getBytes(&minor, range: NSRange(location: 1, length: 1))
                
                appFirmwareDataString = "v\(major).\(minor)"
                tableView.reloadData()
                getRadioFirmwareVersion()
                break
            case "09":
                let version = data.dataFromHexString()
                var major: Int = 0
                var minor: Int = 0
                version?.getBytes(&major, range: NSRange(location: 0, length: 1))
                version?.getBytes(&minor, range: NSRange(location: 1, length: 1))
                
                radioFirmwareDataString = "v\(major).\(minor)"
                tableView.reloadData()
                getBluetoothFirmwareVersion()
                break
            case "12":
                let version = data.dataFromHexString()
                var major: Int = 0
                var minor: Int = 0
                version?.getBytes(&major, range: NSRange(location: 0, length: 1))
                version?.getBytes(&minor, range: NSRange(location: 1, length: 1))
                
                btFirmwareDataString = "v\(major).\(minor)"
                tableView.reloadData()
                break
            case "02":
                processingBusy = false
                break
            case "03","0A": // Bluetooth Update Read
                processingBusy = false
                peripheralReady = true
                break
            case "04","0B":
                processingBusy = false
                rowReady = false
                rowStarted = false
                rowDone = false
            case "05","0C":
                processingBusy = false
                rowReady = true
                rowStarted = true
                rowDone = false
            case "06","0D":
                isUpdatingFirmware = false
                firmwareFinished = true
                DispatchQueue.main.async {
                    let alert: UIAlertController = UIAlertController(title: "Update Complete", message: "Firmware Update is Completed", preferredStyle: UIAlertControllerStyle.alert);
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                        action in
                        self.isUpdatingFirmware = false
                        self.connected = false
                        self.centralManager.cancelPeripheralConnection(self.devicePeripheral)
                        self.selectedFirmwareType = -1
                        self.selectedFirmwareFile = -1
                        self.devicePeripheral = nil
                        self.surefiDevices.removeAll()
                        self.surefiAdvertising.removeAll()
                        self.btTimer.invalidate()
                        self.firmwareFiles.removeAllObjects()
                        self.centralManager = CBCentralManager(delegate: self, queue: nil)
                        self.tableView.reloadData()
                    }));
                    self.present(alert,animated: true, completion: nil);
                }
            case "07":
                
                
                let lowerReadCrc            = data.substring(from:  0).substring(to: 4)
                let lowerCalculatedCrc      = data.substring(from:  4).substring(to: 4)
                let lowerVersionNumberMajor = data.substring(from:  8).substring(to: 2)
                let lowerVersionNumberMinor = data.substring(from: 10).substring(to: 2)
                var lowerProgramNumber      = data.substring(from: 12).substring(to: 4)
                let upperReadCrc            = data.substring(from: 16).substring(to: 4)
                let upperCalculatedCrc      = data.substring(from: 20).substring(to: 4)
                let upperVersionNumberMajor = data.substring(from: 24).substring(to: 2)
                let upperVersionNumberMinor = data.substring(from: 26).substring(to: 2)
                var upperProgramNumber      = data.substring(from: 28).substring(to: 4)
                let bootingUpperMemory      = data.substring(from: 32).substring(to: 2)
                
                bootloaderDataString = "Upper CRC:\(upperReadCrc)|\(upperCalculatedCrc) Version:\(upperVersionNumberMajor).\(upperVersionNumberMinor) Prgm:\(upperProgramNumber)\nLower CRC:\(lowerReadCrc)|\(lowerCalculatedCrc) Version:\(lowerVersionNumberMajor).\(lowerVersionNumberMinor) Prgm:\(lowerProgramNumber)"
                
                getAppFirmwareVersion()
                if lowerProgramNumber == "FFFF" {
                    lowerProgramNumber = "0000"
                }
                if upperProgramNumber == "FFFF" {
                    upperProgramNumber = "0000"
                }
                
                if lowerReadCrc == lowerCalculatedCrc {
                    lowerImageOK = true
                    lowerProgramNumber = self.incrementProgramNumber(programNumber: lowerProgramNumber)
                }
                if upperReadCrc == upperCalculatedCrc {
                    upperImageOK = true
                    upperProgramNumber = self.incrementProgramNumber(programNumber: upperProgramNumber)
                }
                
                if bootingUpperMemory == "00" {
                    writeImageNumber = lowerProgramNumber
                }
                else if  bootingUpperMemory == "01" {
                    writeImageNumber = upperProgramNumber
                }
                else {
                    DispatchQueue.main.async {
                        let alert: UIAlertController = UIAlertController(title: "CRC ERROR", message: "Error Updating Firmware. CRC Error on Bridge Device", preferredStyle: UIAlertControllerStyle.alert);
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                        self.present(alert,animated: true, completion: nil);
                    }
                    return
                }
                tableView.reloadData()
                break
            case "E3":
                break
            case "E4":
                currentPage -= 1
                rowReady = false
                rowStarted = false
                rowDone = false
            case "E5":
                currentPage -= 1
                rowReady = false
                rowStarted = false
                rowDone = false
            case "E6":
                DispatchQueue.main.async {
                    let alert: UIAlertController = UIAlertController(title: "CRC ERROR", message: "Error Updating Firmware. Page CRC Error", preferredStyle: UIAlertControllerStyle.alert);
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                        action in
                        self.isUpdatingFirmware = false
                        self.connected = false
                        self.centralManager.cancelPeripheralConnection(self.devicePeripheral)
                        self.selectedFirmwareType = -1
                        self.selectedFirmwareFile = -1
                        self.devicePeripheral = nil
                        self.surefiDevices.removeAll()
                        self.surefiAdvertising.removeAll()
                        self.firmwareFiles.removeAllObjects()
                        self.centralManager = CBCentralManager(delegate: self, queue: nil)
                        self.btTimer.invalidate()
                        self.tableView.reloadData()
                    }));
                    self.present(alert,animated: true, completion: nil);
                }
                break
            default:
                break
                
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
    
    func incrementProgramNumber(programNumber: String) -> String {
        let versionNumber = programNumber.hexaToDecimal + 1
        var versionString = versionNumber.toHexaString
        while versionString.length < 4 {
            versionString = "0\(versionString)"
        }
        return versionString
    }
    
    func getDeviceData() {
        
        let messageBytes: Data = Data([0x08])
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getAppFirmwareVersion() {
        
        let messageBytes: Data = Data([0x01])
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getRadioFirmwareVersion() {
        
        let messageBytes: Data = Data([0x02])
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getBluetoothFirmwareVersion() {
        
        let messageBytes: Data = Data([0x1B])
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func getCentralApplicationFirmware() {
        
        let postData = NSMutableDictionary()
        postData.setValue("eaa4c810-e477-489c-8ae8-c86387b1c62e", forKey: "hardware_type_key")
        postData.setValue("application", forKey: "firmware_type")
        SessionController().postServerRequest(action: "firmware/get_available_firmware", postData: postData, urlData:"", callback: self.getCentralApplicationFirmwareCallback)
    }
    
    func getCentralRadioFirmware() {
        
        let postData = NSMutableDictionary()
        postData.setValue("eaa4c810-e477-489c-8ae8-c86387b1c62e", forKey: "hardware_type_key")
        postData.setValue("radio", forKey: "firmware_type")
        SessionController().postServerRequest(action: "firmware/get_available_firmware", postData: postData, urlData:"", callback: getCentralRadioFirmwareCallback)
    }
    
    func getCentralBluetoothFirmware() {
        
        let postData = NSMutableDictionary()
        postData.setValue("eaa4c810-e477-489c-8ae8-c86387b1c62e", forKey: "hardware_type_key")
        postData.setValue("bluetooth", forKey: "firmware_type")
        SessionController().postServerRequest(action: "firmware/get_available_firmware", postData: postData, urlData:"", callback: getCentralBluetoothFirmwareCallback)
    }
    
    func getRemoteApplicationFirmware() {
        
        let postData = NSMutableDictionary()
        postData.setValue("0ef2c2a6-ef1f-43e3-be3a-e69628f5c7bf", forKey: "hardware_type_key")
        postData.setValue("application", forKey: "firmware_type")
        SessionController().postServerRequest(action: "firmware/get_available_firmware", postData: postData, urlData:"", callback: self.getRemoteApplicationFirmwareCallback)
    }
    
    func getRemoteRadioFirmware() {
        
        let postData = NSMutableDictionary()
        postData.setValue("0ef2c2a6-ef1f-43e3-be3a-e69628f5c7bf", forKey: "hardware_type_key")
        postData.setValue("radio", forKey: "firmware_type")
        SessionController().postServerRequest(action: "firmware/get_available_firmware", postData: postData, urlData:"", callback: self.getRemoteRadioFirmwareCallback)
    }
    
    func getRemoteBluetoothFirmware() {
        
        let postData = NSMutableDictionary()
        postData.setValue("0ef2c2a6-ef1f-43e3-be3a-e69628f5c7bf", forKey: "hardware_type_key")
        postData.setValue("bluetooth", forKey: "firmware_type")
        SessionController().postServerRequest(action: "firmware/get_available_firmware", postData: postData, urlData:"", callback: self.getRemoteBluetoothFirmwareCallback)
    }
    
    func getCentralApplicationFirmwareCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                self.centralApplicationFiles = data["files"] as? NSMutableArray ?? NSMutableArray()
                print("Found \(self.centralApplicationFiles.count) Central App Files")
                self.tableView.reloadData()
            } else {
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func getCentralRadioFirmwareCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                self.centralRadioFiles = data["files"] as? NSMutableArray ?? NSMutableArray()
                print("Found \(self.centralRadioFiles.count) Central Radio Files")
                self.tableView.reloadData()
            } else {
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func getCentralBluetoothFirmwareCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                self.centralBluetoothFiles = data["files"] as? NSMutableArray ?? NSMutableArray()
                print("Found \(self.centralBluetoothFiles.count) Central Bluetooth Files")
                self.tableView.reloadData()
            } else {
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func getRemoteApplicationFirmwareCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                self.remoteApplicationFiles = data["files"] as? NSMutableArray ?? NSMutableArray()
                print("Found \(self.remoteApplicationFiles.count) Remote App Files")
                self.tableView.reloadData()
            } else {
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func getRemoteRadioFirmwareCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                self.remoteRadioFiles = data["files"] as? NSMutableArray ?? NSMutableArray()
                print("Found \(self.remoteRadioFiles.count) Remote Radio Files")
                self.tableView.reloadData()
            } else {
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func getRemoteBluetoothFirmwareCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                self.remoteBluetoothFiles = data["files"] as? NSMutableArray ?? NSMutableArray()
                print("Found \(self.remoteBluetoothFiles.count) Remote Bluetooth Files")
                self.tableView.reloadData()
            } else {
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        
        currentProgress = progress
        if progressLabel != nil {
            progressLabel.text = "\(currentState) - \(currentProgress)%"
        }
        if progressBar != nil {
            progressBar.progress = Float(currentProgress) / 100
        }
    }
    
    func dfuStateDidChange(to state: DFUState) {
        
        print("DFU State Changed:\(state.description())")
        currentState = state.description()
        if progressLabel != nil {
            progressLabel.text = "\(currentState) - \(currentProgress)%"
        }
        if progressBar != nil {
            progressBar.progress = Float(currentProgress) / 100
        }
        
        if state == .completed {
            let alertController = UIAlertController(title: "Update Completed", message: "Bluetooth Module Firmware Updated", preferredStyle: .alert)
            let continueAction = UIAlertAction(title: "Continue", style: .default, handler: {
                action in
                self.btTimer.invalidate()
                self.isUpdatingFirmware = false
                self.connected = false
                self.selectedFirmwareType = -1
                self.selectedFirmwareFile = -1
                self.devicePeripheral = nil
                self.surefiDevices.removeAll()
                self.surefiAdvertising.removeAll()
                self.centralManager = CBCentralManager(delegate: self, queue: nil)
                self.tableView.reloadData()
            })
            alertController.addAction(continueAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        print("DFU Error:\(message)")
    }
    
    func logWith(_ level: LogLevel, message: String) {
        print("DFU Log:\(message)")
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
