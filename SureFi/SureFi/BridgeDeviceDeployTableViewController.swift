//
//  BridgeDeviceDeployTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 7/7/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth

class BridgeDeviceDeployTableViewController: UITableViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var sfBridgeController: SFBridgeController!
    
    var currentDeviceState: CBPeripheralState!
    var currentDeviceStatus: String = ""
    
    var centralDeviceID: String = ""
    var centralDeviceMfgString: String = ""
    
    var remoteDeviceID: String = ""
    var remoteDeviceMfgString: String = ""
    
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sfBridgeController = SFBridgeController.shared
        currentDeviceState = sfBridgeController.devicePeripheral.state
        
        if sfBridgeController.selectedDeviceType == 1 {
            centralDeviceID = sfBridgeController.selectedDeviceID
            centralDeviceMfgString = sfBridgeController.getMfgString(deviceID: centralDeviceID)
            remoteDeviceID = centralDeviceMfgString.substring(from: 18).substring(to: 6).uppercased()
            remoteDeviceMfgString = sfBridgeController.getMfgString(deviceID: remoteDeviceID)
        }
        if sfBridgeController.selectedDeviceType == 2 {
            remoteDeviceID = sfBridgeController.selectedDeviceID
            remoteDeviceMfgString = sfBridgeController.getMfgString(deviceID: remoteDeviceID)
            centralDeviceID = remoteDeviceMfgString.substring(from: 18).substring(to: 6).uppercased()
            centralDeviceMfgString = sfBridgeController.getMfgString(deviceID: centralDeviceID)
        }
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerTick(sender:)), userInfo: nil, repeats: true)
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = backgroundImageView
        
        self.navigationItem.title = "Deploy Sure-Fi Bridge"
    }

    @IBAction func timerTick(sender: Timer) {
        
        if sfBridgeController.devicePeripheral.state != currentDeviceState {
            
            if currentDeviceState == .connected && sfBridgeController.devicePeripheral.state == .disconnected {
                sfBridgeController.connectDevice()
            }
        }
        if currentDeviceStatus != sfBridgeController.selectedDeviceStatus {
            print("Current Status:\(currentDeviceStatus) New Status:\(sfBridgeController.selectedDeviceStatus)")
            if currentDeviceStatus == "03" && sfBridgeController.selectedDeviceStatus == "01" {
                let alertController = UIAlertController(title: "UnPairing Complete", message: "The UnPairing command has been sucessfully sent. Please confirm that status lights 3 and 4 are blinking.", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                    action in
                    self.navigationController?.pop(animated: true)
                })
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
            currentDeviceStatus = sfBridgeController.selectedDeviceStatus
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 && (indexPath.section == 0 || indexPath.section == 1) {
            return 144
        }
        if indexPath.section == 2 && indexPath.row == 0 {
            return 48
        }
        return 44
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 && indexPath.row == 0 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "DeviceDetailsCell", for: indexPath)
            let imageButton = cell.viewWithTag(100) as! UIButton!
            let titleLabel = cell.viewWithTag(200) as! UILabel
            let deviceIDLabel = cell.viewWithTag(300) as! UILabel
            let centralStatusLabel = cell.viewWithTag(400) as! UILabel
            
            titleLabel.text = "Central Unit"
            
            let manufacturerDataString = centralDeviceMfgString
            let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
            var hardwareStatus = manufacturerDataString.substring(from: 10).substring(to: 2)
            var deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
            let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
            
            var detailsString = ""
            switch hardwareType {
            case "01":
                detailsString = "\(detailsString)Central Unit "
            case "02":
                detailsString = "\(detailsString)Remote Unit "
            default:
                detailsString = ""
            }
            if deviceID.uppercased()  == "FFFFFF" {
                deviceID = "N/A"
                hardwareStatus = "00"
            }
            
            switch hardwareStatus {
            case "00":
                detailsString = "\(detailsString)Unregistered "
            case "01":
                detailsString = "\(detailsString)Unpaired "
            case "02":
                detailsString = "\(detailsString)Pairing to \(remoteID.uppercased()) "
            case "03":
                detailsString = "\(detailsString)Paired to \(remoteID.uppercased()) "
            case "04":
                detailsString = "\(detailsString)Deployed with \(remoteID.uppercased()) "
            default:
                detailsString = ""
            }
            
            deviceIDLabel.text = centralDeviceID
            centralStatusLabel.text = detailsString
        }
        if indexPath.section == 1 && indexPath.row == 0 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "DeviceDetailsCell", for: indexPath)
            let imageButton = cell.viewWithTag(100) as! UIButton!
            let titleLabel = cell.viewWithTag(200) as! UILabel
            let deviceIDLabel = cell.viewWithTag(300) as! UILabel
            let remoteStatusLabel = cell.viewWithTag(400) as! UILabel
            
            titleLabel.text = "Remote Unit"
            
            let manufacturerDataString = remoteDeviceMfgString
            let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
            var hardwareStatus = manufacturerDataString.substring(from: 10).substring(to: 2)
            var deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
            let remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
            
            var detailsString = ""
            switch hardwareType {
            case "01":
                detailsString = "\(detailsString)Central Unit "
            case "02":
                detailsString = "\(detailsString)Remote Unit "
            default:
                detailsString = ""
            }
            if deviceID.uppercased()  == "FFFFFF" {
                deviceID = "N/A"
                hardwareStatus = "00"
            }
            
            switch hardwareStatus {
            case "00":
                detailsString = "\(detailsString)Unregistered "
            case "01":
                detailsString = "\(detailsString)Unpaired "
            case "02":
                detailsString = "\(detailsString)Pairing to \(remoteID.uppercased()) "
            case "03":
                detailsString = "\(detailsString)Paired to \(remoteID.uppercased()) "
            case "04":
                detailsString = "\(detailsString)Deployed with \(remoteID.uppercased()) "
            default:
                detailsString = ""
            }
            
            deviceIDLabel.text = remoteDeviceID
            remoteStatusLabel.text = detailsString
        }
        cell.selectionStyle = .none
        return cell
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
