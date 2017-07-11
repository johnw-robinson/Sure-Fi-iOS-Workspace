//
//  AppDelegate.swift
//  SureFi
//
//  Created by John Robinson on 3/16/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import CoreLocation
import Contacts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?
    
    var userData: NSMutableDictionary = NSMutableDictionary()
    var sessionController:SessionController!
    
    var deviceName: String = ""
    var deviceNotificationToken = ""
    var devicePhoneNumber: String = ""
    var activationCode: String = ""
    
    var checkedRegistration: Bool = false
    var isRegistered: Bool = false
    var deviceDictionary: NSMutableDictionary = NSMutableDictionary()
    
    var currentLatitude: Double!
    var currentLongitude: Double!
    var currentLocation: CLLocation!
    var locationManager = CLLocationManager()
    
    var contactStore = CNContactStore()
    
    var contacts: [CNContact]!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        getCurrentLocation()
        
        deviceName = UIDevice.current.name
        registerForRemoteNotification()
        sessionController = SessionController()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        deviceNotificationToken = ""
        for i in 0..<deviceToken.count {
            deviceNotificationToken = deviceNotificationToken + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        print("Did Register \(deviceName) \(deviceNotificationToken)")
        
        let currentDevice = UIDevice.current
        let model = currentDevice .model
        let systemVersion = currentDevice.systemVersion
        let languageArray = NSLocale.preferredLanguages
        let language = languageArray[0]
        let locale = NSLocale.current
        let country = locale.identifier
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? ""
        let deviceSpecs = "\(model) - \(systemVersion) - \(language) - \(country) - \(appVersion)"
        
        deviceDictionary = NSMutableDictionary()
        deviceDictionary.setValue(deviceNotificationToken, forKey: "device_token")
        deviceDictionary.setValue("IOS", forKey: "device_type")
        deviceDictionary.setValue(deviceName, forKey: "device_title")
        deviceDictionary.setValue(deviceSpecs, forKey: "device_details")
        
        print("Checking Device Registration")
        SessionController().postServerRequest(action: "sessions/check_device_registration", postData: deviceDictionary, urlData:"", callback: self.checkDeviceRegistrationCallback)
    }
    
    func checkDeviceRegistrationCallback(result: Data) {
        
        print("Device Registration Callback")
        let (status,msg,data) = sessionController.processResultData(resultData: result, viewController: self)
        if status {
            
            if data["registered"] as! Bool {
                print("Device is Registered")
                isRegistered = true
                checkedRegistration = true
            } else {
                print("Device is NOT Registered")
                print("Register Device")
                SessionController().postServerRequest(action: "sessions/register_device", postData: deviceDictionary, urlData:"", callback: self.registerDeviceCallback)
            }
        } else {
            print(msg)
        }
    }
    
    func registerDeviceCallback(result: Data) {
        
        print("Register Device Callback")
        let (status,msg,data) = sessionController.processResultData(resultData: result, viewController: self)
        if status {
            
            if data["registered"] as! Bool {
                print("Device is Registered")
                checkedRegistration = true
            } else {
                print("Device is NOT Registered")
            }
        } else {
            print(msg)
        }

    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        print("Did Fail Register:\(error)")
        checkedRegistration = true
        isRegistered = true
        
    }
    
    func getCurrentLocation() {
        
        if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse){
            currentLocation = locationManager.location
            currentLatitude = currentLocation.coordinate.latitude
            currentLongitude = currentLocation.coordinate.longitude
            print("Current Location:\(currentLocation)")
        }
    }
    
    func checkAccessStatus(completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch authorizationStatus {
        case .authorized:
            completionHandler(true)
        case .denied, .notDetermined:
            self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    
                    self.contacts = [CNContact]()
                    let keys = [CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactNicknameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
                    let request = CNContactFetchRequest(keysToFetch: keys  as [CNKeyDescriptor])
                    
                    do {
                        try self.contactStore.enumerateContacts(with: request) {
                            (contact, stop) in
                            // Array containing all unified contacts from everywhere
                            self.contacts.append(contact)
                        }
                    }
                    catch {
                        print("unable to fetch contacts")
                    }
                    
                    completionHandler(access)
                } else {
                    print("access denied")
                }
            })
        default:
            completionHandler(false)
        }
    }
    
    func registerForRemoteNotification() {
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert], completionHandler: {(granted, error) in
            if (granted) {
                print("Success - Push Notifications Registered")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            else {
                print("Fail - Push Notifications Registered")
            }
        })
    }
    
    
    
    //Called when a notification is delivered to a foreground app.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Will Present User Info = ",notification.request.content.userInfo)
        
        var messageText: String = ""
        if let aps = notification.request.content.userInfo["aps"] as? NSDictionary {
            if let alert = aps["alert"] as? NSDictionary {
                if let message = alert["message"] as? String {
                    messageText = message
                }
            } else if let alert = aps["alert"] as? String {
                messageText = alert
            }
        }
        if messageText.range(of:"The Activation Code") != nil{
            devicePhoneNumber = messageText.slice(from: "+", to: " ") ?? ""
            print("Phone Number:\(devicePhoneNumber)")
            activationCode = messageText.substring(from: messageText.length - 4)
        }
        completionHandler([.alert, .badge, .sound])
    }
    
    //Called to let your app know which action was selected by the user for a given notification.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Did Recieve User Info = ",response.notification.request.content.userInfo)
        var messageText: String = ""
        if let aps = response.notification.request.content.userInfo["aps"] as? NSDictionary {
            if let alert = aps["alert"] as? NSDictionary {
                if let message = alert["message"] as? String {
                    messageText = message
                }
            } else if let alert = aps["alert"] as? String {
                messageText = alert
            }
        }
        if messageText.range(of:"The Activation Code") != nil{
            devicePhoneNumber = messageText.slice(from: "+", to: " ") ?? ""
            print("Phone Number:\(devicePhoneNumber)")
            activationCode = messageText.substring(from: messageText.length - 4)
        }
        completionHandler()
    }
    
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "SureFi")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

