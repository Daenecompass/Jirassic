//
//  FirebaseRepository.swift
//  Jirassic
//
//  Created by Cristian Baluta on 09/06/16.
//  Copyright © 2016 Cristian Baluta. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitRepository {
    
    internal var user: User?
    internal let privateDB = CKContainer.default().privateCloudDatabase
    internal let customZone = CKRecordZone(zoneName: "TasksZone")
    
    init() {
        CKContainer.default().accountStatus(completionHandler: { (status, error) in
            RCLog(status.rawValue)
            RCLogErrorO(error)
        })
        privateDB.save(customZone) { (recordZone, err) in
            RCLogO(recordZone)
            RCLogErrorO(err)
        }
    }
}

extension CloudKitRepository {
    
    func fetchChangedRecords (token: CKServerChangeToken?, 
                              previousRecords: [CKRecord], 
                              previousDeletedRecordsIds: [CKRecordID], 
                              completion: @escaping ((_ changedRecords: [CKRecord], _ deletedRecordsIds: [CKRecordID]) -> Void)) {
        
        var changedRecords = previousRecords
        var deletedRecordsIds = previousDeletedRecordsIds
        
        let op = CKFetchRecordChangesOperation(recordZoneID: customZone.zoneID, previousServerChangeToken: token)
        
        op.recordChangedBlock = { record in
            RCLog(record)
            changedRecords.append(record)
        }
        op.recordWithIDWasDeletedBlock = { recordID in
            RCLog(recordID)
            deletedRecordsIds.append(recordID)
        }
        op.fetchRecordChangesCompletionBlock = { serverChangeToken, data, error in
            
//            RCLogO(serverChangeToken)
//            RCLogO(data)
            RCLogErrorO(error)
            guard error == nil else {
                completion(changedRecords, deletedRecordsIds)
                return
            }
            UserDefaults.standard.serverChangeToken = serverChangeToken
            
            if op.moreComing {
                self.fetchChangedRecords(token: serverChangeToken, 
                                         previousRecords: changedRecords, 
                                         previousDeletedRecordsIds: deletedRecordsIds, 
                                         completion: completion)
            } else {
                completion(changedRecords, deletedRecordsIds)
            }
        }
        privateDB.add(op)
    }
    
    func fetchRecords (ofType type: String, predicate: NSPredicate, completion: @escaping ((_ ctask: [CKRecord]?) -> Void)) {
        
        let query = CKQuery(recordType: type, predicate: predicate)
        privateDB.perform(query, inZoneWith: customZone.zoneID) { (results: [CKRecord]?, error) in
            
            RCLogErrorO(error)
            
            if let results = results {
                completion(results)
            } else {
                completion(nil)
            }
        }
    }
}
