//
//  PresetModel.swift
//  BTTPresetBeautify
//
//  Created by BB9z on 2018/12/15.
//  Copyright © 2018 B9Software. All rights reserved.
//

import Foundation

class BTTPreset: NSObject {
    private var rawData: [String: Any]
    
    init(json: [String: Any]) {
        rawData = json
    }
    
    func beautify() {
        var groups = appGroups
        groups.forEach { $0.beautify() }
        groups.sort()
        appGroups = groups
    }
    
    var appGroups: [AppGroup] {
        get {
            guard let rawGroups = rawData["BTTPresetContent"] as? [[String: Any]] else {
                return []
            }
            return rawGroups.compactMap { AppGroup(json: $0) }
        }
        set {
            rawData["BTTPresetContent"] = newValue.map { $0.rawData }
        }
    }
    
    class AppGroup: NSObject, Comparable {
        fileprivate var rawData: [String: Any]

        init(json: [String: Any]) {
            rawData = json
        }
        
        override var description: String {
            return "<\(type(of: self)) \(name ?? "?"): id: \(bundleIdentifier ?? "?")>"
        }
        
        var name: String? {
            return rawData["BTTAppName"] as? String
        }
        var bundleIdentifier: String? {
            return rawData["BTTAppBundleIdentifier"] as? String
        }
        
        var isGlobal: Bool {
            return bundleIdentifier == "BT.G"
        }
        
        static func < (lhs: BTTPreset.AppGroup, rhs: BTTPreset.AppGroup) -> Bool {
            if lhs.isGlobal { return true }
            if rhs.isGlobal { return false }
            guard let lName = lhs.name, let rName = rhs.name else {
                return false
            }
            return lName < rName
        }
        
        func beautify() {
            var items = triggers
            items.sort { a, b -> Bool in
                return a.orderForSort < b.orderForSort
            }
            triggers = items
        }
        
        var triggers: [Trigger] {
            get {
                guard let rawGroups = rawData["BTTTriggers"] as? [[String: Any]] else {
                    return []
                }
                return rawGroups.compactMap { Trigger(json: $0) }
            }
            set {
                rawData["BTTTriggers"] = newValue.map { $0.rawData }
            }
        }
    }
    
    class Trigger: NSObject {
        fileprivate var rawData: [String: Any]
        
        init(json: [String: Any]) {
            rawData = json
        }
        
        override var description: String {
            return "<Trigger \"\(displayName)\">"
        }
        
        var displayName: String {
            return widgetName ?? touchBarButtonName ?? typeDescription ?? "NAME?"
        }
        var widgetName: String? {
            return rawData["BTTWidgetName"] as? String
        }
        var touchBarButtonName: String? {
            return rawData["BTTTouchBarButtonName"] as? String
        }
        var typeDescription: String? {
            return rawData["BTTTriggerTypeDescription"] as? String
        }
        
        var order: Int {
            return rawData["BTTOrder"] as? Int ?? 0
        }
        var type: Int {
            return rawData["BTTTriggerType"] as? Int ?? 0
        }
        fileprivate var orderForSort: Int {
            return type / 100 * 100 + order
        }
    }
}

extension BTTPreset {
    
    func write(toFile file: URL) throws {
        let dir = file.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        
        let os = OutputStream(toFileAtPath: file.path, append: false)!
        os.open()
        if let e = os.streamError {
            throw e
        }
        defer {
            os.close()
        }
        var error: NSError?
        if JSONSerialization.writeJSONObject(rawData, to: os, options: [.prettyPrinted, .sortedKeys], error: &error) > 0 {
            // success
        }
        else {
            throw error ?? NSError(domain: "\(self)", code: 0, userInfo: nil)
        }
    }
}
