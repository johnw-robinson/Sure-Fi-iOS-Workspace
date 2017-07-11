//
//  MainViewController.swift
//  SureFi
//
//  Created by John Robinson on 3/16/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, iCarouselDataSource, iCarouselDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var loaded: Bool = false
    var hideBar: Bool = true
    var items: [Int] = []
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerImageView: UIImageView!
    @IBOutlet var carousel: iCarousel!
    
    override func viewDidLoad() {
        
        let viewWidth = self.view.frame.width
        let viewHeight = self.view.frame.height
        
        let headerViewFrame = CGRect(x: 0 - (viewHeight - (viewWidth / 2)) , y: 0 - viewHeight, width: viewHeight * 2, height:  viewHeight * 2)
        headerView.frame = headerViewFrame
        headerView.clipsToBounds = true
        
        for i in 0 ... 3 {
            items.append(i)
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "RegisterTableViewController") as! RegisterTableViewController
        controller.mainViewController = self
        self.navigationController?.pushViewController(controller, animated: false)
        
        
        carousel.type = .rotary
        carousel.reloadData()
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if loaded == false {
            UIView.animate(withDuration: 1.0, animations: {
                
                let viewWidth = self.view.frame.width
                let viewHeight = self.view.frame.height
                
                let headerViewFrame = CGRect(x: 0 - (viewHeight - (viewWidth / 2)) , y: 0 - ((viewHeight * 2) - 40), width: viewHeight * 2, height:  viewHeight * 2)
                self.headerView.frame = headerViewFrame
                self.headerView.layer.cornerRadius = viewHeight
                self.headerView.clipsToBounds = true
                self.headerImageView.alpha = 0
                
            } , completion: { (finished: Bool) in
                
                self.navigationItem.titleView = UIImageView(image: UIImage(named: "sure-fi_menu"))
                
            })
            loaded = true
        }
    }
    
    func startSessionCallback(result: Bool) {
        DispatchQueue.main.async {
            if !result {
                let alertController = UIAlertController(title: "Server Error", message: "There is an issue starting a secure session with the Sure-Fi Server. Please ensure you have an active internet connection, close the App and try again. If the problem persists, please contact Sure-Fi Support.", preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return items.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        var itemView: UIView
        var itemImage: UIImageView
        
        if view != nil {
            itemView = view ?? UIView()
            //get a reference to the label in the recycled view
            itemImage = itemView.viewWithTag(2) as! UIImageView
            label = itemView.viewWithTag(1) as! UILabel
        } else {
            itemView = UIView(frame: CGRect(x: 0, y: 0, width: 256, height: 384))
            
            label = UILabel(frame: CGRect(x: 0, y: 256, width: 256, height: 128))
            label.backgroundColor = .clear
            label.textAlignment = .center
            label.textColor = .darkGray
            label.font = label.font.withSize(36)
            label.adjustsFontSizeToFitWidth = true
            label.tag = 1
            label.isHidden = true
            label.numberOfLines = 0
            itemView.addSubview(label)
            
            itemImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 256, height: 256))
            switch index {
            case 0:
                itemImage.image = UIImage(named: "menu_bridge")
                label.text = "Access Control Bridges"
            case 1:
                itemImage.image = UIImage(named: "menu_bridge")
                label.text = "Access Control Bridges\n(New)"
            case 2:
                itemImage.image = UIImage(named: "menu_hvac")
                label.text = "HVAC Systems\n(Coming Q4 2017)"
                label.numberOfLines = 0
            case 3:
                itemImage.image = UIImage(named: "menu_help")
                label.text = "Help / Troubleshooting"
            case 4:
                itemImage.image = UIImage(named: "menu_web")
                label.text = "Visit Sure-Fi.com"
            default: break
                //itemView.image = UIImage(named: "page.png")
                
            }
            itemImage.tag = 2
            itemImage.contentMode = .center
            itemView.addSubview(itemImage)
            
        }
        return itemView
    }
    
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        let allViews = carousel.visibleItemViews
        for tempView in allViews {
            
            if let view = tempView as? UIView {
                let label = view.viewWithTag(1)
                label?.isHidden = true
            }
            
        }
        let currentView = carousel.currentItemView
        let label = currentView?.viewWithTag(1)
        label?.isHidden = false
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {
            return value * 1.6
        }
        if option == .fadeMin {
            return 0
        }
        if option == .fadeMax {
            return 0
        }
        if option == .fadeMinAlpha {
            return 1
        }
        return value
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if index == 0 {
            hideBar = false
            let controller = storyboard.instantiateViewController(withIdentifier: "BridgeStartViewController") as! BridgeStartViewController
            self.navigationController?.pushViewController(controller, animated: true)
        }
        //if index == 3 {
        //    let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //    let controller = storyboard.instantiateViewController(withIdentifier: "AccountTableViewController") as! AccountTableViewController
        //    self.navigationController?.pushViewController(controller, animated: true)
       // }
        if index == 3 {
            UIApplication.shared.open(URL(string: "http://www.sure-fi.com")!, options: [:], completionHandler: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
