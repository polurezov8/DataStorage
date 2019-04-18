//
//  CoreDataService.swift
//
//
//  Created by Dmitriy Poluriezov on 4/17/19.
//

import CoreData

protocol CoreDataStoragePrivateType: class {
    var model: NSManagedObjectModel! { get set}
    var coordinator: NSPersistentStoreCoordinator! { get set }
    var mainContext: NSManagedObjectContext! { get set }
}
