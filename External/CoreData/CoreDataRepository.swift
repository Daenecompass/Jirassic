//
//  CoreDataRepository.swift
//  Jirassic
//
//  Created by Cristian Baluta on 15/04/16.
//  Copyright © 2016 Cristian Baluta. All rights reserved.
//

import Foundation
import CoreData

class CoreDataRepository {
    
    fileprivate let databaseName = "Jirassic"
    
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let baseUrl = urls.last!
        let url = baseUrl.appendingPathComponent(self.databaseName)
//        print(url)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
            } catch _ {
                return baseUrl
            }
        }
        return url
    }()
    
    func persistentStoreCoordinator() -> NSPersistentStoreCoordinator? {
        let coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = applicationDocumentsDirectory.appendingPathComponent("\(databaseName).coredata")
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
            return coordinator
        } catch _ {
            return nil
        }
    }
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: self.databaseName, withExtension: "momd")
        return NSManagedObjectModel(contentsOf: modelURL!)!
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        guard let coordinator = self.persistentStoreCoordinator() else {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch _ {
                    
                }
            }
        }
    }
    
    convenience init (documentsDirectory: String) {
        self.init()
        applicationDocumentsDirectory = URL(fileURLWithPath: documentsDirectory)
    }
}

extension CoreDataRepository {
    
    fileprivate func queryWithPredicate<T:NSManagedObject> (_ predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [T] {
        
        guard let context = managedObjectContext else {
            return []
        }
        
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        //let request = T.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        do {
            let results = try context.fetch(request)
            return results
        } catch _ {
            return []
        }
    }
}

extension CoreDataRepository: RepositoryUser {
    
    func currentUser() -> User {
        
        let userPredicate = NSPredicate(format: "isLoggedIn == YES")
        let cusers: [CUser] = queryWithPredicate(userPredicate, sortDescriptors: nil)
        if let cuser = cusers.last {
            return User(isLoggedIn: true, email: cuser.email, userId: cuser.userId, lastSyncDate: cuser.lastSyncDate)
        }
        
        return User(isLoggedIn: false, email: nil, userId: nil, lastSyncDate: nil)
    }
    
    func loginWithCredentials (_ credentials: UserCredentials, completion: (NSError?) -> Void) {
        fatalError("This method is not applicable to CoreDataRepository")
    }
    
    func registerWithCredentials (_ credentials: UserCredentials, completion: (NSError?) -> Void) {
        fatalError("This method is not applicable to CoreDataRepository")
    }
    
    func logout() {
        
        guard let context = managedObjectContext else {
            return
        }
        
        if #available(OSX 1000.11, *) {
            // TODO: This seems not to work under 10.11
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: CTask.self))
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try persistentStoreCoordinator()?.execute(deleteRequest, with: context)
            } catch let error as NSError {
                RCLog(error)
            }
        } else {
            let fetchRequest = NSFetchRequest<CTask>()
            fetchRequest.entity = NSEntityDescription.entity(forEntityName: String(describing: CTask.self), in: context)
            fetchRequest.includesPropertyValues = false
            do {
                let results = try context.fetch(fetchRequest)
                for result in results {
                    context.delete(result)
                }
                try context.save()
            } catch {
                
            }
        }
    }
}

extension CoreDataRepository: RepositoryTasks {

    func queryTasks (_ page: Int, completion: ([Task], NSError?) -> Void) {
        
        let sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: true)]
        let results: [CTask] = queryWithPredicate(nil, sortDescriptors: sortDescriptors)
        let tasks = tasksFromCTasks(results)
        
        completion(tasks, nil)
    }
    
    func queryTasksInDay (_ day: Date) -> [Task] {
        
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "endDate >= %@ AND endDate <= %@", day.startOfDay() as CVarArg, day.endOfDay() as CVarArg)
        ])
        let sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: true)]
        let results: [CTask] = queryWithPredicate(compoundPredicate, sortDescriptors: sortDescriptors)
        let tasks = tasksFromCTasks(results)
        
        return tasks
    }
    
    func queryUnsyncedTasks() -> [Task] {
        
        let predicate = NSPredicate(format: "lastModifiedDate == nil")
        let results: [CTask] = queryWithPredicate(predicate, sortDescriptors: nil)
        let tasks = tasksFromCTasks(results)
        
        return tasks
    }
    
    func deleteTask (_ task: Task, completion: ((_ success: Bool) -> Void)) {
        
        guard let context = managedObjectContext else {
            return
        }
        
        let ctask = ctaskFromTask(task)
        context.delete(ctask)
        saveContext()
        completion(true)
    }
    
    func saveTask (_ task: Task, completion: (_ success: Bool) -> Void) -> Task {
        
        let ctask = ctaskFromTask(task)
        saveContext()
        
        return taskFromCTask(ctask)
    }
    
    fileprivate func taskFromCTask (_ ctask: CTask) -> Task {
        
        return Task(startDate: ctask.startDate,
                    endDate: ctask.endDate!,
                    notes: ctask.notes,
                    taskNumber: ctask.taskNumber,
                    taskType: TaskType(rawValue: ctask.taskType!.intValue)!,
                    objectId: ctask.objectId!
        )
    }
    
    fileprivate func tasksFromCTasks (_ ctasks: [CTask]) -> [Task] {
        
        var tasks = [Task]()
        for ctask in ctasks {
            tasks.append(self.taskFromCTask(ctask))
        }
        
        return tasks
    }
    
    fileprivate func ctaskFromTask (_ task: Task) -> CTask {
        
        let taskPredicate = NSPredicate(format: "objectId == %@", task.objectId)
        let tasks: [CTask] = queryWithPredicate(taskPredicate, sortDescriptors: nil)
        var ctask: CTask? = tasks.first
        if ctask == nil {
            ctask = NSEntityDescription.insertNewObject(forEntityName: String(describing: CTask.self),
                                                        into: managedObjectContext!) as? CTask
        }
        if ctask?.objectId == nil {
            ctask?.objectId = task.objectId
        }
        
        return updatedCTask(ctask!, withTask: task)
    }
    
    // Update only updatable properties. objectId can't be updated
    fileprivate func updatedCTask (_ ctask: CTask, withTask task: Task) -> CTask {
        
        ctask.taskNumber = task.taskNumber
        ctask.taskType = NSNumber(value: task.taskType.rawValue)
        ctask.notes = task.notes
        ctask.startDate = task.startDate
        ctask.endDate = task.endDate
        
        return ctask
    }
}

extension CoreDataRepository: RepositorySettings {
    
    func settings() -> Settings {
        
        let results: [CSettings] = queryWithPredicate(nil, sortDescriptors: nil)
        var csettings: CSettings? = results.first
        if csettings == nil {
            csettings = NSEntityDescription.insertNewObject(forEntityName: String(describing: CSettings.self),
                                                            into: managedObjectContext!) as? CSettings
            csettings?.startOfDayEnabled = 1
            csettings?.lunchEnabled = 1
            csettings?.scrumEnabled = 1
            csettings?.meetingEnabled = 1
            csettings?.autoTrackEnabled = 1
            csettings?.trackingMode = 1
            csettings?.startOfDayTime = Date(hour: 9, minute: 0)
            csettings?.endOfDayTime = Date(hour: 17, minute: 0)
            csettings?.lunchTime = Date(hour: 13, minute: 0)
            csettings?.scrumTime = Date(hour: 10, minute: 30)
            csettings?.minSleepDuration = Date(hour: 0, minute: 13)
            saveContext()
        }
        return settingsFromCSettings(csettings!)
    }
    
    func saveSettings (_ settings: Settings) {
        
        let _ = csettingsFromSettings(settings)
        saveContext()
    }
    
    fileprivate func settingsFromCSettings (_ csettings: CSettings) -> Settings {
        
        return Settings(startOfDayEnabled: csettings.startOfDayEnabled!.boolValue,
                        lunchEnabled: csettings.lunchEnabled!.boolValue,
                        scrumEnabled: csettings.scrumEnabled!.boolValue,
                        meetingEnabled: csettings.meetingEnabled!.boolValue,
                        autoTrackEnabled: csettings.autoTrackEnabled!.boolValue,
                        trackingMode: TaskTrackingMode(rawValue: csettings.trackingMode!.intValue)!,
                        startOfDayTime: csettings.startOfDayTime!,
                        endOfDayTime: csettings.endOfDayTime!,
                        lunchTime: csettings.lunchTime!,
                        scrumTime: csettings.scrumTime!,
                        minSleepDuration: csettings.minSleepDuration!
        )
    }
    
    fileprivate func csettingsFromSettings (_ settings: Settings) -> CSettings {
        
        let results: [CSettings] = queryWithPredicate(nil, sortDescriptors: nil)
        var csettings: CSettings? = results.first
        if csettings == nil {
            csettings = NSEntityDescription.insertNewObject(forEntityName: String(describing: CSettings.self),
                                                            into: managedObjectContext!) as? CSettings
        }
        csettings?.startOfDayEnabled = NSNumber(value: settings.startOfDayEnabled)
        csettings?.lunchEnabled = NSNumber(value: settings.lunchEnabled)
        csettings?.scrumEnabled = NSNumber(value: settings.scrumEnabled)
        csettings?.meetingEnabled = NSNumber(value: settings.meetingEnabled)
        csettings?.autoTrackEnabled = NSNumber(value: settings.autoTrackEnabled)
        csettings?.trackingMode = NSNumber(value: settings.trackingMode.rawValue)
        csettings?.startOfDayTime = settings.startOfDayTime
        csettings?.endOfDayTime = settings.endOfDayTime
        csettings?.lunchTime = settings.lunchTime
        csettings?.scrumTime = settings.scrumTime
        csettings?.minSleepDuration = settings.minSleepDuration
        
        return csettings!
    }
}
