//
//  ACBG2DevicesTableViewController.swift
//  SureFiManufacturing
//
//  Created by John Robinson on 6/26/17.
//  Copyright © 2017 Sure-Fi. All rights reserved.
//

import UIKit

class ACBG2DevicesTableViewController: UITableViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var flashFirmwareViewController: ACBG2FlashSerialViewController!
    
    var devicesList: [String:String] = [:]
    
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
        return devicesList.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Unconfigured Sure-Fi Devices (touch to identify)"
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)

        let uuid = Array(devicesList.keys)[indexPath.row]
        let nameString = devicesList[uuid]
        let nameStrings = nameString?.components(separatedBy: "|")
        var mfgString = Array(nameStrings!)[1]
        
        if mfgString.substring(to: 4).uppercased() == "FFFF" {
            mfgString = mfgString.substring(from: 4).substring(to: 8)
        } else {
            mfgString = mfgString.substring(from: 0).substring(to: 8)
        }
        let type = mfgString.substring(from: 0).substring(to: 2)
        let status = mfgString.substring(from: 6).substring(to: 2)
        let timer = flashFirmwareViewController.bluetoothTimers[uuid] as? Int ?? -99
        
        var typeDesc = ""
        var statusDesc = ""
        
        switch type {
        case "01":
            typeDesc = "Central Unit"
        case "02":
            typeDesc = "Remote Unit"
        default:
            typeDesc = "Unknown"
        }
        switch status {
        case "01":
            statusDesc = "Ready"
        case "02":
            statusDesc = "Not Ready - Pairing"
        case "03":
            statusDesc = "Not Ready - Paired"
        default:
            statusDesc = "Unknown"
        }
        cell.textLabel?.text = "\(Array(nameStrings!)[0]) - \(typeDesc) - \(statusDesc) - \(timer)"
        cell.detailTextLabel?.text = uuid

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let uuid = Array(devicesList.keys)[indexPath.row]
        flashFirmwareViewController.identifyPeripheral(deviceUUID: uuid)
        self.tableView.reloadData()
        
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
