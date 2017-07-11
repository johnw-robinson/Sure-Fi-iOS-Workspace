//
//  RegisterTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 6/13/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import Messages
import MessageUI
import Contacts

class RegisterTableViewController: UITableViewController, MFMessageComposeViewControllerDelegate, UITextFieldDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var mainViewController: MainViewController!
    
    var timer: Timer = Timer()
    var messageSent: Bool = false
    var activationCodeLoaded: Bool = false
    var contactsSearched: Bool = false
    var displayArea = -1
    
    var showStep1 = false
    var showStep2 = false
    var showStep3 = false
    var showStep4 = false
    var requireStep3b: Bool = true
    
    var contactName = ""
    var contactEmail = ""
    
    var primaryContact: CNContact = CNContact()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.tableView.separatorStyle = .none
        self.tableView.separatorInset = .zero
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkRegistrationStatus), userInfo: nil, repeats: true)
    
        appDelegate.checkAccessStatus(completionHandler: { (accessGranted) -> Void in
            
            
            
            
            
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("Text Field Should Return")
        return true
    }
    
    @IBAction func sendSMSToSureFi(sender: UIButton) {
        
        DispatchQueue.main.async {
            let messageVC = MFMessageComposeViewController()
            messageVC.body = "Please send the following Registration Code to SureFi: {\(self.appDelegate.deviceNotificationToken)}";
            messageVC.recipients = ["14804007873"]
            messageVC.messageComposeDelegate = self;
            self.present(messageVC, animated: false, completion: nil)
       }
        
    }
    
    @IBAction func updateActivationCode(sender: UITextField) {
        
        print("Box:\(sender.tag): \(sender.text!)")
        if (sender.text?.length)! >= 1 {
            sender.text = sender.text?.substring(to: 1).digits
        }
        
        var codeDigits: [String] = [" "," "," "," "]
        codeDigits[0] = appDelegate.activationCode.substring(from: 0).substring(to: 1)
        codeDigits[1] = appDelegate.activationCode.substring(from: 1).substring(to: 1)
        codeDigits[2] = appDelegate.activationCode.substring(from: 2).substring(to: 1)
        codeDigits[3] = appDelegate.activationCode.substring(from: 3).substring(to: 1)
        codeDigits[sender.tag - 1] = sender.text ?? " "
        
        appDelegate.activationCode = codeDigits.joined()
        print("Activation Code:\(appDelegate.activationCode)")
        if appDelegate.activationCode.length == 4 {
            if showStep4 == false {
                self.tableView.reloadData()
                showStep4 = true
            }
        } else {
            if showStep4 == true {
                self.tableView.reloadData()
                showStep4 = false
            }
        }
    }
    
    @IBAction func updateContactName(sender: UITextField) {
        
        contactName = sender.text ?? ""
        
    }
    
    @IBAction func updateContactEmail(sender: UITextField) {
        
        contactEmail = sender.text ?? ""
        
    }
    
    func checkRegistrationStatus(sender: Timer) {
        
        var reloadTable = false
        if appDelegate.isRegistered {
            sender.invalidate()
            appDelegate.sessionController.startSession(callback: mainViewController.startSessionCallback(result:))
            self.navigationController?.pop(animated: true)
        } else if appDelegate.checkedRegistration {
            
            if showStep1 == false {
                reloadTable = true
                showStep1 = true
            }
            
            if messageSent {
                
                if showStep2 == false {
                    reloadTable = true
                    showStep2 = true
                }
                
                if appDelegate.activationCode.length == 4 {
                    
                    if activationCodeLoaded == false {
                        
                        reloadTable = true
                        activationCodeLoaded = true
                    }
                    
                    if showStep3 == false {
                        reloadTable = true
                        showStep3 = true
                    }
                    
                    if appDelegate.devicePhoneNumber != "" && self.contactsSearched == false {
                        
                        if appDelegate.contacts != nil {
                            print("You have \(appDelegate.contacts.count) contacts")
                            for contact in appDelegate.contacts {
                                
                                let phoneNumbers = contact.phoneNumbers
                                
                                for phoneNumber in phoneNumbers {
                                    
                                    let phoneNumberString = phoneNumber.value.stringValue.digits
                                    if appDelegate.devicePhoneNumber == phoneNumberString {
                                        primaryContact = contact
                                        contactName = "\(contact.givenName) \(contact.familyName)"
                                        reloadTable = true
                                        requireStep3b = false
                                    }
                                }
                            }
                        }
                        self.contactsSearched = true
                    }
                    
                    
                    if contactName != "" && (!requireStep3b || contactEmail != "") {
                        if showStep4 == false {
                            reloadTable = true
                            showStep4 = true
                        }
                    } else {
                        if showStep4 == true {
                            reloadTable = true
                            showStep4 = false
                        }
                    }
                } else {
                    if showStep3 == true {
                        reloadTable = true
                        showStep3 = false
                    }
                }
            } else {
                if showStep2 == true {
                    reloadTable = true
                    showStep2 = false
                }
            }
        } else {
            if showStep1 == true {
                reloadTable = true
                showStep1 = false
            }
        }
        if reloadTable {
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showStep4 {
            if requireStep3b {
                return 6
            }
            return 5
        } else if showStep3 {
            if requireStep3b {
                return 5
            }
            return 4
        } else if showStep2 {
            return 3
        } else if showStep1 {
            return 2
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 0 {
            return 108
        } else if indexPath.row == 1 {
            return 80
        } else if indexPath.row == 2 {
            return 112
        } else if indexPath.row == 3 || (indexPath.row == 4 && requireStep3b) {
            return 104
        } else if indexPath.row == 4 || (indexPath.row == 5 && requireStep3b) {
            return 56
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath)
        }
        else if indexPath.row == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Step1Cell", for: indexPath)
        }
        else if indexPath.row == 2 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Step2Cell", for: indexPath)
            let step2Code1 = cell.viewWithTag(1) as! UITextField
            let step2Code2 = cell.viewWithTag(2) as! UITextField
            let step2Code3 = cell.viewWithTag(3) as! UITextField
            let step2Code4 = cell.viewWithTag(4) as! UITextField
            
            step2Code1.addTarget(self, action: #selector(updateActivationCode(sender:)), for: .allEditingEvents)
            step2Code2.addTarget(self, action: #selector(updateActivationCode(sender:)), for: .allEditingEvents)
            step2Code3.addTarget(self, action: #selector(updateActivationCode(sender:)), for: .allEditingEvents)
            step2Code4.addTarget(self, action: #selector(updateActivationCode(sender:)), for: .allEditingEvents)
            
            if appDelegate.activationCode.length == 4 {
                step2Code1.text = appDelegate.activationCode.substring(from: 0).substring(to: 1)
                step2Code2.text = appDelegate.activationCode.substring(from: 1).substring(to: 1)
                step2Code3.text = appDelegate.activationCode.substring(from: 2).substring(to: 1)
                step2Code4.text = appDelegate.activationCode.substring(from: 3).substring(to: 1)
            }
            
        }
        else if indexPath.row == 3 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Step3Cell", for: indexPath)
            let step3NameField = cell.viewWithTag(100) as! UITextField
            step3NameField.addTarget(self, action: #selector(updateContactName(sender:)), for: .allEditingEvents)
            step3NameField.text = contactName
        }
        else if indexPath.row == 4 && requireStep3b {
            cell = tableView.dequeueReusableCell(withIdentifier: "Step3bCell", for: indexPath)
            let step3NameField = cell.viewWithTag(100) as! UITextField
            step3NameField.addTarget(self, action: #selector(updateContactEmail(sender:)), for: .allEditingEvents)
            step3NameField.text = contactEmail
        }
        else if indexPath.row == 4 || (indexPath.row == 5 && requireStep3b) {
            cell = tableView.dequeueReusableCell(withIdentifier: "Step4Cell", for: indexPath)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        print("Result:\(result)")
        if result == MessageComposeResult.sent {
            messageSent = true
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmRegistrationButtonPress(sender: UIButton) {
        
        print(primaryContact)
        let emailAddresses = primaryContact.emailAddresses
        
        for emailAddress in emailAddresses {
            contactEmail = emailAddress.value as String
        }
        let deviceDictionary = appDelegate.deviceDictionary
        deviceDictionary.setValue(appDelegate.activationCode, forKey: "activation_code")
        deviceDictionary.setValue(contactName, forKey: "user_name")
        deviceDictionary.setValue(contactEmail, forKey: "user_email")
        SessionController().postServerRequest(action: "users/check_exists", postData: deviceDictionary, urlData:"", callback: self.checkUserExistsCallback)
    }
    
    func checkUserExistsCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        if status {
            let deviceDictionary = appDelegate.deviceDictionary
            var userID = String(data.object(forKey: "user_id") as? Int ?? -1)
            if userID == "-1" {
                userID = data.object(forKey: "user_id") as? String ?? ""
            }
            deviceDictionary.setValue(appDelegate.activationCode, forKey: "activation_code")
            deviceDictionary.setValue(userID, forKey: "user_id")
            SessionController().postServerRequest(action: "sessions/confirm_device_registration", postData: deviceDictionary, urlData:"", callback: self.confirmDeviceRegistrationCallback)
        } else {
            DispatchQueue.main.async {
                
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func confirmDeviceRegistrationCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        if status {
            print(data)
            appDelegate.isRegistered = true
        } else {
            DispatchQueue.main.async {
                
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
