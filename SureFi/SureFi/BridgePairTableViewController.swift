//
//  BridgePairTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 4/18/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class BridgePairTableViewController: UITableViewController,UITextViewDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var newBridgeData :[String:String] = [:]
    var centralImage: UIImage!
    var remoteImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Pair New Sure-Fi Bridge"
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView?.backgroundView = backgroundImageView
        
        appDelegate.getCurrentLocation()
    }
    
    func setBridgeDataValue( field: String, value: String) {
        newBridgeData[field] = value
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if newBridgeData["device_id_central"] ?? "" == "" || centralImage == nil || newBridgeData["device_title_central"] ?? "" == "" {
            return 1
        }
        if newBridgeData["device_id_remote"] ?? "" == "" || remoteImage == nil || newBridgeData["device_title_remote"] ?? "" == ""  {
            return 2
        }
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 || indexPath.section == 1 {
            if indexPath.row == 0 {
                return 148
            }
            if indexPath.row == 1 {
                return 96
            }
            if indexPath.row == 2 {
                return 120
            }
        }
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                return 120
            }
            return 80
        }
        return 1
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 && newBridgeData["device_id_central"] != nil {
            
            if centralImage == nil {
                return 2
            }
            return 3
        }
        if section == 1 && newBridgeData["device_id_remote"] != nil {
            if remoteImage == nil {
                return 2
            }
            return 3
        }
        if section == 2 {
            if newBridgeData["system_title"] ?? "" == "" {
                return 1
            } else {
                return 2
            }
        }
        return 1
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
        if(section==1) {
            return "Remote Unit"
        }
        if(section==2) {
            return "System Details"
        }
        return ""
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
                
                let imageView = cell.viewWithTag(100) as! UIImageView
                let label1 = cell.viewWithTag(200) as! UILabel
                let label2 = cell.viewWithTag(300) as! UILabel
                
                if newBridgeData["device_id_central"]==nil {
                    imageView.image = UIImage(named:"hardware_select")
                    label1.text = "Scan Central Unit"
                    label2.text = ""
                } else {
                    imageView.image = UIImage(named:"hardware_bridge")
                    label1.text = "Sure-Fi Bridge Central"
                    label2.text = newBridgeData["device_id_central"] ?? ""
                }
                cell.accessoryType = .disclosureIndicator
            }
            if indexPath.row == 1 {
                cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath)
                cell.textLabel?.text = "Select an Image for Central Unit"
                cell.textLabel?.numberOfLines = 0
                if centralImage != nil {
                    cell.imageView?.image = centralImage
                } else {
                    cell.imageView?.image = nil
                }
                cell.accessoryType = .disclosureIndicator
            }
            if indexPath.row == 2 {
                cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell", for: indexPath)
                let titleLabel = cell.viewWithTag(100) as! UILabel
                titleLabel.text = "Description of Central Unit Installation"

                let descriptionTextView = cell.viewWithTag(200) as! UITextView
                descriptionTextView.layer.borderWidth = 0.5
                descriptionTextView.layer.borderColor = UIColor.gray.cgColor
                descriptionTextView.delegate = self
                
                descriptionTextView.text = newBridgeData["device_title_central"] ?? "Please provide a description...\n\nExample - The central unit is connected to a 4-Door controller from XYZ Company"
                descriptionTextView.textColor = .black
                if newBridgeData["device_title_central"] == nil || newBridgeData["device_title_central"] == "" {
                    descriptionTextView.textColor = .gray
                }
                cell.accessoryType = .none
            }
            cell.selectionStyle = .none
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
                
                let imageView = cell.viewWithTag(100) as! UIImageView
                let label1 = cell.viewWithTag(200) as! UILabel
                let label2 = cell.viewWithTag(300) as! UILabel
                
                if newBridgeData["device_id_remote"]==nil {
                    imageView.image = UIImage(named:"hardware_select")
                    label1.text = "Scan Remote Unit"
                    label2.text = ""
                } else {
                    imageView.image = UIImage(named:"hardware_bridge")
                    label1.text = "Sure-Fi Bridge Remote"
                    label2.text = newBridgeData["device_id_remote"] ?? ""
                }
                cell.accessoryType = .disclosureIndicator
            }
            if indexPath.row == 1 {
                cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath)
                cell.textLabel?.text = "Select an Image for Remote Unit"
                cell.textLabel?.numberOfLines = 0
                if remoteImage != nil {
                    cell.imageView?.image = remoteImage
                } else {
                    cell.imageView?.image = nil
                }
                cell.accessoryType = .disclosureIndicator
            }
            if indexPath.row == 2 {
                cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell", for: indexPath)
                let titleLabel = cell.viewWithTag(100) as! UILabel
                titleLabel.text = "Description of Remote Unit Installation"
                
                let descriptionTextView = cell.viewWithTag(200) as! UITextView
                descriptionTextView.layer.borderWidth = 0.5
                descriptionTextView.layer.borderColor = UIColor.gray.cgColor
                descriptionTextView.delegate = self
                
                descriptionTextView.text = newBridgeData["device_title_remote"] ?? "Please provide a description...\n\nExample - The remote unit is connected to a weigand keypad from XYZ Company"
                descriptionTextView.textColor = .black
                if newBridgeData["device_title_remote"] == nil || newBridgeData["device_title_remote"] == "" {
                    descriptionTextView.textColor = .gray
                }
                cell.accessoryType = .none
            }
            cell.selectionStyle = .none
        }
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell", for: indexPath)
                let titleLabel = cell.viewWithTag(100) as! UILabel
                titleLabel.text = "Description of Overall Installation"
                
                let descriptionTextView = cell.viewWithTag(200) as! UITextView
                descriptionTextView.layer.borderWidth = 0.5
                descriptionTextView.layer.borderColor = UIColor.gray.cgColor
                descriptionTextView.delegate = self
                
                descriptionTextView.text = newBridgeData["system_title"] ?? "Please provide a description...\n\nExample - This Sure-Fi Brigde is used to connect a 4-Door controller and keypad from XYZ Company"
                descriptionTextView.textColor = .black
                if newBridgeData["system_title"] == nil || newBridgeData["system_title"] == "" {
                    descriptionTextView.textColor = .gray
                }
                cell.accessoryType = .none
            }
            if indexPath.row == 1 {
                cell = tableView.dequeueReusableCell(withIdentifier: "CompleteCell", for: indexPath)
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        }
        return cell
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.text.range(of: "Please provide a description...") != nil {
            textView.text = ""
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        tableView.reloadData()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        if textView.text.length > 0 {
            textView.textColor = .black
        }
        
        let tempCell = textView.superview?.superview as? UITableViewCell
        if tempCell != nil {
         
            let indexPath = tableView.indexPath(for: tempCell!)
            if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 2 {
                newBridgeData["device_title_central"] = textView.text
                print("Central Title:\(newBridgeData["device_title_central"] ?? "")")
            }
            if indexPath != nil && indexPath!.section == 1 && indexPath!.row == 2 {
                newBridgeData["device_title_remote"] = textView.text
                print("Remote Title:\(newBridgeData["device_title_remote"] ?? "")")
            }
            if indexPath != nil && indexPath!.section == 2 && indexPath!.row == 0 {
                newBridgeData["system_title"] = textView.text
                print("System Title:\(newBridgeData["system_title"] ?? "")")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "BridgeSelectViewController") as! BridgeSelectViewController
            //controller.bridgePairTableViewController = self
            controller.bridgeRequiredStatus = "01"
            controller.bridgeDataField = "device_id_central"
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        if indexPath.section == 0 && indexPath.row == 1 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "BridgeImageViewController") as! BridgeImageViewController
            controller.bridgePairTableViewController = self
            controller.hardwareType = "central"
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        if indexPath.section == 1 && indexPath.row == 0  {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "BridgeSelectViewController") as! BridgeSelectViewController
            //controller.bridgePairTableViewController = self
            controller.bridgeRequiredStatus = "01"
            controller.bridgeDataField = "device_id_remote"
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        if indexPath.section == 1 && indexPath.row == 1 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "BridgeImageViewController") as! BridgeImageViewController
            controller.bridgePairTableViewController = self
            controller.hardwareType = "remote"
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    @IBAction func setupBridge (sender: UIButton) {
        
        let alert = UIAlertController(title: "Initiate Bridge Configuration", message: "Are you sure you are ready to initiate configurion of this Sure-Fi Bridge?", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Continue", style: .default, handler: continueSetup);
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func continueSetup(alert: UIAlertAction!) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let bridgePairingTableViewController = storyboard.instantiateViewController(withIdentifier: "BridgePairingTableViewController") as! BridgePairingTableViewController
        bridgePairingTableViewController.centralDeviceID = newBridgeData["device_id_central"]
        bridgePairingTableViewController.remoteDeviceID = newBridgeData["device_id_remote"]
        bridgePairingTableViewController.bridgePairTableViewController = self
        self.navigationController?.pushViewController(bridgePairingTableViewController, animated: true)
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
