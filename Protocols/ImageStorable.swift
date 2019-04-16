//
//  ImageStorable.swift
//
//
//  Created by Dmitriy Poluriezov on 4/16/19.
//

import Foundation
import UIKit

typealias LocalStorageSaveImageCompletion = (_ success: Bool) -> Void

protocol ImageStorable {
    func getImagesDirectoryPath() -> String
    func createImageDirectory()
    func deleteImageDirectory()
    func saveImage(_ image: UIImage, named: String, complition: @escaping LocalStorageSaveImageCompletion)
    func getSavedImage(named: String) -> UIImage?
    func removeImage(named: String)
}
