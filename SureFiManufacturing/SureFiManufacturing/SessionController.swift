//
//  Session.swift
//  SureFi
//
//  Created by John Robinson on 3/31/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import Foundation
import UIKit

class SessionController: NSObject {

    var session_key: String!

    let apiURLString = "https://tjdk5m3fi2.execute-api.us-west-2.amazonaws.com/prod/"
    let apiKey = "52a9"
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func checkServerConnection() -> Bool {
        
        let networkStatus = Reachability().connectionStatus()
        switch networkStatus {
        case .Unknown, .Offline:
            return false
        case .Online(.WWAN):
            return true
        case .Online(.WiFi):
            return true
        }
    }
    
    func sessionStarted() -> Bool {
        
        if session_key == nil || session_key == "" {
            return false
        }
        return true
    }
    
    func startSession(callback: ((Bool) -> Void)! ) ->Void {
        
        var params: [String:String] = [String:String]()
        let rand_string = Util().randomString(length: 12, letters: "abcdef01234567890")
        params["random_string"] = rand_string
        params["API_KEY"] = apiKey

        let url: URL = URL(string: "\(apiURLString)sessions/start")!
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        let jsonDataString = String(data: jsonData!, encoding: .utf8)
        
        request.httpBody = jsonData

        let task = session.dataTask(with: request as URLRequest) {
            (data, response, error) in
            
            guard let data = data, let _:URLResponse = response, error == nil else {
                return
            }
            let (status, msg, result_data) = self.processResultData(resultData: data, viewController: nil)
            if status {
                self.session_key = result_data.object(forKey: "session_key") as? String ?? ""
                callback(true)
            } else {
                
                let dataString = String(data: data, encoding: .utf8)
                callback(false)
            }
            return
        }
        task.resume()

    }
    
    func postServerRequest(action: String, postData: NSMutableDictionary, urlData :String, callback: ((Data) -> Void)! ) ->Void {
        
        var params: [String:String] = [String:String]()
        params["session_key"] = self.session_key
        for (key,value) in postData {
            params[key as! String] = value as? String ?? ""
        }
        
        let url: URL = URL(string: "\(apiURLString)\(action)")!
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        let jsonDataString = String(data: jsonData!, encoding: .utf8)
        
        request.httpBody = jsonData
        
        let task = session.dataTask(with: request as URLRequest) {
            (data, response, error) in
            
            guard let data = data, let _:URLResponse = response, error == nil else {
                return
            }
            
            if callback != nil {
                return callback(data)
            } else {
                return
            }
        }
        task.resume()
    }
    
    func processResultData(resultData: Data, viewController:Any?) -> (Bool, String, NSMutableDictionary) {
        
        do {
            let parsedData = try JSONSerialization.jsonObject(with: resultData, options: JSONSerialization.ReadingOptions.mutableContainers)
            let apiDictionary = parsedData as? NSDictionary
            
            if apiDictionary?.object(forKey: "status") as? String ?? "" == "success" {
                let data = apiDictionary?.object(forKey: "data") as? NSMutableDictionary ?? NSMutableDictionary()
                let message = apiDictionary?.object(forKey: "msg") as? String ?? ""
                return (true,message,data)
            }
            if apiDictionary?.object(forKey: "status") as? String ?? "" == "failure" {
                
                let data = apiDictionary?.object(forKey: "data") as? NSMutableDictionary ?? NSMutableDictionary()
                let message = apiDictionary?.object(forKey: "msg") as? String ?? ""
                return (false,message,data)
            }
            
            if viewController != nil && (apiDictionary?.object(forKey: "message") as? String ?? "" != "" || apiDictionary?.object(forKey: "errorMessage") as? String ?? "" != "") {
                
                let tempViewController = viewController as? UIViewController ?? UIViewController()
                let alertController = UIAlertController(title: "API Error", message: "\(apiDictionary?.object(forKey: "message") as? String ?? "")\(apiDictionary?.object(forKey: "errorMessage") as? String ?? "")", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                DispatchQueue.main.async {
                    tempViewController.present(alertController, animated: true, completion: nil)
                }
            }
            return (false,"",NSMutableDictionary())
        }
        catch let error as NSError {
            
            let dataString = String(data: resultData, encoding: .utf8)
            
            if viewController != nil {
                
                let tempViewController = viewController as? UIViewController ?? UIViewController()
                let alertController = UIAlertController(title: "API Error", message: "\(error)", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertController.addAction(continueAction)
                tempViewController.present(alertController, animated: true, completion: nil)
                
            }
            print("Details of JSON parsing error:\n \(error)")
        }
        return (false,"",NSMutableDictionary())
    }
    

    


}
