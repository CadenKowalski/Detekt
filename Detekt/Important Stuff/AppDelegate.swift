//
//  AppDelegate.swift
//  Detekt
//
//  Created by Caden Kowalski on 6/7/19.
//  Copyright © 2019 Caden Kowalski. All rights reserved.
//

import UIKit
import CoreData

var smartNN: Bool!
let flashBtn = UIButton()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func SaveContext(ContextName: NSManagedObjectContext) {
        if ContextName.hasChanges {
            do {
                try ContextName.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        func InitiateSettings() {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let Context = appDelegate.persistentContainer.viewContext
            let settingsObject = NSEntityDescription.entity(forEntityName: "Settings", in: Context)
            let smartNNObject = NSManagedObject(entity: settingsObject!, insertInto: Context)
            smartNNObject.setValue(true, forKey: "smartNeuralNet")
            smartNN = true
            SaveContext(ContextName: Context)
        }
        InitiateSettings()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        flashBtn.setImage(#imageLiteral(resourceName: "cameraFlashOff"), for: .normal)
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
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let Context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Settings")
        do {
            let fetchResults = try Context.fetch(fetchRequest)
            let firstInstance: Settings = fetchResults[0] as! Settings
            let firstValue = (firstInstance.value(forKey: "smartNeuralNet") as! Bool)
            smartNN = firstValue
            if fetchResults.count > 1 {
                let secondInstance = fetchResults[1] as! NSManagedObject
                Context.delete(secondInstance)
            }
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        SaveContext(ContextName: context)
        
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Detekt")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
}
