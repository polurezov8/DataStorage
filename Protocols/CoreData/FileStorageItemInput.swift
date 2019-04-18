//
//  FileStorageItemInput.swift
//
//
//  Created by Dmitriy Poluriezov on 4/16/19.
//

import Foundation

typealias FileStorageItemListCompletion = (_ results: [FileStorageItem]?, _ error: Error?) -> Void
typealias FileStorageItemCompletion = (_ success: Bool, _ error: Error?) -> Void
typealias FileStorageItemsCountComplition = (_ count: Int?, _ error: Error?) -> Void

protocol FileStorageItemInput: class {
    func fetchFileItems(parentId: String?, completion: @escaping FileStorageItemListCompletion)
    func addToRootFoler(items: [FileStorageItem], completion: @escaping FileStorageItemCompletion)
    func insertToRootFolder(fileItem: FileStorageItem, completion: @escaping FileStorageItemCompletion)
    func insertTo(folder: FileStorageItem, documents: [FileStorageItem], isFolderNewlyCreated: Bool, completion: @escaping FileStorageItemCompletion)
    func update(fileStorageItem: FileStorageItem, completion: @escaping FileStorageItemCompletion)
    func updateOrderForCDFiles(_ fileStorageItems: [FileStorageItem], completion: @escaping FileStorageItemCompletion)
    func removeFileItem(with id: String, completion: @escaping FileStorageItemCompletion)
    func removeItemsFromRootFolder(completion: @escaping FileStorageItemCompletion)
    func getFilesCount(by folderId: String, completion: @escaping FileStorageItemsCountComplition)
}
