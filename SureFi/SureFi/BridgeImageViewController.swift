//
//  BridgeImageViewController.swift
//  SureFi
//
//  Created by John Robinson on 6/8/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class BridgeImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var bridgePairTableViewController: BridgePairTableViewController!
    var hardwareType: String = ""
    
    @IBOutlet var exampleImageView1: UIImageView!
    @IBOutlet var exampleImageView2: UIImageView!
    @IBOutlet var exampleImageViewGood: UIImageView!
    @IBOutlet var deviceImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        exampleImageView1.layer.borderColor = UIColor.red.cgColor
        exampleImageView1.layer.borderWidth = 3
        exampleImageView1.layer.cornerRadius = 5
        exampleImageView1.clipsToBounds = true
        
        exampleImageView2.layer.borderColor = UIColor.red.cgColor
        exampleImageView2.layer.borderWidth = 3
        exampleImageView2.layer.cornerRadius = 5
        exampleImageView2.clipsToBounds = true

        exampleImageViewGood.layer.borderColor = UIColor.green.cgColor
        exampleImageViewGood.layer.borderWidth = 3
        exampleImageViewGood.layer.cornerRadius = 5
        exampleImageViewGood.clipsToBounds = true

        deviceImageView.layer.borderColor = UIColor.gray.cgColor
        deviceImageView.layer.borderWidth = 3
        deviceImageView.layer.cornerRadius = 5
        deviceImageView.clipsToBounds = true
        
        self.navigationItem.title = "Take Picture"
        let selectButton = UIBarButtonItem(title: "Use Image", style: .done, target: self, action: #selector(selectButtonPress(sender:)))
        selectButton.isEnabled = false
        self.navigationItem.rightBarButtonItem = selectButton
        // Do any additional setup after loading the view.
    }
    
    @IBAction func takePictureButtonPress(sender: UIButton) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func selectButtonPress(sender: UIBarButtonItem) {
        if hardwareType == "central" {
            bridgePairTableViewController.centralImage = deviceImageView.image
        } else if hardwareType == "remote" {
            bridgePairTableViewController.remoteImage = deviceImageView.image
        }
        bridgePairTableViewController.tableView.reloadData()
        self.navigationController?.pop(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info["UIImagePickerControllerEditedImage"] as? UIImage
        self.dismiss(animated: true, completion: nil)
        
        if image != nil {
            let selectButton = UIBarButtonItem(title: "Use Image", style: .done, target: self, action: #selector(selectButtonPress(sender:)))
            selectButton.isEnabled = true
            self.navigationItem.rightBarButtonItem = selectButton
            deviceImageView.image = image
        }
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
