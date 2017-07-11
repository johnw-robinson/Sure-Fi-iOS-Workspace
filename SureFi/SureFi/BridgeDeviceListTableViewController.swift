//
//  BridgeDeviceListTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 7/5/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth

class BridgeDeviceListTableViewController: UITableViewController {
    
    var surefiDevices: Array<CBPeripheral> = Array<CBPeripheral>()
    var surefiMfgStrings: [String:String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return surefiDevices.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Discovered Sure-Fi Devices"
        }
        return ""
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        
        let deviceData = surefiDevices[indexPath.row]
        let uuid = deviceData.identifier.uuidString
        let manufacturerDataString = surefiMfgStrings[uuid]!
        
        
        let hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
        let firmwareVersion = manufacturerDataString.substring(from: 6).substring(to: 4)
        var status = manufacturerDataString.substring(from: 10).substring(to: 2)
        var deviceID = manufacturerDataString.substring(from: 12).substring(to: 6)
        var remoteID = manufacturerDataString.substring(from: 18).substring(to: 6)
        
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
            status = "00"
        }
        
        switch status {
        case "00":
            detailsString = "\(detailsString)Unregistered "
        case "01":
            detailsString = "\(detailsString)Unpaired "
        case "02":
            detailsString = "\(detailsString)Pairing to \(remoteID.uppercased()) "
        case "03":
            detailsString = "\(detailsString)Paired to \(remoteID.uppercased()) "
        default:
            detailsString = ""
        }
        
        cell.textLabel?.text = "\(deviceData.name!) - \(deviceID.uppercased())"
        cell.detailTextLabel?.text = detailsString
        
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
