//
//  UserDefaults.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 7/27/18.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

#if os(macOS)

import AppKit
import Log4swift

public class Dock {
    static public let shared = Dock.init()
    static let bundleIdentifier = "com.apple.dock"
    
    lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()

    public func addApplication(with path: String) -> Bool {
//        NSDictionary *domain = [self persistentDomainForName:@"com.apple.dock"];
//        NSArray *apps = [domain objectForKey:@"persistent-apps"];
//        NSArray *matchingApps = [apps filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K CONTAINS %@", @"tile-data.file-data._CFURLString", path]];
//        if ([matchingApps count] == 0) {
//            NSMutableDictionary *newDomain = [domain mutableCopy];
//            NSMutableArray *newApps = [[apps mutableCopy] autorelease];
//            NSDictionary *app = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"_CFURLString", [NSNumber numberWithInt:0], @"_CFURLStringType", nil] forKey:@"file-data"] forKey:@"tile-data"];
//            [newApps addObject:app];
//            [newDomain setObject:newApps forKey:@"persistent-apps"];
//            [self setPersistentDomain:newDomain forName:@"com.apple.dock"];
//            return [self synchronize];
//        }
        return false
    }
    
    public func removeApplication(with bundleIdentifier: String) -> Bool {
        if var domain = UserDefaults.standard.persistentDomain(forName: Dock.bundleIdentifier) {
            var newApps = [[String: Any]]()
            var removedApps = [[String: Any]]()

            if let apps = domain["persistent-apps"] as? [[String: Any]] {
                apps.forEach { (app) in
                    var append = true
                    
                    if logger.isDebug {
                        logger.debug("app: '\(app)'")
                    }
                    if let titleData = app["tile-data"] as? [String: Any] {
                        if let identifier = titleData["bundle-identifier"] as? String {
                            if identifier == bundleIdentifier {
                                logger.info("bundleIdentifier: '\(identifier)'")
                                append = false
                                removedApps.append(app)
                            }
                        }
                    }
                    if append {
                        newApps.append(app)
                    }
                }
                if apps.count != newApps.count {
                    logger.info("removedApps: '\(removedApps)'")
                    domain["persistent-apps"] = newApps
                    
                    UserDefaults.standard.setPersistentDomain(domain, forName: Dock.bundleIdentifier)
                    UserDefaults.standard.synchronize()
                    Process.killProcess(bundleIdentifier: Dock.bundleIdentifier)
                }
            }
        }
        return false
    }
}

#endif
