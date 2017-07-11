//
//  BridgeFirmwareUpdateViewController.swift
//  SureFi
//
//  Created by John Robinson on 5/17/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth

class BridgeFirmwareUpdateViewController: UIViewController, CBPeripheralDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var bridgeConfigureTableViewController: BridgeConfigureTableViewController!
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var pageProgressLabel: UILabel!
    @IBOutlet var packageProgressLabel: UILabel!
    @IBOutlet var pageProgressView: UIProgressView!
    @IBOutlet var packageProgressView: UIProgressView!
    @IBOutlet var instructionsLabel:UILabel!
    @IBOutlet var timeEstimateLabel: UILabel!
    @IBOutlet var statusView: UIView!
    @IBOutlet var selectFirmwareFileButton: UIButton!
    
    var firmwareFilePath = ""
    let pageSize: Int = 2048
    let packageSize: Int = 19
    var pageCount: Int = -1
    var currentPage: Int = -1
    var currentPackage: Int = -1
    
    var totalPackages = -1
    var currentPackageCount = 0
    
    var timer: Timer = Timer()
    
    var firmwareType: String!
    var hardwareType: String!
    
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
    
    var firmwareFiles: NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusLabel.text = ""
        pageProgressLabel.text = ""
        packageProgressLabel.text = ""
        
        self.navigationItem.title = "Update Firmware"
        
        getFirmwareFilesList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let startButton = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(startButtonPress(sender:)))
        let testButton = UIBarButtonItem(title: "Test", style: .plain, target: self, action: #selector(testButtonPress(sender:)))
        
        if firmwareFilePath == "" {
            startButton.isEnabled = false
            testButton.isEnabled = false
            selectFirmwareFileButton.setTitle("Select Firmware File", for: .normal)
        } else {
            startButton.isEnabled = true
            testButton.isEnabled = true
        }
        self.navigationItem.rightBarButtonItems = [startButton,testButton]
    }
 
    func getFirmwareFilesList() {
        
        let postData = NSMutableDictionary()
        if hardwareType == "CENTRAL" {
            postData.setValue("eaa4c810-e477-489c-8ae8-c86387b1c62e", forKey: "hardware_type_key")
        }
        if hardwareType == "REMOTE" {
            postData.setValue("0ef2c2a6-ef1f-43e3-be3a-e69628f5c7bf", forKey: "hardware_type_key")
        }
        if firmwareType == "APPLICATION" {
            postData.setValue("application", forKey: "firmware_type")
        }
        if firmwareType == "RADIO" {
            postData.setValue("radio", forKey: "firmware_type")
        }
        if firmwareType == "BLUETOOTH" {
            postData.setValue("bluetooth", forKey: "firmware_type")
        }
        
        SessionController().postServerRequest(action: "firmware/get_available_firmware", postData: postData, urlData:"", callback: self.getFirmwareFilesListCallback)
        
    }
    
    func getFirmwareFilesListCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        
        if status {
            
            firmwareFiles = data["files"] as? NSMutableArray ?? NSMutableArray()
        } else {
            print(msg)
        }
    }
    
    @IBAction func selectFirmwareFileButtonPress(sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "BridgeFirmwareSelectTableViewController") as! BridgeFirmwareSelectTableViewController
        controller.bridgeFirmwareUpdateViewController = self
        controller.firmwareFiles = firmwareFiles
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: nil)
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
    
    @IBAction func testButtonPress(sender: UIBarButtonItem) {
        
        var lines:[String] = []
        do {
            fileData = try Data(contentsOf: URL(string: firmwareFilePath)!)
            
            pageCount = Int(ceil(Float(fileData.count) / Float(pageSize)))
            
            for pageIndex in 0..<pageCount {
                
                let pageByteStart = pageIndex * pageSize
                var pageByteEnd = pageByteStart + pageSize
                if pageByteEnd >= fileData.count {
                    pageByteEnd = fileData.count
                }
                let pageBytes = fileData.subdata(in: pageByteStart..<pageByteEnd)
                let crc = pageBytes.crc16()
                let crcString = String(format:"%X", crc).leftPadding(toLength: 4, withPad: "0")
                
                lines.append("\(pageIndex+1) of \(pageCount) \(pageBytes.count) bytes CRC:\(crcString)")
                
            }
            
            let alert: UIAlertController = UIAlertController(title: "Success", message: lines.joined(separator: "\n"), preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            self.present(alert,animated: true, completion: nil);
            
        } catch {
            let alert: UIAlertController = UIAlertController(title: "Error", message: "Error downloading firmware file.", preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            self.present(alert,animated: true, completion: nil);
            
            print("Error info: \(error)")
            return
        }
        
        
    }
    
    
    @IBAction func startButtonPress(sender: UIBarButtonItem) {
        
        if firmwareFilePath == "" {
            let alert: UIAlertController = UIAlertController(title: "No Firmware File Selected", message: "Please select a firmware file to write to this device.", preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            self.present(alert,animated: true, completion: nil);
            return
        }
        
        if hardwareType == "CENTRAL" {
            bridgeConfigureTableViewController.centralPeripheral.delegate = self
            if bridgeConfigureTableViewController.centralCmdWriteCharacteristic == nil {
                let alert: UIAlertController = UIAlertController(title: "Incompatible Device", message: "Firmware Update is not supported on this device.", preferredStyle: UIAlertControllerStyle.alert);
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                self.present(alert,animated: true, completion: nil);
                return
            }
        } else if hardwareType == "REMOTE" {
            bridgeConfigureTableViewController.remotePeripheral.delegate = self
            if bridgeConfigureTableViewController.remoteCmdWriteCharacteristic == nil {
                let alert: UIAlertController = UIAlertController(title: "Incompatible Device", message: "Firmware Update is not supported on this device.", preferredStyle: UIAlertControllerStyle.alert);
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                self.present(alert,animated: true, completion: nil);
                return
            }
        } else {
            let alert: UIAlertController = UIAlertController(title: "Incompatible Device", message: "Firmware Update is not supported on this device.", preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            self.present(alert,animated: true, completion: nil);
            return
        }
        
        DispatchQueue.main.async {
            self.statusLabel.text = "Downloading Firmware File"
            self.statusView.isHidden = false
            self.instructionsLabel.isHidden = false
            sender.isEnabled = false
        }
        
        do {
            
            fileData = try Data(contentsOf: URL(string: firmwareFilePath)!)

            pageCount = Int(ceil(Float(fileData.count) / Float(pageSize)))
            startTime = NSDate().timeIntervalSince1970
            DispatchQueue.main.async {
                self.statusLabel.text = "Processing Firmware File"
                self.pageProgressLabel.text = "There will be \(self.pageCount) pages"
                self.pageProgressView.isHidden = false
                self.pageProgressView.progress = 0
                self.packageProgressView.isHidden = false
                self.packageProgressView.progress = 0
                self.instructionsLabel.isHidden = true
            }
            
        } catch {
            print("Error info: \(error)")
            return
        }
        print("Starting")
        timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(processFirmwareUpdate), userInfo: nil, repeats: true)
        
    }
    
    func processFirmwareUpdate() {
        
        let currentTime = NSDate().timeIntervalSince1970
        let timeDiff = currentTime - startTime
        if !processingBusy {
            
            if imageNumberLoaded == false {
                
                processingBusy = true
                let messageBytes: Data = Data([0x08])
                print("BLE Cmd:\(messageBytes.hexStringFromData())")
                switch hardwareType {
                case "CENTRAL":
                    bridgeConfigureTableViewController.centralPeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.centralCmdWriteCharacteristic, type: .withResponse)
                case "REMOTE":
                    bridgeConfigureTableViewController.remotePeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.remoteCmdWriteCharacteristic, type: .withResponse)
                default:
                    return
                }
            }
            
            if peripheralReady == false {
                
                processingBusy = true
                var messageBytes: Data = Data()
                if firmwareType == "APPLICATION" {
                    messageBytes.append(0x03)
                } else if firmwareType == "RADIO" {
                    messageBytes.append(0x0D)
                }
                
                
                print("BLE Cmd:\(messageBytes.hexStringFromData())")
                switch hardwareType {
                case "CENTRAL":
                    bridgeConfigureTableViewController.centralPeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.centralCmdWriteCharacteristic, type: .withResponse)
                case "REMOTE":
                    bridgeConfigureTableViewController.remotePeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.remoteCmdWriteCharacteristic, type: .withResponse)
                default:
                    return
                }
            } else {
                
                if currentPackage == -1 {
                    
                    if currentPage >= 0 && rowDone == true {
                        
                        processingBusy = true
                        var messageBytes: Data = Data()
                        if firmwareType == "APPLICATION" {
                            messageBytes.append(0x06)
                        } else if firmwareType == "RADIO" {
                            messageBytes.append(0x10)
                        }

                        print("BLE Cmd:\(messageBytes.hexStringFromData())")
                        switch hardwareType {
                        case "CENTRAL":
                            bridgeConfigureTableViewController.centralPeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.centralCmdWriteCharacteristic, type: .withResponse)
                        case "REMOTE":
                            bridgeConfigureTableViewController.remotePeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.remoteCmdWriteCharacteristic, type: .withResponse)
                        default:
                            return
                        }
                        return
                    }
                    
                    currentPackage = 0
                    currentPage += 1
                    return
                }
                
                if currentPage >= pageCount {
                    
                    var messageBytes: Data = Data()
                    if firmwareType == "APPLICATION" {
                        messageBytes.append(0x07)
                    } else if firmwareType == "RADIO" {
                        messageBytes.append(0x11)
                    }
                    
                    print("BLE Cmd:\(messageBytes.hexStringFromData())")
                    switch hardwareType {
                    case "CENTRAL":
                        bridgeConfigureTableViewController.centralPeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.centralCmdWriteCharacteristic, type: .withResponse)
                    case "REMOTE":
                        bridgeConfigureTableViewController.remotePeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.remoteCmdWriteCharacteristic, type: .withResponse)
                    default:
                        return
                    }
                    
                    timer.invalidate()
                    
                } else {
                    
                    if currentPackageCount % 32 == 0 {
                        DispatchQueue.main.async {
                            
                            if (Float(self.currentPackageCount) / Float(self.totalPackages)) > 0.3 {
                                
                                var estimatedTime:Float = (self.currentPackageCount > 0 ? Float(self.totalPackages) * ( Float(timeDiff) / Float(self.currentPackageCount) )  : 0.0)
                                estimatedTime -= Float(timeDiff)
                                
                                self.timeEstimateLabel.text = "About \(Int(estimatedTime)) seconds remaining"
                            } else {
                                self.timeEstimateLabel.text = "Calculating remaining time"
                            }
                        }
                    }
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
                        if firmwareType == "APPLICATION" {
                            messageBytes.append(0x04)
                        } else if firmwareType == "RADIO" {
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
                        switch hardwareType {
                        case "CENTRAL":
                            bridgeConfigureTableViewController.centralPeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.centralCmdWriteCharacteristic, type: .withResponse)
                        case "REMOTE":
                            bridgeConfigureTableViewController.remotePeripheral.writeValue(messageBytes, for: bridgeConfigureTableViewController.remoteCmdWriteCharacteristic, type: .withResponse)
                        default:
                            return
                        }
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
                        
                        DispatchQueue.main.async {
                            self.pageProgressLabel.text = "Processing Page \(self.currentPage+1) of \(self.pageCount)"
                            self.pageProgressView.progress = pageProgress
                        }
                        if currentPackage >= 0 && currentPackage <= packageCount {
                            
                            let packageByteStart = currentPackage * packageSize
                            var packageByteEnd = packageByteStart + packageSize
                            if packageByteEnd >= pageBytes.count {
                                packageByteEnd = pageBytes.count
                            }
                            var packageBytes: Data = Data()
                            if firmwareType == "APPLICATION" {
                                packageBytes.append(0x05)
                            } else if firmwareType == "RADIO" {
                                packageBytes.append(0x0F)
                            }

                            
                            packageBytes.append(pageBytes.subdata(in: packageByteStart..<packageByteEnd))
                            print("BLE Cmd:\(packageBytes.hexStringFromData())")
                            switch hardwareType {
                            case "CENTRAL":
                                bridgeConfigureTableViewController.centralPeripheral.writeValue(packageBytes, for: bridgeConfigureTableViewController.centralCmdWriteCharacteristic, type: .withoutResponse)
                            case "REMOTE":
                                bridgeConfigureTableViewController.remotePeripheral.writeValue(packageBytes, for: bridgeConfigureTableViewController.remoteCmdWriteCharacteristic, type: .withoutResponse)
                            default:
                                return
                            }
                            let packageProgress:Float = Float(currentPackage+1) / Float(packageCount)
                            currentPackageCount += 1
                            
                            DispatchQueue.main.async {
                                self.packageProgressLabel.text = "Sending Package \(self.currentPackage+1) of \(packageCount)"
                                self.packageProgressView.progress = packageProgress
                                self.currentPackage += 1
                                if self.currentPackage >= packageCount {
                                    self.currentPackage = -1
                                    self.rowDone = true
                                }
                                self.processingBusy = false
                            }
                            //print("Sending Package \(self.currentPackage+1) of \(packageCount): \(packageBytes.hexStringFromData())")
                            
                        }
                    }
                }
            }
        } else {
            //print("Busy")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == bridgeConfigureTableViewController.SUREFI_CMD_WRITE_UUID {
            
            let value = bridgeConfigureTableViewController.centralCmdReadCharacteristic.value
            print("Send:\(value)")
        }
        
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == bridgeConfigureTableViewController.SUREFI_CMD_READ_UUID {
            
            let value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            print("BLE Read:\(value)")
            
            let response = value.substring(to: 2)
            let data = value.substring(from: 2)
            
            switch (response) {
            case "01":
                processingBusy = false
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
                firmwareFinished = true
                DispatchQueue.main.async {
                    let alert: UIAlertController = UIAlertController(title: "Update Complete", message: "Firmware Update is Completed", preferredStyle: UIAlertControllerStyle.alert);
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                    self.present(alert,animated: true, completion: nil);
                }
            case "07":
                
                let lowerReadCrc            = data.substring(from:  0).substring(to: 4)
                let lowerCalculatedCrc      = data.substring(from:  4).substring(to: 4)
                //let lowerVersionNumberMajor = data.substring(from:  8).substring(to: 2)
                //let lowerVersionNumberMinor = data.substring(from: 10).substring(to: 2)
                var lowerProgramNumber      = data.substring(from: 12).substring(to: 4)
                let upperReadCrc            = data.substring(from: 16).substring(to: 4)
                let upperCalculatedCrc      = data.substring(from: 20).substring(to: 4)
                //let upperVersionNumberMajor = data.substring(from: 24).substring(to: 2)
                //let upperVersionNumberMinor = data.substring(from: 26).substring(to: 2)
                var upperProgramNumber      = data.substring(from: 28).substring(to: 4)
                let bootingUpperMemory      = data.substring(from: 32).substring(to: 2)

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
                
                processingBusy = false
                imageNumberLoaded = true
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
            default:
                break
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer.invalidate()
    }
    
    func incrementProgramNumber(programNumber: String) -> String {
        let versionNumber = programNumber.hexaToDecimal + 1
        var versionString = versionNumber.toHexaString
        while versionString.length < 4 {
            versionString = "0\(versionString)"
        }
        return versionString
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
