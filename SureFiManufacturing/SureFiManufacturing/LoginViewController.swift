//
//  LoginViewController.swift
//  SureFiManufacturing
//
//  Created by John Robinson on 6/20/17.
//  Copyright © 2017 Sure-Fi. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var launchImageView: UIImageView!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var loginContainerView: UIView!
    
    @IBOutlet var loginUsername: UITextField!
    @IBOutlet var loginPassword: UITextField!
    @IBOutlet var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        let accountImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        accountImage.image = UIImage(named: "login_account_image")
        loginUsername.leftView = paddingView;
        loginUsername.leftViewMode = .always
        loginUsername.addSubview(accountImage)
        
        paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        let passwordImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        passwordImage.image = UIImage(named: "login_password_image")
        loginPassword.leftView = paddingView
        loginPassword.leftViewMode = .always
        loginPassword.addSubview(passwordImage)
        
        self.loginContainerView.alpha = 0
        UIView.animate(withDuration: 0.5) {
            
            self.launchImageView.alpha = 0
            self.loginContainerView.alpha = 1
            self.backgroundImageView.alpha = 1
            
            
        }
    
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonPress(sender: UIButton) {
        
        sender.setTitle("Logging In...", for: .normal)
        sender.setTitleColor(UIColor.gray, for: .normal)
        sender.isEnabled = false
        
        let loginData = NSMutableDictionary()
        loginData.setValue(loginUsername.text ?? "", forKey: "user_login")
        loginData.setValue(loginPassword.text ?? "", forKey: "user_password")
        appDelegate.sessionController.postServerRequest(action: "users/login", postData: loginData, urlData:"", callback: self.userLoginCallback)
    }
    
    func userLoginCallback(result: Data) {
        
        let (status,msg,data) = appDelegate.sessionController.processResultData(resultData: result, viewController: self)
        DispatchQueue.main.async {
            if status {
                
                self.appDelegate.userData = data.object(forKey: "user_data") as? NSMutableDictionary ?? NSMutableDictionary()
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
                self.present(controller, animated: true, completion: nil)
            }
            else
            {
                self.loginButton.setTitle("Log In", for: .normal)
                self.loginButton.setTitleColor(UIColor(rgb: 0x21ABDC), for: .normal)
                self.loginButton.isEnabled = true
                
                
                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

}
