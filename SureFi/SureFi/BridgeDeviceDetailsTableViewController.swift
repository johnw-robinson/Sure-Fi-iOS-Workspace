//
//  BridgeDeviceDetailsTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 7/6/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreBluetooth

class BridgeDeviceDetailsTableViewController: UITableViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var bridgeStartViewController:BridgeStartViewController!
    var sfBridgeController: SFBridgeController!

    var timer: Timer!
    
    var currentAppFirmwareVersion = ""
    var currentRadioFirmwareVersion = ""
    var currentBTFirmwareVersion = ""
    
    var hardwareType: String = ""
    var hardwareStatus: String = ""
    
    var currentDeviceState: CBPeripheralState!
    var currentDeviceStatus: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sfBridgeController = SFBridgeController.shared
        currentDeviceState = sfBridgeController.devicePeripheral.state
        
        let backgroundImageView = UIImageView(image:UIImage(named:"temp_background"))
        backgroundImageView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = backgroundImageView
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerTick(sender:)), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func timerTick(sender: Timer) {
        
        var reloadTable = false
        if sfBridgeController.devicePeripheral == nil {
            currentDeviceState = nil
            reloadTable = true
        }
        else if sfBridgeController.devicePeripheral.state != currentDeviceState {
            let newState = sfBridgeController.devicePeripheral.state
            
            switch newState {
            case .connected:
                print("Connected")
                break
            case .connecting:
                print("Connecting")
                break
            case .disconnected:
                print("Disconnected")
                break
            case .disconnecting:
                print("Disconnecting")
                break
            default:
                print("Unknown")
                break
            }
            currentDeviceState = newState
            reloadTable = true
        }
        
        if sfBridgeController.selectedDeviceStatus != currentDeviceStatus {
            currentDeviceStatus = sfBridgeController.selectedDeviceStatus
            reloadTable = true
        }
        if sfBridgeController.appFirmwareDataString != currentAppFirmwareVersion {
            currentAppFirmwareVersion = sfBridgeController.appFirmwareDataString
            reloadTable = true
        }
        if sfBridgeController.radioFirmwareDataString != currentRadioFirmwareVersion {
            currentRadioFirmwareVersion = sfBridgeController.radioFirmwareDataString
            reloadTable = true
        }
        if sfBridgeController.btFirmwareDataString != currentBTFirmwareVersion {
            currentBTFirmwareVersion = sfBridgeController.btFirmwareDataString
            reloadTable = true
        }
        
        if reloadTable {
            self.tableView.reloadData()
            self.tableView.setNeedsDisplay()
        }
    }
    
    @IBAction func connectButtonPress(sender: UIButton) {
        
        if currentDeviceState == .connected {
            sfBridgeController.disconnectDevice()
        }
        else if currentDeviceState == .disconnected {
            sfBridgeController.connectDevice()
        }
        
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if sfBridgeController.devicePeripheral.state == .connected {
            return 5
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        if section == 1 {
            
            switch currentDeviceStatus {
            case "00":
                return 1
            case "01":
                return 3
            case "02":
                return 1
            case "03":
                return 4
            case "04":
                return 3
            default:
                return 0
            }
            
        }
        
        if section == 2 {
            return 3
        }
        if section == 3 {
            return 3
        }
        if section == 4 {
            return 2
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            return 80
        }
        
        if indexPath.section == 1 {
            return 80
        }
        
        return 44
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 1 {
            return "Available Options"
        }
        if section == 2 {
            return "Current Firmware Versions"
        }
        if section == 3 {
            return "Current Radio Settings"
        }
        if section == 4 {
            return "Current Power Values"
        }
        return ""
        
    }
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textAlignment = .center
        header.textLabel?.textColor = .darkGray
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeviceDetailsCell", for: indexPath)
                let tempImageView = cell.viewWithTag(100) as! UIImageView
                let tempTitleLabel = cell.viewWithTag(200) as! UILabel
                let tempDetailLabel = cell.viewWithTag(300) as! UILabel
                
                let manufacturerDataString = sfBridgeController.deviceManufacturerDataString!
                hardwareType = manufacturerDataString.substring(from: 4).substring(to: 2)
                hardwareStatus = manufacturerDataString.substring(from: 10).substring(to: 2)
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
                    currentDeviceStatus = "00"
                }
                
                switch currentDeviceStatus {
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
                
                tempTitleLabel.text = "\(sfBridgeController.devicePeripheral.name!) - \(sfBridgeController.selectedDeviceID.uppercased())"
                tempDetailLabel.text = detailsString
            }
            if indexPath.row == 1 {
                cell = tableView.dequeueReusableCell(withIdentifier: "DeviceStatusCell", for: indexPath)
                let statusLabel = cell.viewWithTag(100) as! UILabel
                let connectButton = cell.viewWithTag(200) as! UIButton
                connectButton.layer.cornerRadius = 10
                connectButton.clipsToBounds = true
                statusLabel.layer.cornerRadius = 10
                statusLabel.clipsToBounds = true
                
                switch currentDeviceState {
                case .connected:
                    statusLabel.text = "Status: Connected"
                    statusLabel.textColor = UIColor(rgb: 0x009900)
                    
                    connectButton.setTitle("Disconnect", for: .normal)
                    connectButton.backgroundColor = .darkGray
                    connectButton.isEnabled = true
                    break
                case .connecting:
                    statusLabel.text = "Status: Connecting"
                    statusLabel.textColor = .orange
                    
                    connectButton.setTitle("Connecting...", for: .normal)
                    connectButton.backgroundColor = .orange
                    connectButton.isEnabled = false
                    break
                case .disconnected:
                    statusLabel.text = "Status: Disconnected"
                    statusLabel.textColor = UIColor(rgb: 0x990000)
                    
                    connectButton.setTitle("Connect", for: .normal)
                    connectButton.backgroundColor = UIColor(rgb: 0x009900)
                    connectButton.isEnabled = true
                    break
                case .disconnecting:
                    statusLabel.text = "Status: Disconnecting"
                    statusLabel.textColor = .orange

                    connectButton.setTitle("Disconnecting...", for: .normal)
                    connectButton.backgroundColor = .orange
                    connectButton.isEnabled = false
                    break
                default:
                    statusLabel.text = "Status: Unknown"
                    break
                }
            }
        }
        if indexPath.section == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
            let tempImageView = cell.viewWithTag(100) as! UIImageView
            let tempTitleLabel = cell.viewWithTag(200) as! UILabel
            
            if indexPath.row == 0 {
                switch currentDeviceStatus {
                case "00":
                    tempImageView.image = UIImage(named: "menu_flash_serial")
                    tempTitleLabel.text = "Register Serials"
                case "01":
                    tempImageView.image = UIImage(named: "menu_pair")
                    tempTitleLabel.text = "Pair Bridge"
                case "02":
                    tempImageView.image = UIImage(named: "")
                    tempTitleLabel.text = "No Options Available"
                case "03":
                    tempImageView.image = UIImage(named: "menu_deploy")
                    tempTitleLabel.text = "Deploy Bridge"
                case "04":
                    tempImageView.image = UIImage(named: "menu_unpair")
                    tempTitleLabel.text = "Unpair Bridge"
                default:
                    tempImageView.image = nil
                    tempTitleLabel.text = ""
                }
            }
            if indexPath.row == 1 {
                switch currentDeviceStatus {
                case "00":
                    tempImageView.image = UIImage(named: "")
                    tempTitleLabel.text = "No Options Available"
                case "01":
                    tempImageView.image = UIImage(named: "menu_flash_firmware")
                    tempTitleLabel.text = "Update Firmware"
                case "02":
                    tempImageView.image = UIImage(named: "")
                    tempTitleLabel.text = "No Options Available"
                case "03":
                    tempImageView.image = UIImage(named: "menu_unpair")
                    tempTitleLabel.text = "Unpair Bridge"
                case "04":
                    tempImageView.image = UIImage(named: "menu_flash_firmware")
                    tempTitleLabel.text = "Update Firmware"
                default:
                    tempImageView.image = nil
                    tempTitleLabel.text = ""
                }
            }
            if indexPath.row == 2 {
                switch currentDeviceStatus {
                case "00":
                    tempImageView.image = UIImage(named: "")
                    tempTitleLabel.text = "No Options Available"
                case "01":
                    tempImageView.image = UIImage(named: "menu_radio_settings")
                    tempTitleLabel.text = "Configure Radio"
                case "02":
                    tempImageView.image = UIImage(named: "")
                    tempTitleLabel.text = "No Options Available"
                case "03":
                    tempImageView.image = UIImage(named: "flash_firmware_icon")
                    tempTitleLabel.text = "Update Firmware"
                case "04":
                    tempImageView.image = UIImage(named: "menu_radio_settings")
                    tempTitleLabel.text = "Configure Radio"
                default:
                    tempImageView.image = nil
                    tempTitleLabel.text = "No Options Available"
                }
            }
            if indexPath.row == 3 {
                switch currentDeviceStatus {
                case "00":
                    tempImageView.image = UIImage(named: "")
                    tempTitleLabel.text = "No Options Available"
                case "01":
                    tempImageView.image = UIImage(named: "")
                    tempTitleLabel.text = "No Options Available"
                case "02":
                    tempImageView.image = UIImage(named: "")
                    tempTitleLabel.text = "No Options Available"
                case "03":
                    tempImageView.image = UIImage(named: "menu_radio_settings")
                    tempTitleLabel.text = "Configure Radio"
                case "04":
                    tempImageView.image = UIImage(named: "")
                    tempTitleLabel.text = "No Options Available"
                default:
                    tempImageView.image = nil
                    tempTitleLabel.text = "No Options Available"
                }
            }
            
        }
        if indexPath.section == 2 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "FirmwareDetailsCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            if indexPath.row == 0 {
                cell.textLabel?.text = "Application"
                cell.detailTextLabel?.text = sfBridgeController.appFirmwareDataString
            }
            if indexPath.row == 1 {
                cell.textLabel?.text = "Radio"
                cell.detailTextLabel?.text = sfBridgeController.radioFirmwareDataString
            }
            if indexPath.row == 2 {
                cell.textLabel?.text = "Bluetooth"
                cell.detailTextLabel?.text = sfBridgeController.btFirmwareDataString
            }
        }
        if indexPath.section == 3 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "FirmwareDetailsCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            if indexPath.row == 0 {
                cell.textLabel?.text = "Spreading Factor"
                cell.detailTextLabel?.text = sfBridgeController.selectedDeviceSF
            }
            if indexPath.row == 1 {
                cell.textLabel?.text = "Bandwidth"
                cell.detailTextLabel?.text = sfBridgeController.selectedDeviceBandwidth
            }
            if indexPath.row == 2 {
                cell.textLabel?.text = "Power"
                cell.detailTextLabel?.text = sfBridgeController.selectedDevicePower
            }
        }
        if indexPath.section == 4 {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "FirmwareDetailsCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            if indexPath.row == 0 {
                cell.textLabel?.text = "Power Voltage"
                cell.detailTextLabel?.text = "\(sfBridgeController.selectedDeviceVoltagePwr) volts"
            }
            if indexPath.row == 1 {
                cell.textLabel?.text = "Battery Voltage"
                cell.detailTextLabel?.text = "\(sfBridgeController.selectedDeviceVoltageBat) volts"
            }
        }
        
        
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if indexPath.section == 1 {
            
            if indexPath.row == 0 {
                switch currentDeviceStatus {
                case "00":
                    return
                case "01":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDevicePairTableViewController") as! BridgeDevicePairTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                case "02":
                    return
                case "03":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceDeployTableViewController") as! BridgeDeviceDeployTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                case "04":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceUnpairTableViewController") as! BridgeDeviceUnpairTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                default:
                    return
                }
            }
            if indexPath.row == 1 {
                switch currentDeviceStatus {
                case "00":
                    return
                case "01":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceFirmwareTableViewController") as! BridgeDeviceFirmwareTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                case "02":
                    return
                case "03":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceUnpairTableViewController") as! BridgeDeviceUnpairTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                case "04":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceFirmwareTableViewController") as! BridgeDeviceFirmwareTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                default:
                    return
                }
            }
            if indexPath.row == 2 {
                switch currentDeviceStatus {
                case "00":
                    return
                case "01":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceRadioTableViewController") as! BridgeDeviceRadioTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                case "02":
                    return
                case "03":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceFirmwareTableViewController") as! BridgeDeviceFirmwareTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                case "04":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceRadioTableViewController") as! BridgeDeviceRadioTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                default:
                    return
                }
            }
            if indexPath.row == 3 {
                switch currentDeviceStatus {
                case "00":
                    return
                case "01":
                    return
                case "02":
                    return
                case "03":
                    let controller = storyboard.instantiateViewController(withIdentifier: "BridgeDeviceRadioTableViewController") as! BridgeDeviceRadioTableViewController
                    self.navigationController?.pushViewController(controller, animated: true)
                case "04":
                    return
                default:
                    return
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        timer.invalidate()
        
    }
}
