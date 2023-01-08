//
//  URL+Tilde.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 10/22/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

extension URL {
    /// Expanding tilde in URL
    ///
    /// ```
    /// +--------+----------------------------------------------------+
    /// | Input  |            ~/Documents/git.id-design.com/whatsize7 |
    /// | Input  |           /~/Documents/git.id-design.com/whatsize7 |
    /// +--------+----------------------------------------------------+
    ///     v
    /// +--------+----------------------------------------------------+
    /// | Output | /Users/kdeda/Documents/git.id-design.com/whatsize7 |
    /// +--------+----------------------------------------------------+
    /// ```
    /// - Precondition: The URL should be a file url or a string url that starts with `~/` or `/~/`.
    /// If the URL is empty or starts with the FileManager.default.homeDirectoryForCurrentUser.path ew return self.
    /// - Returns: The `URL` if we'r able to expand the ~ into a full URL, or `nil` if we'r unable do so
    public var expandingTilde: URL? {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        var components = self.pathComponents

        // if we are empty or begin with the home path do nothing
        guard !components.isEmpty, !self.path.hasPrefix(homePath)
        else {
            // well convert to a isFileURL
            return URL.init(fileURLWithPath: self.path)
        }
        
        guard let index = components.firstIndex(where: { $0 == "~"})
        else { return nil }

        (0 ... index).forEach { _ in
            components.remove(at: 0)
        }
        components.insert(homePath, at: 0)
        return URL.init(fileURLWithPath: components.joined(separator: "/"))
    }
}
