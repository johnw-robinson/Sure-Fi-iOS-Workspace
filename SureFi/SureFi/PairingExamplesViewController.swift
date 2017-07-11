//
//  PairingExamplesViewController.swift
//  SureFi
//
//  Created by John Robinson on 6/15/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class PairingExamplesViewController: UIViewController {

    @IBOutlet var exampleImageView1: UIImageView!
    @IBOutlet var exampleImageView2: UIImageView!
    @IBOutlet var exampleImageViewGood: UIImageView!

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
