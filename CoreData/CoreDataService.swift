//
//  CoreDataService.swift
//
//
//  Created by Dmitriy Poluriezov on 4/16/19.
//

import CoreData

final class CoreDataService {

    static let sharedInstance: CoreDataService = {
        let instance = CoreDataService()
        instance.storage = CoreDataStorage()
        instance.fileStorageItemMapper = FileStorageItemMapper()

        return instance
    }()

    public var storage: CoreDataStorageInput!
    public var fileStorageItemMapper: FileStorageItemMapperInput!

    // MARK: - Private methods
    private func addCDFolder(_ folder: FileStorageItem, context: NSManagedObjectContext) -> CDFileStorageItem? {
        let cdFileStorageItemName = String(describing: CDFileStorageItem.self)
        guard let description = NSEntityDescription.entity(forEntityName: cdFileStorageItemName, in: context) else {
            return nil
        }

        let cdFileStorageFolder = CDFileStorageItem(entity: description, insertInto: context)
        self.fileStorageItemMapper.map(fileStorageItem: folder, to: cdFileStorageFolder)
        return cdFileStorageFolder
    }

    private func fetchCDFileItem(id: String, context: NSManagedObjectContext) -> CDFileStorageItem? {
        let request: NSFetchRequest<NSFetchRequestResult> = CDFileStorageItem.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(CDFileStorageItem.id), id)

        do {
            let cdFileStorageItem = try context.fetch(request)
            if let cdFileStorageItem = cdFileStorageItem.first as? CDFileStorageItem {
                return cdFileStorageItem
            }
        } catch {
            return nil
        }

        return nil
    }
}

// MARK: - FileStorageItemInput
extension CoreDataService: FileStorageItemInput {
    func fetchFileItems(parentId: String?, completion: @escaping FileStorageItemListCompletion) {
        storage.performInTemporaryContext { [weak self] (context: NSManagedObjectContext, save: @escaping CoreDataStorageSaveClosure) -> Void in
            guard let self = self else {
                completion(nil, nil)
                return
            }

            let request: NSFetchRequest<NSFetchRequestResult> = CDFileStorageItem.fetchRequest()
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(CDFileStorageItem.parentId), parentId ?? "")
            let folderOrderDescriptor = NSSortDescriptor(key: "folderOrder", ascending: true)
            request.sortDescriptors = [folderOrderDescriptor]

            do {
                var result: [FileStorageItem] = []
                let cdFileStorageItems = try context.fetch(request)
                if let cdFileStorageItems = cdFileStorageItems as? [CDFileStorageItem] {
                    cdFileStorageItems.forEach { cdFileStorageItem in
                        if let fileStorageItem = self.fileStorageItemMapper.fileStorageItem(from: cdFileStorageItem, includeCildren: true) {
                            result.append(fileStorageItem)
                        }
                    }
                    completion(result, nil)
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
    }

    func addToRootFoler(items: [FileStorageItem], completion: @escaping FileStorageItemCompletion) {
        storage.performInTemporaryContext { [weak self] (context: NSManagedObjectContext, save: @escaping CoreDataStorageSaveClosure) -> Void in
            guard let self = self else {
                completion(false, nil)
                return
            }

            var cdFileStorageItems: [CDFileStorageItem] = []
            let cdFileStorageItemName = String(describing: CDFileStorageItem.self)
            items.forEach { fileStorageItem in
                guard let description = NSEntityDescription.entity(forEntityName: cdFileStorageItemName, in: context) else {
                    completion(false, nil)
                    return
                }

                let cdFileStorageItem = CDFileStorageItem(entity: description, insertInto: context)
                self.fileStorageItemMapper.map(fileStorageItem: fileStorageItem, to: cdFileStorageItem)
                cdFileStorageItems.append(cdFileStorageItem)
            }

            save(completion)
        }
    }

    func insertToRootFolder(fileItem: FileStorageItem, completion: @escaping FileStorageItemCompletion) {
        storage.performInTemporaryContext { [weak self] (context: NSManagedObjectContext, save: @escaping CoreDataStorageSaveClosure) -> Void in
            guard let self = self else {
                completion(false, nil)
                return
            }

            let cdFileStorageItemName = String(describing: CDFileStorageItem.self)
            guard let description = NSEntityDescription.entity(forEntityName: cdFileStorageItemName, in: context) else {
                completion(false, nil)
                return
            }

            let cdFileStorageItem = CDFileStorageItem(entity: description, insertInto: context)
            self.fileStorageItemMapper.map(fileStorageItem: fileItem, to: cdFileStorageItem)

            save(completion)
        }
    }

    func insertTo(folder: FileStorageItem, documents: [FileStorageItem], isFolderNewlyCreated: Bool, completion: @escaping FileStorageItemCompletion) {
        storage.performInTemporaryContext { [weak self] (context: NSManagedObjectContext, save: @escaping CoreDataStorageSaveClosure) -> Void in
            guard let self = self else {
                completion(false, nil)
                return
            }

            var cdFileStorageItem: CDFileStorageItem?
            if isFolderNewlyCreated {
                cdFileStorageItem = self.addCDFolder(folder, context: context)
            } else {
                cdFileStorageItem = self.fetchCDFileItem(id: folder.id, context: context)
            }

            guard let cdFolder = cdFileStorageItem else {
                completion(false, nil)
                return
            }

            var cdFileStorageItems: [CDFileStorageItem] = []
            documents.forEach { fileStorageItem in
                if let cdFileStorageItem = self.fetchCDFileItem(id: fileStorageItem.id, context: context) {
                    cdFileStorageItems.append(cdFileStorageItem)
                }
            }

            cdFileStorageItems.forEach { cdFileStorageItem in
                cdFileStorageItem.parentId = cdFolder.id
                cdFileStorageItem.parent = cdFolder
                cdFolder.addToChildren(cdFileStorageItem)
            }

            save { success, error in
                if error == nil && success {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }
    }

    func update(fileStorageItem: FileStorageItem, completion: @escaping FileStorageItemCompletion) {
        storage.performInTemporaryContext { [weak self] (context: NSManagedObjectContext, save: @escaping CoreDataStorageSaveClosure) -> Void in
            guard let self = self else {
                completion(false, nil)
                return
            }

            let request: NSFetchRequest<NSFetchRequestResult> = CDFileStorageItem.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(CDFileStorageItem.id), fileStorageItem.id)

            do {
                let cdFileStorageItem = try context.fetch(request)
                if let cdFileStorageItem = cdFileStorageItem.first as? CDFileStorageItem {
                    self.fileStorageItemMapper.map(fileStorageItem: fileStorageItem, to: cdFileStorageItem)
                    save(completion)
                } else {
                    completion(true, nil)
                }
            } catch {
                completion(false, error)
            }
        }
    }

    func updateOrderForCDFiles(_ fileStorageItems: [FileStorageItem], completion: @escaping FileStorageItemCompletion) {
        storage.performInTemporaryContext { [weak self] (context: NSManagedObjectContext, save: @escaping CoreDataStorageSaveClosure) -> Void in
            guard let self = self else {
                completion(false, nil)
                return
            }

            fileStorageItems.forEach { fileStorageItem in
                let cdFileStorageItem = self.fetchCDFileItem(id: fileStorageItem.id, context: context)
                cdFileStorageItem?.folderOrder = fileStorageItem.folderOrder
            }

            save { success, error in
                if error == nil && success {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }
    }

    func removeFileItem(with id: String, completion: @escaping FileStorageItemCompletion) {
        storage.performInTemporaryContext { (context: NSManagedObjectContext, save: @escaping CoreDataStorageSaveClosure) -> Void in
            let request: NSFetchRequest<NSFetchRequestResult> = CDFileStorageItem.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(CDFileStorageItem.id), id)

            do {
                let cdFileStorageItem = try context.fetch(request)
                if let cdFileStorageItem = cdFileStorageItem.first as? CDFileStorageItem {
                    context.delete(cdFileStorageItem)
                    save(completion)
                } else {
                    completion(true, nil)
                }
            } catch {
                completion(false, error)
            }
        }
    }

    func removeItemsFromRootFolder(completion: @escaping FileStorageItemCompletion) {
        storage.performInTemporaryContext { [weak self] (context: NSManagedObjectContext, save: @escaping CoreDataStorageSaveClosure) -> Void in
            guard let self = self else {
                completion(false, nil)
                return
            }

            let request: NSFetchRequest<NSFetchRequestResult> = CDFileStorageItem.fetchRequest()
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(CDFileStorageItem.parentId), "")

            do {
                let cdFileStorageItems = try context.fetch(request)
                if let cdFileStorageItems = cdFileStorageItems as? [CDFileStorageItem] {
                    cdFileStorageItems.forEach { cdFileStorageItem in
                        guard let id = cdFileStorageItem.id else {
                            return
                        }

                        self.removeFileItem(with: id, completion: { success, error in
                            guard success, error == nil else {
                                completion(false, error)
                                return
                            }
                        })
                    }
                }
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
    }

    func getFilesCount(by folderId: String, completion: @escaping FileStorageItemsCountComplition) {
        storage.performInTemporaryContext { (context: NSManagedObjectContext, save: @escaping CoreDataStorageSaveClosure) -> Void in
            let request: NSFetchRequest<NSFetchRequestResult> = CDFileStorageItem.fetchRequest()
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(CDFileStorageItem.parentId), folderId)

            do {
                let cdFileStorageItems = try context.fetch(request)
                let storageItemsCount = cdFileStorageItems.count
                completion(storageItemsCount, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}
