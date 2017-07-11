//
//  BridgeMenuCollectionViewController.swift
//  SureFiManufacturing
//
//  Created by John Robinson on 6/20/17.
//  Copyright © 2017 Sure-Fi. All rights reserved.
//

import UIKit

class ACBG2MenuCollectionViewController: UICollectionViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.titleView = UIImageView(image:UIImage(named: "SureFiManufacturingNavImage"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath)
    
        let imageView: UIImageView = cell.viewWithTag(100) as! UIImageView
        let titleLabel: UILabel = cell.viewWithTag(200) as! UILabel
        
        if indexPath.row == 0 {
            imageView.image = UIImage(named: "menu_serials")
            titleLabel.text = "Request Serial Numbers"
        }
        if indexPath.row == 1 {
            imageView.image = UIImage(named: "menu_flash_serial")
            titleLabel.text = "Flash Serial"
        }
        if indexPath.row == 2 {
            imageView.image = UIImage(named: "menu_flash_firmware")
            titleLabel.text = "Update Firmware"
        }
        if indexPath.row == 3 {
            imageView.image = UIImage(named: "menu_radio_settings")
            titleLabel.text = "Confgure Radio Settings"
        }
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 0 && indexPath.row == 1 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "ACBG2FlashSerialViewController") as! ACBG2FlashSerialViewController
            self.navigationController?.pushViewController(controller, animated: true)
        }
        if indexPath.section == 0 && indexPath.row == 2 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "ACBG2UpdateFirmwareTableViewController") as! ACBG2UpdateFirmwareTableViewController
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
}
