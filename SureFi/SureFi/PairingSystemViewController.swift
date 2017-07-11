//
//  PairingSystemViewController.swift
//  SureFi
//
//  Created by John Robinson on 6/15/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class PairingSystemViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var pairingTableViewController: PairingTableViewController!
    
    @IBOutlet var systemDescTextView: UITextView!
    @IBOutlet var continueButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Step 3 - Bridge Details"
 
        systemDescTextView.layer.borderColor = UIColor.gray.cgColor
        systemDescTextView.layer.borderWidth = 0.5
        systemDescTextView.text = "Please provide a description...\n\nExample - Front Door of Main Building"
        systemDescTextView.textColor = .gray

        // Do any additional setup after loading the view.
    }

    @IBAction func continueButtonPress (sender: UIButton) {
        
        let alert = UIAlertController(title: "Initiate Bridge Pairing", message: "Are you sure you are ready to initiate pairing of this Sure-Fi Bridge?", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Continue", style: .default, handler: continueSetup);
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func continueSetup(alert: UIAlertAction!) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let bridgePairingTableViewController = storyboard.instantiateViewController(withIdentifier: "BridgePairingTableViewController") as! BridgePairingTableViewController
        bridgePairingTableViewController.centralDeviceID = pairingTableViewController.centralDeviceID
        bridgePairingTableViewController.remoteDeviceID = pairingTableViewController.remoteDeviceID
        bridgePairingTableViewController.pairingSystemViewController = self
        self.navigationController?.pushViewController(bridgePairingTableViewController, animated: true)
    
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.text.range(of: "Please provide a description...") != nil {
            textView.text = ""
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        var text = systemDescTextView.text
        if text?.range(of: "Please provide a description...") != nil {
            text = ""
        }
        
        if text != "" {
            continueButton.isHidden = false
        } else {
            continueButton.isHidden = true
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
