//
//  ACBG2SelectFirmwareTableViewController.swift
//  SureFiManufacturing
//
//  Created by John Robinson on 6/20/17.
//  Copyright © 2017 Sure-Fi. All rights reserved.
//

import UIKit

class ACBG2SelectFirmwareTableViewController: UITableViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var flashFirmwareController: ACBG2FlashSerialViewController!
    
    var centralApplicationFiles: NSArray = NSArray()
    var centralRadioFiles: NSArray = NSArray()
    var remoteApplicationFiles: NSArray = NSArray()
    var remoteRadioFiles: NSArray = NSArray()
    
    var selectedCentralApplicationFile = -1
    var selectedCentralRadioFile = -1
    var selectedRemoteApplicationFile = -1
    var selectedRemoteRadioFile = -1
    
    var selectFilesButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getCentralApplicationFirmware()
        getCentralRadioFirmware()
        getRemoteApplicationFirmware()
        getRemoteRadioFirmware()
        
        self.navigationItem.title = "Select Firmware Files"
        
        selectFilesButton = UIBarButtonItem(title: "Select Files", style: .plain, target: self, action: #selector(selectFilesButtonPress(sender:)))
        selectFilesButton.isEnabled = false
        self.navigationItem.rightBarButtonItem = selectFilesButton

    }

    @IBAction func selectFilesButtonPress(sender: UIBarButtonItem) {
        flashFirmwareController.viewDidLoad()
        self.navigationController?.pop(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return centralApplicationFiles.count
        case 1:
            return centralRadioFiles.count
        case 2:
            return remoteApplicationFiles.count
        case 3:
            return remoteRadioFiles.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 {
            return "Central Application Board Firmware"
        }
        if section == 1 {
            return "Central Radio Board Firmware"
        }
        if section == 2 {
            return "Remote Application Board Firmware"
        }
        if section == 3 {
            return "Remote Radio Board Firmware"
        }
        return ""
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath)
        let firmwareStatusLabel: UILabel = cell.viewWithTag(100) as! UILabel
        let firmwareTitleLabel: UILabel = cell.viewWithTag(200) as! UILabel
        let firmwareVersionLabel: UILabel = cell.viewWithTag(300) as! UILabel
        
        cell.backgroundColor = .white
        
        var firmwareData: NSMutableDictionary = NSMutableDictionary()
        if indexPath.section == 0 {
            firmwareData = centralApplicationFiles.object(at: indexPath.row) as? NSMutableDictionary ?? NSMutableDictionary()
            if selectedCentralApplicationFile == indexPath.row {
                cell.backgroundColor = UIColor.paleBlue
            }
        }
        if indexPath.section == 1 {
            firmwareData = centralRadioFiles.object(at: indexPath.row) as? NSMutableDictionary ?? NSMutableDictionary()
            if selectedCentralRadioFile == indexPath.row {
                cell.backgroundColor = UIColor.paleBlue
            }
        }
        if indexPath.section == 2 {
            firmwareData = remoteApplicationFiles.object(at: indexPath.row) as? NSMutableDictionary ?? NSMutableDictionary()
            if selectedRemoteApplicationFile == indexPath.row {
                cell.backgroundColor = UIColor.paleBlue
            }
        }
        if indexPath.section == 3 {
            firmwareData = remoteRadioFiles.object(at: indexPath.row) as? NSMutableDictionary ?? NSMutableDictionary()
            if selectedRemoteRadioFile == indexPath.row {
                cell.backgroundColor = UIColor.paleBlue
            }
        }
        
        firmwareTitleLabel.text = firmwareData.object(forKey: "firmware_title") as? String ?? ""
        firmwareVersionLabel.text = firmwareData.object(forKey: "firmware_version") as? String ?? ""
        var firmwareStatus: Int = Int(firmwareData.object(forKey: "firmware_status") as? String ?? "-1")!
        if firmwareStatus == -1 {
            firmwareStatus = firmwareData.object(forKey: "firmware_status") as? Int ?? -1
        }
        switch (firmwareStatus) {
        case 1:
            firmwareStatusLabel.text = "Development"
            firmwareStatusLabel.backgroundColor = UIColor.blue
        case 2:
            firmwareStatusLabel.text = "Release"
            firmwareStatusLabel.backgroundColor = UIColor.darkGreen
        case 3:
            firmwareStatusLabel.text = "Beta"
            firmwareStatusLabel.backgroundColor = UIColor.orange
        case 4:
            firmwareStatusLabel.text = "Depricated"
            firmwareStatusLabel.backgroundColor = UIColor.red
        default:
            firmwareStatusLabel.text = "Unknown Status"
            firmwareStatusLabel.backgroundColor = UIColor.purple
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if indexPath.row != selectedCentralApplicationFile {
                selectedCentralApplicationFile = indexPath.row
            } else {
                selectedCentralApplicationFile = -1
            }
        }
        if indexPath.section == 1 {
            if indexPath.row != selectedCentralRadioFile {
                selectedCentralRadioFile = indexPath.row
            } else {
                selectedCentralRadioFile = -1
            }
        }
        if indexPath.section == 2 {
            if indexPath.row != selectedRemoteApplicationFile {
                selectedRemoteApplicationFile = indexPath.row
            } else {
                selectedRemoteApplicationFile = -1
            }
        }
        if indexPath.section == 3 {
            if indexPath.row != selectedRemoteRadioFile {
                selectedRemoteRadioFile = indexPath.row
            } else {
                selectedRemoteRadioFile = -1
            }
        }
        if selectedCentralApplicationFile != -1 && selectedCentralRadioFile != -1 && selectedRemoteApplicationFile != -1 && selectedRemoteRadioFile != -1 {
            selectFilesButton.isEnabled = true
        } else {
            selectFilesButton.isEnabled = false
        }
        
        
        tableView.reloadData()
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
    
    func getCentralApplicationFirmwareCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                self.centralApplicationFiles = data["files"] as? NSMutableArray ?? NSMutableArray()
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
                self.tableView.reloadData()
            } else {
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
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
