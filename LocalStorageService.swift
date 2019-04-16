//
//  LocalStorageService.swift
//
//
//  Created by Dmitriy Poluriezov on 4/16/19.
//


import Foundation
import UIKit

// MARK: - Constants
private enum Constants {
    static let compressedImageSuffix = "-compressed"
}

final class LocalStorageService: LocalServicePrivateType {

    lazy var provider = FileManager.default

    // MARK: Private methods
    private func removeCompressedImage(named: String) {
        let imagePath = (getImagesDirectoryPath() as NSString).appendingPathComponent(named)
        if provider.fileExists(atPath: imagePath) {
            do {
                try provider.removeItem(atPath: imagePath)
            } catch let error {
                debugPrint("Error deleting file with name \(named), error: \(error.localizedDescription)")
            }
        } else {
            debugPrint("In the specified directory there is no file with name \(named)")
        }
    }

    private func saveCompressedImage(_ image: UIImage, named: String, complition: @escaping LocalStorageSaveImageCompletion) {
        let imagePath = (getImagesDirectoryPath() as NSString).appendingPathComponent(named)
        if !provider.fileExists(atPath: imagePath) {
            guard let compressedImage = image.compressed(quality: 0.1) else {
                complition(false)
                return
            }

            let compressedImageData =  compressedImage.pngData()
            provider.createFile(atPath: imagePath, contents: compressedImageData, attributes: nil)
            complition(true)
        } else {
            complition(false)
            debugPrint("Already file with name \(named) created.")
        }
    }
}

// MARK: - ImageStorable
extension LocalStorageService: ImageStorable {
    // MARK: - Methods for working with images directory
    func getImagesDirectoryPath() -> String {
        let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let imageDirectoryPath = (documentsPaths[0] as NSString).appendingPathComponent("Images")
        return imageDirectoryPath
    }

    func createImageDirectory() {
        let imageDirectoryPath = getImagesDirectoryPath()
        if !provider.fileExists(atPath: imageDirectoryPath) {
            do {
                try provider.createDirectory(atPath: imageDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                debugPrint("Error creating images directory: \(error.localizedDescription)")
            }
        } else {
            debugPrint("Already images directory created.")
        }
    }

    func deleteImageDirectory() {
        let imageDirectoryPath = getImagesDirectoryPath()
        if provider.fileExists(atPath: imageDirectoryPath) {
            do {
                try provider.removeItem(atPath: imageDirectoryPath)
            } catch let error {
                debugPrint("Error deleting images directory, error: \(error.localizedDescription)")
            }
        } else {
            debugPrint("Already images dictionary deleted.")
        }
    }

    // MARK: - Methods for working with UIImage
    func saveImage(_ image: UIImage, named: String, complition: @escaping LocalStorageSaveImageCompletion) {
        let imagePath = (getImagesDirectoryPath() as NSString).appendingPathComponent(named)
        if !provider.fileExists(atPath: imagePath) {
            let imageData = image.pngData()
            provider.createFile(atPath: imagePath, contents: imageData, attributes: nil)
            saveCompressedImage(image, named: named + Constants.compressedImageSuffix) { success in
                guard success else {
                    complition(false)
                    return
                }
            }

            complition(true)
        } else {
            complition(false)
            debugPrint("Already file with name \(named) created.")
        }
    }

    func getSavedImage(named: String) -> UIImage? {
        let imagePath = (getImagesDirectoryPath() as NSString).appendingPathComponent(named)
        if provider.fileExists(atPath: imagePath) {
            guard let imageData = provider.contents(atPath: imagePath), let image = UIImage(data: imageData) else {
                return nil
            }
            return image
        } else {
            debugPrint("In the specified directory there is no file with name \(named)")
            return nil
        }
    }

    func removeImage(named: String) {
        let imagePath = (getImagesDirectoryPath() as NSString).appendingPathComponent(named)
        if provider.fileExists(atPath: imagePath) {
            do {
                try provider.removeItem(atPath: imagePath)
                removeCompressedImage(named: named + Constants.compressedImageSuffix)
            } catch let error {
                debugPrint("Error deleting file with name \(named), error: \(error.localizedDescription)")
            }
        } else {
            debugPrint("In the specified directory there is no file with name \(named)")
        }
    }
}
