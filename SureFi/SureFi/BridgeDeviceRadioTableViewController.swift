//
//  BridgeDeviceRadioTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 7/7/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class BridgeDeviceRadioTableViewController: UITableViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var sfBridgeController: SFBridgeController!
    
    var selectedSection = -1
    var selectedPower = -1
    var selectedSpreadingFactor = -1
    var selectedBandwidth = -1
    var selectedHeartbeat = -1
    var selectedRetry = -1
    var selectedAcks = -1
    
    let powerArray: [String] = ["1/8 Watt","1/4 Watt","1/2 Watt","1 Watt"]
    let spreadingFactorArray: [Int] = [7,8,9,10,11,12]
    let bandwidthArray: [Float] = [31.25,62.50,125,250,500]
    let heartbeatArray: [Int] = [0,15,30,60,90,120]
    let retryArray: [Int] = [0,1,2,3,4,5]
    let acksArray: [String] = ["Disabled","Enabled"]
    
    var timer: Timer!
    
    var radioSettingsDataString: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sfBridgeController = SFBridgeController.shared
        
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerTick(sender:)), userInfo: nil, repeats: true)
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = backgroundImageView
        
        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonPressed(sender:)))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.navigationItem.title = "Configure Radio"
    }
    
    func timerTick(sender: Timer) {
        if radioSettingsDataString != sfBridgeController.radioSettingsDataString {
            print("Radio Settings String Changed")
            radioSettingsDataString = sfBridgeController.radioSettingsDataString
            processRadioDataString()
        }
    }
    
    func processRadioDataString() {
        
        if radioSettingsDataString != "" {
            let spreadingFactor = Int(radioSettingsDataString.substring(from: 0).substring(to: 2).hexaToDecimal)
            let bandwidth       = Int(radioSettingsDataString.substring(from: 2).substring(to: 2).hexaToDecimal)
            let powerAmp        = Int(radioSettingsDataString.substring(from: 4).substring(to: 2).hexaToDecimal)
            let retryCount      = Int(radioSettingsDataString.substring(from: 6).substring(to: 2).hexaToDecimal)
            let heartbeat       = Int(radioSettingsDataString.substring(from: 8).substring(to: 2).hexaToDecimal)
            let acks            = Int(radioSettingsDataString.substring(from: 10).substring(to: 2).hexaToDecimal)
            
            selectedSpreadingFactor = spreadingFactor - 1
            selectedBandwidth = bandwidth - 1
            selectedPower = powerAmp - 1
            selectedRetry = retryArray.index(of: retryCount) ?? -1
            selectedHeartbeat = heartbeatArray.index(of: heartbeat) ?? -1
            selectedAcks = acks
            
            self.tableView.reloadData()
        }
    }
    
    @IBAction func saveButtonPressed(sender: UIBarButtonItem) {
        
        let spreadingFactorValue = UInt8(selectedSpreadingFactor + 1)
        let bandwidthValue = UInt8(selectedBandwidth + 1)
        let powerValue = UInt8(selectedPower + 1)
        let retryValue = UInt8(retryArray[selectedRetry])
        let heartbeatValue = UInt8(heartbeatArray[selectedHeartbeat])
        let acksValue = UInt8(selectedAcks)
        
        sfBridgeController.setRadioSettings(spreadingFactorValue: spreadingFactorValue, bandwidthValue: bandwidthValue, powerValue: powerValue, retryValue: retryValue, heartbeatValue: heartbeatValue, acksValue: acksValue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 6
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if selectedSection == section {
            if section == 0 {
                return powerArray.count + 1
            }
            if section == 1 {
                return spreadingFactorArray.count + 1
            }
            if section == 2 {
                return bandwidthArray.count + 1
            }
            if section == 3 {
                return retryArray.count + 1
            }
            if section == 4 {
                return heartbeatArray.count + 1
            }
            if section == 5 {
                return acksArray.count + 1
            }
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 22
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            cell.detailTextLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            if indexPath.section == 0 {
                cell.textLabel?.text = "Power"
                if selectedPower >= 0 {
                    cell.detailTextLabel?.text = powerArray[selectedPower]
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            }
            if indexPath.section == 1 {
                cell.textLabel?.text = "Spreading Factor"
                if selectedSpreadingFactor >= 0 {
                    cell.detailTextLabel?.text = "SF\(spreadingFactorArray[selectedSpreadingFactor])"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            }
            if indexPath.section == 2 {
                cell.textLabel?.text = "Bandwidth"
                if selectedBandwidth >= 0 {
                    cell.detailTextLabel?.text = "\(bandwidthArray[selectedBandwidth]) kHz"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            }
            if indexPath.section == 3 {
                cell.textLabel?.text = "Retry Count"
                if selectedRetry >= 0 {
                    cell.detailTextLabel?.text = "\(retryArray[selectedRetry])"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            }
            if indexPath.section == 4 {
                cell.textLabel?.text = "Heartbeat Period"
                if selectedHeartbeat >= 0 {
                    cell.detailTextLabel?.text = "\(heartbeatArray[selectedHeartbeat]) sec"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            }
            if indexPath.section == 5 {
                cell.textLabel?.text = "Acknowledments"
                if selectedAcks >= 0 {
                    cell.detailTextLabel?.text = "\(acksArray[selectedAcks])"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            }
            cell.accessoryType = .disclosureIndicator
            
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
            
            if indexPath.section == 0 {
                cell.textLabel?.text = powerArray[indexPath.row - 1]
                if selectedPower == indexPath.row - 1 {
                    cell.imageView?.image = UIImage(named: "check")
                } else {
                    cell.imageView?.image = UIImage(named: "check_spacer")
                }
            }
            if indexPath.section == 1 {
                cell.textLabel?.text = "SF\(spreadingFactorArray[indexPath.row - 1])"
                if selectedSpreadingFactor == indexPath.row - 1 {
                    cell.imageView?.image = UIImage(named: "check")
                } else {
                    cell.imageView?.image = UIImage(named: "check_spacer")
                }
            }
            if indexPath.section == 2 {
                cell.textLabel?.text = "\(bandwidthArray[indexPath.row - 1]) kHz"
                if selectedBandwidth == indexPath.row - 1 {
                    cell.imageView?.image = UIImage(named: "check")
                } else {
                    cell.imageView?.image = UIImage(named: "check_spacer")
                }
            }
            if indexPath.section == 3 {
                cell.textLabel?.text = "\(retryArray[indexPath.row - 1])"
                if selectedRetry == indexPath.row - 1 {
                    cell.imageView?.image = UIImage(named: "check")
                } else {
                    cell.imageView?.image = UIImage(named: "check_spacer")
                }
            }
            if indexPath.section == 4 {
                cell.textLabel?.text = "\(heartbeatArray[indexPath.row - 1]) sec"
                if selectedHeartbeat == indexPath.row - 1 {
                    cell.imageView?.image = UIImage(named: "check")
                } else {
                    cell.imageView?.image = UIImage(named: "check_spacer")
                }
            }
            if indexPath.section == 5 {
                cell.textLabel?.text = "\(acksArray[indexPath.row - 1])"
                if selectedAcks == indexPath.row - 1 {
                    cell.imageView?.image = UIImage(named: "check")
                } else {
                    cell.imageView?.image = UIImage(named: "check_spacer")
                }
            }
        }
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            if indexPath.section == selectedSection {
                selectedSection = -1
            } else {
                selectedSection = indexPath.section
            }
        } else {
            if indexPath.section == 0 {
                selectedPower = indexPath.row - 1
            }
            if indexPath.section == 1 {
                selectedSpreadingFactor = indexPath.row - 1
            }
            if indexPath.section == 2 {
                selectedBandwidth = indexPath.row - 1
            }
            if indexPath.section == 3 {
                selectedRetry = indexPath.row - 1
            }
            if indexPath.section == 4 {
                selectedHeartbeat = indexPath.row - 1
            }
            if indexPath.section == 5 {
                selectedAcks = indexPath.row - 1
            }
        }
        
        self.tableView.reloadData()
    }
    
}

