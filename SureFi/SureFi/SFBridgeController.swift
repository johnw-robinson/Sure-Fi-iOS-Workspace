//
//  SFBridgeController.swift
//  SureFi
//
//  Created by John Robinson on 7/7/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import Foundation
import CoreBluetooth
import iOSDFULibrary

class SFBridgeController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    private var centralManager: CBCentralManager!
    private var peripherals: Array<CBPeripheral> = Array<CBPeripheral>()
    var devicePeripheral: CBPeripheral!
    var surefiDevices: Array<CBPeripheral> = Array<CBPeripheral>()
    var surefiMfgStrings: [String:String] = [:]
    var surefiDeviceTimers: [String:Int] = [:]
    var selectedDeviceStatus: String = ""
    var selectedDeviceID: String = ""
    var selectedDeviceType: Int = -1
    var selectedFirmwareType: Int = -1
    var selectedDeviceTxUUID: String = ""
    var selectedDeviceRxUUID: String = ""
    var selectedDeviceVoltageBat: Double = 0
    var selectedDeviceVoltagePwr: Double = 0
    var selectedDevicePower: String = ""
    var selectedDeviceBandwidth: String = ""
    var selectedDeviceSF: String = ""
    
    var currentCommand: String = ""
    
    var deviceManufacturerDataString: String!
    
    private var deviceTxCharacteristic: CBCharacteristic!
    private var deviceRxCharacteristic: CBCharacteristic!
    private var deviceStatusCharacteristic: CBCharacteristic!
    private var deviceSecHashCharacteristic: CBCharacteristic!
    
    private var deviceCmdWriteCharacteristic: CBCharacteristic!
    private var deviceCmdReadCharacteristic: CBCharacteristic!
    
    var connected: Bool = false
    
    private let SUREFI_SERVICE_UUID = CBUUID(string: "98BF000A-0EC5-2536-2143-2D155783CE78")
    private let SUREFI_RX_UID_UUID  = CBUUID(string: "98BF000B-0EC5-2536-2143-2D155783CE78")
    private let SUREFI_TX_UID_UUID  = CBUUID(string: "98BF000C-0EC5-2536-2143-2D155783CE78")
    private let SUREFI_STATUS_UUID  = CBUUID(string: "98BF000D-0EC5-2536-2143-2D155783CE78")
    
    private let SUREFI_SEC_SERVICE_UUID  = CBUUID(string: "58BF000A-0EC5-2536-2143-2D155783CE78")
    private let SUREFI_SEC_HASH_UUID     = CBUUID(string: "58BF000B-0EC5-2536-2143-2D155783CE78")
    
    private let SUREFI_CMD_SERVICE_UUID   = CBUUID(string:"C8BF000A-0EC5-2536-2143-2D155783CE78")
    private let SUREFI_CMD_WRITE_UUID     = CBUUID(string:"C8BF000B-0EC5-2536-2143-2D155783CE78")
    private let SUREFI_CMD_READ_UUID      = CBUUID(string:"C8BF000C-0EC5-2536-2143-2D155783CE78")
    
    private let BT_UPDATE_SERVICE_UUID      = CBUUID(string:"FE59")
    
    var appFirmwareDataString: String = ""
    var radioFirmwareDataString: String = ""
    var btFirmwareDataString: String = ""
    var bootloaderDataString: String = ""
    var radioSettingsDataString: String = ""
    
    var isUpdatingFirmware = false
    var imageNumberLoaded = false
    var lowerImageOK = false
    var upperImageOK = false
    var writeImageNumber: String = ""
    var timerAction: String = ""

    var peripheralReady = false
    var rowReady = false
    var rowDone = false
    var rowStarted = false
    var firmwareFinished = false
    let pageSize: Int = 2048
    let packageSize: Int = 19
    var pageCount: Int = -1
    var currentPage: Int = -1
    var currentPackage: Int = -1
    var readyToFlash: Bool = false
    var processingBusy = false
    var currentProgress: Int = -1
    var currentProgressMessage: String = ""
    var totalPackages = -1
    var currentPackageCount = 0
    var currentState: String = ""
    
    var fileData: Data = Data()
    var filePathString: String = ""
    
    var btTimer: Timer!
    
    let powerArray: [String] = ["1/8 Watt","1/4 Watt","1/2 Watt","1 Watt"]
    let spreadingFactorArray: [Int] = [7,8,9,10,11,12]
    let bandwidthArray: [Float] = [31.25,62.50,125,250,500]
    let heartbeatArray: [Int] = [0,15,30,60,90,120]
    let retryArray: [Int] = [0,1,2,3,4,5]
    let acksArray: [String] = ["Disabled","Enabled"]

    static let shared = SFBridgeController()
    
    private override init() {
        
        super.init()
        print("SFBridgeController - Init")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        print("SFBridgeController - Manager Updated to State \(central.state.rawValue)")
        if (central.state == CBManagerState.poweredOn)
        {
            centralManager!.scanForPeripherals(withServices: nil, options: nil)
        }
        else
        {
            let alert: UIAlertController = UIAlertController(title: "Bluetooth Error", message: "Bluetooth is not turned on.", preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            alert.show()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("SFBridgeController - Connected Device... \(peripheral.name!)")
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("SFBridgeController - Disconnected from Device... \(peripheral.name)")
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
        
        if name?.uppercased().range(of: "SURE-FI") != nil || name?.uppercased().range(of: "SF BRIDGE") != nil {
            
            let uuid = peripheral.identifier.uuidString
            
            var deviceStatusString = ""
            
            if peripheralDeviceID.substring(to: 4).uppercased() == "FFFF" {
                deviceStatusString = peripheralDeviceID.substring(from: 4).substring(to: 8)
                peripheralDeviceID = peripheralDeviceID.substring(from: 12).substring(to: 6)
            } else {
                deviceStatusString = peripheralDeviceID.substring(from: 0).substring(to: 4)
                peripheralDeviceID = peripheralDeviceID.substring(from: 8).substring(to: 6)
            }
            if !surefiDevices.contains(peripheral) {
                print("SFBridgeController - Device Found \(peripheralDeviceID)")
                peripheral.delegate = self
                surefiDevices.append(peripheral);
                surefiMfgStrings[uuid] = manufacturerString
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service as CBService
            
            if service.uuid == SUREFI_SERVICE_UUID || service.uuid == SUREFI_SEC_SERVICE_UUID || service.uuid == SUREFI_CMD_SERVICE_UUID {
                print("SFBridgeController - Discovered Service...\(service.uuid)")
                peripheral.discoverCharacteristics(nil,for: thisService)
            }
        }
    }
    
   func peripheral(_ peripheral: CBPeripheral,didDiscoverCharacteristicsFor service: CBService,error: Error?) {
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if devicePeripheral != nil && peripheral == devicePeripheral {
                if thisCharacteristic.uuid == SUREFI_TX_UID_UUID {
                    print("SFBridgeController - Discovered Characteristic - SUREFI_TX_UID_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceTxCharacteristic = thisCharacteristic
                    selectedDeviceTxUUID = deviceTxCharacteristic.value?.hexStringFromData() ?? ""
                }
                if thisCharacteristic.uuid == SUREFI_RX_UID_UUID {
                    print("SFBridgeController - Discovered Characteristic - SUREFI_RX_UID_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceRxCharacteristic = thisCharacteristic
                    selectedDeviceRxUUID = deviceRxCharacteristic.value?.hexStringFromData() ?? ""
                }
                if thisCharacteristic.uuid == SUREFI_STATUS_UUID {
                    print("SFBridgeController - Discovered Characteristic - SUREFI_STATUS_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceStatusCharacteristic = thisCharacteristic
                    peripheral.readValue(for: deviceStatusCharacteristic)
                }
                if thisCharacteristic.uuid == SUREFI_SEC_HASH_UUID {
                    print("SFBridgeController - Discovered Characteristic - SUREFI_SEC_HASH_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceSecHashCharacteristic = thisCharacteristic
                    
                    let data = getSecurityHash(manufacturerDataString: deviceManufacturerDataString)
                    print("SFBridgeController - Writing to Security Characteristic - \(data)")
                    self.devicePeripheral.writeValue(data as Data, for: self.deviceSecHashCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
                if thisCharacteristic.uuid == SUREFI_CMD_WRITE_UUID {
                    print("SFBridgeController - Discovered Characteristic - SUREFI_CMD_WRITE_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceCmdWriteCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == SUREFI_CMD_READ_UUID {
                    print("SFBridgeController - Discovered Characteristic - SUREFI_CMD_READ_UUID")
                    peripheral.setNotifyValue(true,for: thisCharacteristic)
                    deviceCmdReadCharacteristic = thisCharacteristic
                }
            }
            
            if deviceSecHashCharacteristic != nil && deviceCmdReadCharacteristic != nil && deviceCmdWriteCharacteristic != nil {
                connected = true
                refreshData()
            }
        }
    }
    
    private func getSecurityHash(manufacturerDataString: String) -> Data {
        
        let peripheralRXUUID = manufacturerDataString.substring(from: 12).substring(to: 6)
        let peripheralTXUUID = manufacturerDataString.substring(from:18).substring(to: 6)
        let string = "\(String(peripheralRXUUID.uppercased().characters.reversed()))\(peripheralTXUUID.uppercased())x~sW5-C\"6fu>!!~X"
        let data = string.getMD5()
        return data
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == SUREFI_TX_UID_UUID {
            
            let uuid = peripheral.identifier.uuidString
            surefiMfgStrings.removeValue(forKey: uuid)
            let deviceIndex = surefiDevices.index(of: peripheral) ?? -1
            if deviceIndex >= 0 {
                surefiDevices.remove(at: deviceIndex)
            }
        }
        
        if characteristic.uuid == SUREFI_CMD_WRITE_UUID {
            
            if currentCommand == "update_radio" {
                
                let alert: UIAlertController = UIAlertController(title: "Update Complete", message: "Sure-Fi Radio Settings successfully updated.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                alert.show()
                
                getRadioSettings()
            }
            currentCommand = ""
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == SUREFI_STATUS_UUID {
            let value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            print("SFBridgeController - BLE Read - Status:\(value)")
            selectedDeviceStatus = value
        }
        
        
        if characteristic.uuid == SUREFI_TX_UID_UUID {
            let value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            print("SFBridgeController - BLE Read - TxUUID:\(value)")
            print("TX UUID Updated")
        }
        
        if characteristic.uuid == SUREFI_CMD_READ_UUID {
            
            let value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            print("SFBridgeController - BLE Read - CMD:\(value)")
            
            let response = value.substring(to: 2)
            let data = value.substring(from: 2)
            
            switch (response) {
                
            //App Firmware Version
            case "01":
                let version = data.dataFromHexString()
                var major: Int = 0
                var minor: Int = 0
                version?.getBytes(&major, range: NSRange(location: 0, length: 1))
                version?.getBytes(&minor, range: NSRange(location: 1, length: 1))
                appFirmwareDataString = "v\(major).\(minor)"
                getRadioFirmwareVersion()
                break
                
            //Radio Firmware Version
            case "09":
                let version = data.dataFromHexString()
                var major: Int = 0
                var minor: Int = 0
                version?.getBytes(&major, range: NSRange(location: 0, length: 1))
                version?.getBytes(&minor, range: NSRange(location: 1, length: 1))
                radioFirmwareDataString = "v\(major).\(minor)"
                getBluetoothFirmwareVersion()
                break
                
            //Bluetooth Firmware Version
            case "12":
                let version = data.dataFromHexString()
                var major: Int = 0
                var minor: Int = 0
                version?.getBytes(&major, range: NSRange(location: 0, length: 1))
                version?.getBytes(&minor, range: NSRange(location: 1, length: 1))
                btFirmwareDataString = "v\(major).\(minor)"
                getRadioSettings()
                break
                
            //Get Bootloader Info
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
                        let alert: UIAlertController = UIAlertController(title: "CRC ERROR", message: "CRC Error on Bridge Device", preferredStyle: UIAlertControllerStyle.alert);
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                        alert.show()
                    }
                    return
                }
                getAppFirmwareVersion()
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
                connected = false
                selectedFirmwareType = -1
                btTimer.invalidate()
                refreshData()
                break
            case "08":
                radioSettingsDataString = data
                
                let spreadingFactor = Int(radioSettingsDataString.substring(from: 0).substring(to: 2).hexaToDecimal)
                let bandwidth       = Int(radioSettingsDataString.substring(from: 2).substring(to: 2).hexaToDecimal)
                let powerAmp        = Int(radioSettingsDataString.substring(from: 4).substring(to: 2).hexaToDecimal)
                
                selectedDevicePower = powerArray[powerAmp - 1]
                selectedDeviceSF = "SF\(spreadingFactorArray[bandwidth - 1])"
                selectedDeviceBandwidth = "\(bandwidthArray[bandwidth - 1]) kHz"
                
                getVoltage()
                break
            case "14":
                
                let pwrHexStr = data.substring(from: 0).substring(to: 4).uppercased()
                let batHexStr = data.substring(from: 4).substring(to: 4).uppercased()
                
                let pwrIntVal = Double(pwrHexStr.hexaToDecimal)
                let batHexVal = Double(batHexStr.hexaToDecimal)
                
                selectedDeviceVoltagePwr = Double(( pwrIntVal / 4095 ) * 16.5).roundTo(places: 2)
                selectedDeviceVoltageBat = Double(( batHexVal / 4095 ) * 16.5).roundTo(places: 2)
                
                print("Pwr: \(selectedDeviceVoltagePwr) volts")
                print("Bat: \(selectedDeviceVoltageBat) volts")
                
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
                        self.selectedFirmwareType = -1
                        self.devicePeripheral = nil
                        self.btTimer.invalidate()
                    }));
                    alert.show()
                }
                break
                
            default:
                break
            }
        }
    }
                
    private func incrementProgramNumber(programNumber: String) -> String {
        let versionNumber = programNumber.hexaToDecimal + 1
        var versionString = versionNumber.toHexaString
        while versionString.length < 4 {
            versionString = "0\(versionString)"
        }
        return versionString
    }
    
    func deviceExists(deviceID: String) -> Bool {
        
        if(surefiDevices.count==0) {
            return false
        } else {
            
            for (uuid,manufacturerDataString) in surefiMfgStrings {
                
                var peripheralDeviceID = manufacturerDataString
                if peripheralDeviceID.substring(to: 4).uppercased() == "FFFF" {
                    peripheralDeviceID = peripheralDeviceID.substring(from: 12).substring(to: 6)
                } else {
                    peripheralDeviceID = peripheralDeviceID.substring(from: 8).substring(to: 6)
                }
                if peripheralDeviceID.uppercased().range(of: deviceID.uppercased()) != nil {
                    return true
                }
            }
            return false
        }
    }
    
    func getMfgString(deviceID: String) -> String {
        
        for (uuid,manufacturerDataString) in surefiMfgStrings {
            
            var peripheralDeviceID = manufacturerDataString
            if peripheralDeviceID.substring(to: 4).uppercased() == "FFFF" {
                peripheralDeviceID = peripheralDeviceID.substring(from: 12).substring(to: 6)
            } else {
                peripheralDeviceID = peripheralDeviceID.substring(from: 8).substring(to: 6)
            }
            if peripheralDeviceID.uppercased().range(of: deviceID.uppercased()) != nil {
                return manufacturerDataString
            }
        }
        return ""
    }
    
    func disconnectDevice() {
        centralManager.cancelPeripheralConnection(devicePeripheral)
    }
    
    func connectDevice() {
        centralManager.connect(devicePeripheral, options: nil)
    }
    
    func selectPeripheral(deviceID: String) -> Bool {
        
        if(surefiDevices.count==0) {
            return false
        } else {
            
            for surefiDevice in surefiDevices {
                
                let uuid = surefiDevice.identifier.uuidString
                let mfgString = surefiMfgStrings[uuid]!
                var deviceStatusString = mfgString
                var peripheralDeviceID = ""
                
                if mfgString.substring(to: 4).uppercased() == "FFFF" {
                    deviceStatusString = mfgString.substring(from: 4).substring(to: 8)
                    peripheralDeviceID = mfgString.substring(from: 12).substring(to: 6)
                } else {
                    deviceStatusString = mfgString.substring(from: 0).substring(to: 4)
                    peripheralDeviceID = mfgString.substring(from: 8).substring(to: 6)
                }
                
                if peripheralDeviceID.uppercased().range(of: deviceID.uppercased()) != nil {
                    devicePeripheral = surefiDevice
                    devicePeripheral.delegate = self
                    deviceManufacturerDataString = mfgString
                    selectedDeviceID = deviceID
                    selectedDeviceStatus = ""
                    selectedDeviceType = Int(mfgString.substring(from: 4).substring(to: 2))!
                    connectDevice()
                    return true
                }
            }
            return false
        }
    }
    
    func pairBridge(centralDeviceID: String, remoteDeviceID: String) -> Bool {
        
        var writeID = ""
        if centralDeviceID == selectedDeviceID {
            writeID = remoteDeviceID
        } else if remoteDeviceID == selectedDeviceID {
            writeID = centralDeviceID
        } else {
            return false
        }
        let data = writeID.dataFromHexString()
        devicePeripheral.writeValue(data! as Data, for: deviceTxCharacteristic, type: CBCharacteristicWriteType.withResponse)
        return true
    }
    
    func unpairBridge(centralDeviceID: String, remoteDeviceID: String) -> Bool {
        
        var writeID = ""
        if centralDeviceID == selectedDeviceID {
            writeID = "000000"
        } else if remoteDeviceID == selectedDeviceID {
            writeID = "000000"
        } else {
            return false
        }
        let data = writeID.dataFromHexString()
        devicePeripheral.writeValue(data! as Data, for: deviceTxCharacteristic, type: CBCharacteristicWriteType.withResponse)
        return true
    }
    
    func refreshData() {
        getDeviceStatus()
    }
    
    private func getDeviceStatus() {
        let messageBytes: Data = Data([0x08])
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
    }
    private func getDeviceData() {
        let messageBytes: Data = Data([0x08])
        print("BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
    }
    private func getAppFirmwareVersion() {
        let messageBytes: Data = Data([0x01])
        print("SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
    }
    
    private func getRadioFirmwareVersion() {
         let messageBytes: Data = Data([0x02])
        print("SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
    }
    
    private func getBluetoothFirmwareVersion() {
        let messageBytes: Data = Data([0x1B])
        print("SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
    }
    
    private func getRadioSettings() {
        let messageBytes: Data = Data([0x09])
        print("SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
    }
    
    private func getVoltage() {
        let messageBytes: Data = Data([0x1E])
        print("SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
    }
    
    func setRadioSettings(spreadingFactorValue: UInt8, bandwidthValue: UInt8, powerValue: UInt8, retryValue: UInt8, heartbeatValue: UInt8, acksValue: UInt8) {
        
        var messageBytes: Data = Data([0x0A])
        
        messageBytes.append(spreadingFactorValue)
        messageBytes.append(bandwidthValue)
        messageBytes.append(powerValue)
        messageBytes.append(retryValue)
        messageBytes.append(heartbeatValue)
        messageBytes.append(acksValue)
        
        print("SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())")
        
        currentCommand = "update_radio"
        
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        
    }
    
    func startCentralApplicationUpdate(firmwareURLString: String) {
        
        selectedFirmwareType = 0
        filePathString = firmwareURLString
        timerAction = "flash_application"
        let firmwareURL = URL(string: firmwareURLString)!
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
    
    func startRemoteApplicationUpdate(firmwareURLString: String) {
        
        selectedFirmwareType = 0
        filePathString = firmwareURLString
        timerAction = "flash_application"
        let firmwareURL = URL(string: firmwareURLString)!
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
    
    func startCentralRadioUpdate(firmwareURLString: String) {
        
        selectedFirmwareType = 1
        filePathString = firmwareURLString
        timerAction = "flash_radio"
        let firmwareURL = URL(string: firmwareURLString)!
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
    
    func startRemoteRadioUpdate(firmwareURLString: String) {
        
        selectedFirmwareType = 1
        filePathString = firmwareURLString
        timerAction = "flash_radio"
        let firmwareURL = URL(string: firmwareURLString)!
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
    
    func startCentralBluetoothUpdate(firmwareURLString: String) {
        
        filePathString = firmwareURLString
        timerAction = "flash_bluetooth"
        let messageBytes: Data = Data([0x1A])
        print("SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        self.btTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(bluetoothTimerTick(sender:)), userInfo: nil, repeats: true)
    }
    
    func startRemoteBluetoothUpdate(firmwareURLString: String) {
        
        filePathString = firmwareURLString
        timerAction = "flash_bluetooth"
        let messageBytes: Data = Data([0x1A])
        print("SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())")
        devicePeripheral.writeValue(messageBytes, for: deviceCmdWriteCharacteristic, type: .withResponse)
        self.btTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(bluetoothTimerTick(sender:)), userInfo: nil, repeats: true)
    }
    
    private func flashCentralBluetoothFirmware() {
        
        readyToFlash = false
        
        let firmwareURL = URL(string: filePathString)!
        print("SFBridgeController - Downloading Firmware File:\(firmwareURL.absoluteString)")
        var firmwareZipFile: Data = Data()
        do {
            firmwareZipFile = try Data.init(contentsOf: firmwareURL)
        } catch {
            print(error)
        }
        
        if firmwareZipFile.count > 0 {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath = documentsPath.appending("/").appending("bt\(Date().timeIntervalSince1970).zip")
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
        } else {
            print("Error Downloading File")
        }
    }
    
    private func flashRemoteBluetoothFirmware() {
        
        readyToFlash = false
        let firmwareURL = URL(string: filePathString)!
        print("SFBridgeController - Downloading Firmware File:\(firmwareURL.absoluteString)")
        var firmwareZipFile: Data = Data()
        do {
            firmwareZipFile = try Data.init(contentsOf: firmwareURL)
        } catch {
            print(error)
        }
        
        if firmwareZipFile.count > 0 {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath = documentsPath.appending("/").appending("bt\(Date().timeIntervalSince1970).zip")
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
        } else {
            print("Error Downloading File")
        }
    }
    
    @IBAction func bluetoothTimerTick(sender: Timer) {
        
        //print("SFBridgeController - BT Timer Tick")
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
                    } else {
                        return
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
                            } else {
                                return
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
                        sender.invalidate()
                        
                    } else {
                        
                        currentProgress = Int((Float(self.currentPackageCount) / Float(self.totalPackages)) * 100)
                        currentProgressMessage = "Uploading - \(currentProgress)%"
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
                            } else {
                                return
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
                                } else {
                                    return
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
                
                if readyToFlash && selectedDeviceType == 1 {
                    flashCentralBluetoothFirmware()
                }
                if readyToFlash && selectedDeviceType == 2 {
                    flashRemoteBluetoothFirmware()
                }
            }
        }
    }
    
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        
        currentProgress = progress
        currentProgressMessage = "\(currentState) - \(currentProgress)%"
    }
    
    func dfuStateDidChange(to state: DFUState) {
        
        print("DFU State Changed:\(state.description())")
        currentState = state.description()
        currentProgressMessage = "\(currentState) - \(currentProgress)%"
        
        if state == .completed {
            let alertController = UIAlertController(title: "Update Completed", message: "Bluetooth Module Firmware Updated", preferredStyle: .alert)
            let continueAction = UIAlertAction(title: "Continue", style: .default, handler: {
                action in
                self.btTimer.invalidate()
                self.isUpdatingFirmware = false
                self.connected = false
                self.selectedFirmwareType = -1
                self.devicePeripheral = nil
            })
            alertController.addAction(continueAction)
            alertController.show()
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        print("DFU Error:\(message)")
    }
    
    func logWith(_ level: LogLevel, message: String) {
        print("DFU Log:\(message)")
    }
}

