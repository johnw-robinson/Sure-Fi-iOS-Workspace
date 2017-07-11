//
//  BridgeFirmwareSelectTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 5/23/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class BridgeFirmwareSelectTableViewController: UITableViewController {
    
    var bridgeFirmwareUpdateViewController: BridgeFirmwareUpdateViewController!
    var firmwareFiles: NSMutableArray = NSMutableArray()
    
    var selectedSection: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem?.isEnabled = false
        self.navigationItem.title = "Select Firmware File"
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView?.backgroundView = backgroundImageView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return firmwareFiles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == selectedSection {
            return 2
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 1 {
            return 128
        }
        return 44
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        let firmwareData = firmwareFiles.object(at: indexPath.section) as? NSMutableDictionary ?? NSMutableDictionary()

        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectCell", for: indexPath)
            
            cell.textLabel?.text = "\(firmwareData.object(forKey: "firmware_title") as? String ?? "") v\(firmwareData.object(forKey: "firmware_version") as? String ?? "")"
            cell.detailTextLabel?.text = "\(firmwareData.object(forKey: "firmware_filename") as? String ?? "") - \(firmwareData.object(forKey: "firmware_description") as? String ?? "")"
            
            if indexPath.section == selectedSection {
                cell.imageView?.image = UIImage(named: "check")
            } else {
                cell.imageView?.image = nil
            }
        }
        if indexPath.row == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
            
            let firmwareTitleLabel = cell.viewWithTag(100) as! UILabel
            let firmwareVersionLabel = cell.viewWithTag(200) as! UILabel
            let firmwareStatusLabel = cell.viewWithTag(300) as! UILabel
            let firmwareDescriptionView = cell.viewWithTag(400) as! UITextView
            
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
                firmwareStatusLabel.backgroundColor = UIColor.green
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
            firmwareDescriptionView.text = firmwareData.object(forKey: "firmware_description") as? String ?? ""
        }
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section != selectedSection {
            selectedSection = indexPath.section
            let firmwareData = firmwareFiles.object(at: indexPath.section) as? NSMutableDictionary ?? NSMutableDictionary()
            bridgeFirmwareUpdateViewController.firmwareFilePath = firmwareData.object(forKey: "firmware_path") as? String ?? ""
            bridgeFirmwareUpdateViewController.selectFirmwareFileButton.setTitle(firmwareData.object(forKey: "firmware_title") as? String ?? "", for: .normal)
            self.navigationItem.backBarButtonItem?.isEnabled = true
        } else {
            selectedSection = -1
            bridgeFirmwareUpdateViewController.firmwareFilePath = ""
            bridgeFirmwareUpdateViewController.selectFirmwareFileButton.setTitle("Select Firmware File", for: .normal)
            self.navigationItem.backBarButtonItem?.isEnabled = false
        }
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
