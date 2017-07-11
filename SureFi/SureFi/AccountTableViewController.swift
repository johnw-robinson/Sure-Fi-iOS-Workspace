//
//  AccountTableViewController.swift
//  SureFi
//
//  Created by John Robinson on 6/6/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class AccountTableViewController: UITableViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var userLogin: UITextField!
    @IBOutlet var userPass: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = " Your Sure-Fi Account"
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

        if appDelegate.userData.count != 0 {
            return 1
        }
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if appDelegate.userData.count != 0 {
            return 0
        } else {
            return 3
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if appDelegate.userData.count == 0 {
            return 76
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if appDelegate.userData.count == 0 {
            return "User Login"
        } else {
            
            if section == 0 {
                return "Account Information"
            }
            if section == 1 {
                return "Account Systems"
            }
            
        }
        
        return ""
        
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if appDelegate.userData.count == 0 {
            
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "LoginCell", for: indexPath)
                userLogin = cell.viewWithTag(100) as! UITextField
                userLogin.placeholder = "Email Address"
                userLogin.isSecureTextEntry = false
                
                let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
                let accountImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
                accountImage.image = UIImage(named: "login_account_image")
                userLogin.leftView = paddingView;
                userLogin.leftViewMode = .always
                userLogin.addSubview(accountImage)
            }
            if indexPath.row == 1 {
                cell = tableView.dequeueReusableCell(withIdentifier: "LoginCell", for: indexPath)
                userPass = cell.viewWithTag(100) as! UITextField
                userPass.placeholder = "Password"
                userPass.isSecureTextEntry = true
                
                let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
                let passwordImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
                passwordImage.image = UIImage(named: "login_password_image")
                userPass.leftView = paddingView
                userPass.leftViewMode = .always
                userPass.addSubview(passwordImage)
            }
            if indexPath.row == 2 {
                cell = tableView.dequeueReusableCell(withIdentifier: "LoginButtonCell", for: indexPath)
                let loginButton: UIButton = cell.viewWithTag(100) as! UIButton
                loginButton.setTitle("Log In", for: .normal)
                loginButton.addTarget(self, action: #selector(loginButtonPress(sender:)), for: .touchUpInside)
            }
            cell.selectionStyle = .none
            tableView.separatorStyle = .none
        }

        // Configure the cell...

        return cell
    }
    
    @IBAction func loginButtonPress(sender: UIButton) {

        let loginData = NSMutableDictionary()
        loginData.setValue(userLogin.text ?? "", forKey: "user_login")
        loginData.setValue(userPass.text ?? "", forKey: "user_password")
        appDelegate.sessionController.postServerRequest(action: "users/login", postData: loginData, urlData:"", callback: self.userLoginCallback)
    }
    
    func userLoginCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                
                self.appDelegate.userData = data.object(forKey: "userData") as? NSMutableDictionary ?? NSMutableDictionary()
                self.tableView.reloadData()
                
            }
            else
            {
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
