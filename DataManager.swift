//
//  DataManager.swift
//
//
//  Created by Dmitriy Poluriezov on 4/16/19.
//


import Foundation

final class DataManager {

    static let sharedInstance: DataManager = {
        let instance = DataManager()
        instance.coreDataService = CoreDataService.sharedInstance
        instance.localStorageService = LocalStorageService()

        return instance
    }()

    public var coreDataService: FileStorageItemInput!
    public var localStorageService: ImageStorable!
}
