//
//  CoreDataStorage.swift
//
//
//  Created by Dmitriy Poluriezov on 4/16/19.
//

import CoreData

// MARK: - Constants
private enum Constants {
    static let storageName = "DataStorage.sqlite"
}

class CoreDataStorage: CoreDataStoragePrivateType {

    var model: NSManagedObjectModel!
    var coordinator: NSPersistentStoreCoordinator!
    var mainContext: NSManagedObjectContext!

    init() {
        setup()
    }

    // MARK: - Setup CoreDataStorage
    private func setup() {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            debugPrint("Failed to read documents url")
            return
        }

        let storageURL = documentsUrl.appendingPathComponent(Constants.storageName)
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]

        model = NSManagedObjectModel.mergedModel(from: nil)
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storageURL, options: options)
        } catch let error as NSError {
            coordinator = nil
            debugPrint("Failed to add persistent store with error \(error)")
        }

        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.persistentStoreCoordinator = coordinator
        mainContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
}

// MARK: - CoreDataStorageInput
extension CoreDataStorage: CoreDataStorageInput {
    func performInTemporaryContext(block: @escaping CoreDataStorageOperationClosure) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        context.parent = mainContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        let saveBlock: CoreDataStorageSaveClosure = { [weak self] (completion: CoreDataStorageSaveCompletion?) -> Void in
            guard let self = self else {
                return
            }

            do {
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                debugPrint("Error on saving in temporary context:" + error.localizedDescription)
                completion?(false, error)
            }

            self.mainContext.perform {
                do {
                    try self.mainContext.save()
                    completion?(true, nil)
                } catch {
                    debugPrint("Error on pushing changes to main context:" + error.localizedDescription)
                    completion?(false, error)
                }
            }
        }

        context.perform {
            block(context, saveBlock)
        }
    }
}
