//
//  CoreDataStorageInput.swift
//
//
//  Created by Dmitriy Poluriezov on 4/16/19.
//

import CoreData

typealias CoreDataStorageOperationClosure = (_ context: NSManagedObjectContext, _ save: @escaping CoreDataStorageSaveClosure) -> Void
typealias CoreDataStorageSaveClosure = (_ completion: CoreDataStorageSaveCompletion?) -> Void
typealias CoreDataStorageSaveCompletion = (_ success: Bool, _ error: Error?) -> Void

protocol CoreDataStorageInput {
    func performInTemporaryContext(block: @escaping CoreDataStorageOperationClosure)
}
