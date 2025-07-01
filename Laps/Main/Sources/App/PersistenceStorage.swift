//
//  PersistenceStorage.swift
//  Core
//
//  Created by dev team on 2024/01/04.
//

import Combine
import CoreData

@objc(AttributedStringToDataTransformer)
class AttributedStringToDataTransformer: ValueTransformer {
    
    override func transformedValue(_ value: Any?) -> Any? {
        let boxedData = try! NSKeyedArchiver.archivedData(withRootObject: value!, requiringSecureCoding: true)
        return boxedData
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        let typedBlob = value as! Data
        let data = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [String.self as! AnyObject.Type], from: typedBlob)
        return (data as! String)
    }
}

//@MainActor
public class PersistenceStorage {
    public static let shared = PersistenceStorage()
    
    let container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "Coredata")
            
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.cloud.mooq.labs")
        storeDescription.configuration = "Cloud"
        storeDescription.timeout = 3
        container.persistentStoreDescriptions = [storeDescription]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        return container
    }()
    
    // MARK: - Core Data support
    private func save () {
        if container.viewContext.hasChanges {
            do {
                try self.container.viewContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveContext() {
        let context = self.container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func fetch<T: NSManagedObject>(request: NSFetchRequest<T>) -> [T] {
        do {
            let fetchResult = try self.container.viewContext.fetch(request)
            return fetchResult
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    @discardableResult func delete(object: NSManagedObject) -> Bool {
        self.container.viewContext.delete(object)
        do{
            try self.container.viewContext.save()
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult func deleteAll<T: NSManagedObject>(request: NSFetchRequest<T>) -> Bool {
        let request: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try self.container.viewContext.execute(delete)
            return true
        } catch {
            return false
        }
    }
    
    private func count<T: NSManagedObject>(request: NSFetchRequest<T>) -> Int? {
        do {
            let count = try self.container.viewContext.count(for: request)
            return count
        } catch {
            return nil
        }
    }
    
    @discardableResult public func removeAllEntityData(entityName: String) -> Bool {
        let ReqVar = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: ReqVar)
        do {
            try self.container.viewContext.execute(DelAllReqVar)
            return true
        }
        catch { return false }
    }
    
    public func getContainer() -> NSPersistentCloudKitContainer {
        return container
    }
}
