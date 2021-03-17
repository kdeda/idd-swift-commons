//
//  NSRunningApplication.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 7/26/18.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public extension Bundle {
    
    static func with(appName appName_dot_app: String) -> Bundle? {
        let urls = [
            URL.iddHomeDirectory.appendingPathComponent("Development/build/Deployment/"),
            URL.iddHomeDirectory.appendingPathComponent("Development/build/Development/")
            ]

        let bundles = urls.compactMap { Bundle.init(url: $0.appendingPathComponent(appName_dot_app)) }
        return bundles.first(where: { $0.executableURL != nil })
    }

    /*
     * Wrapper for use in helper apps
     * To unpack use the counter part daemonVersion
     */
    var daemonVersion: String {
        let logger = IDDLog4swift.getLogger(self)
        let rv: String = {
            let json = [
                "CFBundleShortVersionString": Bundle.main[.info, "CFBundleShortVersionString", "1.0.1"],
                "CFBundleVersion": Bundle.main[.info, "CFBundleVersion", "1010"]
            ]

            do {
                let jsonBytes = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)

                return String(data: jsonBytes, encoding: .utf8)!
            } catch let error as NSError {
                logger.error("error: '\(error)'")
                logger.error("json: '\(json)'")
                return ""
            }
        }()

        logger.info("daemonVersion: '\(rv)'")
        return rv
    }
    
    func daemonVersion(fromJSON daemonVersionJSON: String) -> [String: String] {
        if let jsonBytes = daemonVersionJSON.data(using: .utf8) {
            let logger = IDDLog4swift.getLogger(self)
            
            do {
                if let daemonVersion = try JSONSerialization.jsonObject(with: jsonBytes, options: .allowFragments) as? [String : String] {
                    logger.info("result: '\(daemonVersion)'")
                    return daemonVersion
                }
            } catch let error as NSError {
                logger.error("error: '\(error)'")
                logger.error("daemonVersionJSON: '\(daemonVersionJSON)'")
            }
        }
        
        return ["CFBundleShortVersionString": "0.0.0", "CFBundleVersion": "0000"]
    }
    
    var isDevelopment: Bool {
        let build = URL.iddHomeDirectory.appendingPathComponent("Development/build").path
        
        if let executableURL = self.executableURL {
            return executableURL.path.hasPrefix(build)
        }
        
        return false
    }

    enum SectionType {
        case info
        case localizedInfo
    }
    
    // convenience access
    subscript<T>(from: SectionType, key:String, defaultValue: T) -> T {
        let dictionary: [String: Any]? = {
            switch from {
            case .info: return infoDictionary
            case .localizedInfo: return localizedInfoDictionary
            }
        }()
        if let dictionary = dictionary {
            guard let rv = dictionary[key] as? T
            else { return defaultValue }
            return rv
        }
        return defaultValue
    }

    var appVersion: AppVersion {
        return AppVersion()
    }
}

public extension Bundle {
    struct AppVersion {
        let id: String
        let name: String
        let version: String
        let buildNumber: String
        let startDate: String
        let buildDate: String

        init() {
            id = Bundle.main.bundleIdentifier ?? "com.mycompany.myapp"
            name = Bundle.main[.info, "CFBundleName", "myapp"]
            version = Bundle.main[.info, "CFBundleShortVersionString", "1.0.1"]
            buildNumber = Bundle.main[.info, "CFBundleVersion", "1010"]
            startDate = Date.init().stringWithDefaultFormat
            buildDate = Bundle.main.executableURL?.creationDate.stringWithDefaultFormat ?? "1968-05-25 12:00:00.001 -0500"
        }

        public var shortDescription: String {
            let rv = [
                "\(name) \(version)",
                "build: \(buildNumber)",
                "on: \(buildDate)",
                "started: \(startDate)"
            ]
            return rv.joined(separator: ", ")
        }
    }
}
