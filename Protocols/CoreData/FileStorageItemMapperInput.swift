//
//  FileStorageItemMapperInput.swift
//
//
//  Created by Dmitriy Poluriezov on 4/16/19.
//

import Foundation

protocol FileStorageItemMapperInput: class {
    func map(fileStorageItem: FileStorageItem, to cdFileStorageItem: CDFileStorageItem)
    func fileStorageItem(from cdFileStorageItem: CDFileStorageItem, includeCildren: Bool) -> FileStorageItem?
}
