//
//  FileManager.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 9/3/21.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

extension FileManager {
    // will fail if aFilePath is unreadable due to permissions ...
    //
    public func pathsFromVolumeRoot(_ fileURL: URL) -> [URL] {
        var currentURL = fileURL
        let currentUUID = currentURL.volumeUUID
        var rv = [currentURL]
        var crawlup = currentURL.path != "/"

        guard crawlup
        else { return rv }

        repeat {
            let parentURL = currentURL.deletingLastPathComponent()
            let parentUUID = currentURL.volumeUUID
            
            // IDDLogDebug(self, _cmd, @"parent.uuid: '%@', parent.filePath: '%@'", parentUUID, parentPath);
            if parentUUID != currentUUID {
                break
            }
            currentURL = parentURL
            rv.append(currentURL)
            crawlup = currentURL.path != "/"
        } while crawlup
        return rv
    }

    public func volumeRootPath(_ fileURL: URL) -> URL {
        return pathsFromVolumeRoot(fileURL).last ?? URL(fileURLWithPath: "")
    }
    
    public func pathsFromVolumeRoot(_ filePath: String) -> [String] {
        pathsFromVolumeRoot(URL(fileURLWithPath: filePath)).map(\.path)
    }
    
    public func volumeRootPath(_ filePath: String) -> String {
        return pathsFromVolumeRoot(filePath).last ?? ""
    }
    
//
//    /*
//     * '/Applications/Adobe InCopy CC 2015/Adobe InCopy CC 2015.app',
//     * '/Volumes/ElCap SM951/Applications/Adobe InCopy CC 2015/Adobe InCopy CC 2015.app',
//     * are the same
//     * '/' == '/Volumes/ElCap SM951'
//     */
//    - (NSString*)mountedPathForRootVolume:(BOOL)refetch {
//        @synchronized(self) {
//            if (refetch) {
//                _mountedPathForRootVolume = nil;
//            }
//            if (!_mountedPathForRootVolume) {
//                NSError*  error = nil;
//                NSArray*  mountedPaths = [self contentsOfDirectoryAtPath:@"/Volumes" error:nil];
//                NSDictionary*  attributes = [self attributesOfItemAtPath:@"/" error:&error];
//                NSInteger  fileSystemNumber = [[attributes valueForKey:NSFileSystemNumber] integerValue];
//
//                for (NSString* mountedName in mountedPaths) {
//                    NSString*  mountedPath = [@"/Volumes" stringByAppendingPathComponent:mountedName];
//                    BOOL  isDir = NO;
//
//                    if ([self fileExistsAtPath:mountedPath isDirectory:&isDir] && isDir) {
//                        NSDictionary*  attributes = [self attributesOfItemAtPath:mountedPath error:&error];
//                        NSInteger  fileSystemNumber_ = [[attributes valueForKey:NSFileSystemNumber] integerValue];
//
//                        if (fileSystemNumber == fileSystemNumber_) {
//                            _mountedPathForRootVolume = [mountedPath copy];
//                            break;
//                        }
//                    }
//                }
//                if (!_mountedPathForRootVolume) {
//                    _mountedPathForRootVolume = @"/";
//                }
//            }
//            return _mountedPathForRootVolume;
//        }
//    }
}
