//
//  BridgeTextViewController.swift
//  SureFi
//
//  Created by John Robinson on 6/9/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class BridgeTextViewController: UIViewController {

    var bridgePairTableViewController: BridgePairTableViewController!
    var navTitle: String!
    var fieldTitle: String!
    var fieldName: String!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = navTitle
        titleLabel.text = fieldTitle
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        
        textField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func back(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        bridgePairTableViewController.setBridgeDataValue(field: fieldName, value: textField.text!)
        bridgePairTableViewController.tableView.reloadData()
        _ = navigationController?.popViewController(animated: true)
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
