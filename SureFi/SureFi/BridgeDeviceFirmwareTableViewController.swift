//
//  BridgeDeviceFirmwareTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 7/7/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class BridgeDeviceFirmwareTableViewController: UITableViewController {
    
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var progressLabel: UILabel!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var sfBridgeController: SFBridgeController!
    
    var readyToFlash: Bool = false
    var isUpdatingFirmware: Bool = false
    var currentProgress: Int = 0
    var currentState: String = ""
    
    var selectedFirmwareFile: Int = -1
    var selectedFirmwareType: Int = -1
    
    var centralApplicationFiles: NSMutableArray = NSMutableArray()
    var centralRadioFiles: NSMutableArray = NSMutableArray()
    var centralBluetoothFiles: NSMutableArray = NSMutableArray()
    var remoteApplicationFiles: NSMutableArray = NSMutableArray()
    var remoteRadioFiles: NSMutableArray = NSMutableArray()
    var remoteBluetoothFiles: NSMutableArray = NSMutableArray()
    
    var firmwareFiles: NSMutableArray = NSMutableArray()
    var timer: Timer!
    var timer_action: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getCentralApplicationFirmware()
        getCentralRadioFirmware()
        getCentralBluetoothFirmware()
        getRemoteApplicationFirmware()
        getRemoteRadioFirmware()
        getRemoteBluetoothFirmware()
        
        sfBridgeController = SFBridgeController.shared
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = backgroundImageView
        
        self.navigationItem.title = "Update Firmware"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        if (section == 1 || section == 2) && isUpdatingFirmware {
            return 1
        }
        if section == 2 && selectedFirmwareType >= 0 {
            return firmwareFiles.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 168
        }
        return 44
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 && indexPath.row == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "DeviceDetailCell", for: indexPath)
            
            let bootloaderLabel = cell.viewWithTag(100) as! UILabel
            let appFirmwareDataLabel = cell.viewWithTag(200) as! UILabel
            let radioFirmwareDataLabel = cell.viewWithTag(300) as! UILabel
            let btFirmwareDataLabel = cell.viewWithTag(400) as! UILabel
            let selectSegmentedControl = cell.viewWithTag(500) as! UISegmentedControl
            
            bootloaderLabel.text = sfBridgeController.bootloaderDataString
            appFirmwareDataLabel.text = sfBridgeController.appFirmwareDataString
            radioFirmwareDataLabel.text = sfBridgeController.radioFirmwareDataString
            btFirmwareDataLabel.text = sfBridgeController.btFirmwareDataString
            
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
        if indexPath.section == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "ProgressCell", for: indexPath)
            
            progressBar = cell.viewWithTag(100) as! UIProgressView
            progressBar.progress = 0
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
            subtitleLabel.text = firmwareData.object(forKey: "firmware_description") as? String ?? ""
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 2 {
            
            if selectedFirmwareFile == indexPath.row {
                selectedFirmwareFile = -1
            } else {
                selectedFirmwareFile = indexPath.row
            }
            self.tableView.reloadData()
        }
        
    }
    
    @IBAction func selectSegmentedControlChanged(sender: UISegmentedControl) {
        selectedFirmwareType = sender.selectedSegmentIndex
        print("SelectedType:\(selectedFirmwareType)")
        
        if selectedFirmwareType >= 0 {
            
            if sfBridgeController.selectedDeviceType == 1 { //Central
                
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
            if sfBridgeController.selectedDeviceType == 2 { //Remote
                
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
            if sfBridgeController.selectedDeviceType == 1 { //Central
                if selectedFirmwareType == 0 { //App
                    print("Flash Central Application")
                    let firmwareFileData = firmwareFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
                    let firmwareURLString = firmwareFileData.object(forKey: "firmware_path") as? String ?? ""
                    if firmwareURLString != "" {
                        sfBridgeController.startCentralApplicationUpdate(firmwareURLString: firmwareURLString)
                    }
                }
                if selectedFirmwareType == 1 { //Radio
                    print("Flash Central Radio")
                    let firmwareFileData = firmwareFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
                    let firmwareURLString = firmwareFileData.object(forKey: "firmware_path") as? String ?? ""
                    if firmwareURLString != "" {
                        sfBridgeController.startCentralRadioUpdate(firmwareURLString: firmwareURLString)
                    }
                }
                if selectedFirmwareType == 2 { //Bluetooth
                    print("Flash Central Bluetooth")
                    let firmwareFileData = firmwareFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
                    let firmwareURLString = firmwareFileData.object(forKey: "firmware_path") as? String ?? ""
                    if firmwareURLString != "" {
                        sfBridgeController.startCentralBluetoothUpdate(firmwareURLString: firmwareURLString)
                    }
                }
            }
            if sfBridgeController.selectedDeviceType == 2 { //Remote
                if selectedFirmwareType == 0 { //App
                    print("Flash Remote Application")
                    let firmwareFileData = firmwareFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
                    let firmwareURLString = firmwareFileData.object(forKey: "firmware_path") as? String ?? ""
                    if firmwareURLString != "" {
                        sfBridgeController.startRemoteApplicationUpdate(firmwareURLString: firmwareURLString)
                    }
                }
                if selectedFirmwareType == 1 { //Radio
                    print("Flash Remote Radio")
                    let firmwareFileData = firmwareFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
                    let firmwareURLString = firmwareFileData.object(forKey: "firmware_path") as? String ?? ""
                    if firmwareURLString != "" {
                        sfBridgeController.startRemoteRadioUpdate(firmwareURLString: firmwareURLString)
                    }
                }
                if selectedFirmwareType == 2 { //Bluetooth
                    print("Flash Remote Bluetooth")
                    let firmwareFileData = firmwareFiles.object(at: selectedFirmwareFile) as? NSMutableDictionary ?? NSMutableDictionary()
                    let firmwareURLString = firmwareFileData.object(forKey: "firmware_path") as? String ?? ""
                    if firmwareURLString != "" {
                        sfBridgeController.startRemoteBluetoothUpdate(firmwareURLString: firmwareURLString)
                    }
                }
            }
            isUpdatingFirmware = true
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateProgress(sender:)), userInfo: nil, repeats: true)
            tableView.reloadData()
        }
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
    
    func updateProgress(sender: Timer) {
        
        if sfBridgeController.firmwareFinished {
            isUpdatingFirmware = false
            sender.invalidate()
            DispatchQueue.main.async {
                let alert: UIAlertController = UIAlertController(title: "Update Complete", message: "Firmware Update is Completed", preferredStyle: UIAlertControllerStyle.alert);
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                    action in
                    self.navigationController?.pop(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        progressBar.progress = Float(sfBridgeController.currentProgress) / 100
        progressLabel.text = sfBridgeController.currentProgressMessage
    }
    
}
