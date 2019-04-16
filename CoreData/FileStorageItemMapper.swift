//
//  FileStorageItemMapper.swift
//
//
//  Created by Dmitriy Poluriezov on 4/16/19.
//

import UIKit

class FileStorageItemMapper {
}

// MARK: - FileStorageItemMapperInput
extension FileStorageItemMapper: FileStorageItemMapperInput {
    func map(fileStorageItem: FileStorageItem, to cdFileStorageItem: CDFileStorageItem) {
        cdFileStorageItem.creationDate = fileStorageItem.creationDate
        cdFileStorageItem.id = fileStorageItem.id
        cdFileStorageItem.folderOrder = fileStorageItem.folderOrder
        cdFileStorageItem.imagePath = fileStorageItem.imagePath
        cdFileStorageItem.compressedImageParh = fileStorageItem.compressedImagePath
        cdFileStorageItem.parentId = fileStorageItem.parentId
        cdFileStorageItem.type = fileStorageItem.type
        cdFileStorageItem.children?.addingObjects(from: fileStorageItem.children)
    }

    func fileStorageItem(from cdFileStorageItem: CDFileStorageItem, includeCildren: Bool) -> FileStorageItem? {
        guard let id = cdFileStorageItem.id,
            let date = cdFileStorageItem.creationDate,
            let imagePath = cdFileStorageItem.imagePath,
            let compressedImagePath = cdFileStorageItem.compressedImageParh,
            let parentId = cdFileStorageItem.parentId,
            let type = cdFileStorageItem.type else {
            return nil
        }

        let folderOrder = cdFileStorageItem.folderOrder

        var children: [FileStorageItem] = []

        if includeCildren, let childrenSet = cdFileStorageItem.children, let cdChildren = Array(childrenSet) as? [CDFileStorageItem] {
            cdChildren.forEach { cdCild in
                if let child = self.fileStorageItem(from: cdCild, includeCildren: false) {
                    children.append(child)
                }
            }
        }

        let fileStorageItem = FileStorageItem(id: id, creationDate: date, folderOrder: folderOrder, imagePath: imagePath, compressedImagePath: compressedImagePath, parentId: parentId, type: type, children: children)

        return fileStorageItem
    }
}
