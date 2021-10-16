//
//  File.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 3/6/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import ZSTDSwift

// MARK: - Data -

extension Data {
    
    // https://github.com/aperedera/SwiftZSTD
    // the new supreme leader, twice if not thirce faster than zlibCompressed()
    //
    public var zlibCompressed: Data {
        let startDate = Date.init()
        var rv = Data()
        let processor = ZSTDProcessor(useContext: true)
        
        do {
            rv = try processor.compressBuffer(self, compressionLevel: 2)
        } catch ZSTDError.libraryError(let errStr) {
            Log4swift[Self.self].error("Library error: \(errStr)")
        } catch ZSTDError.invalidCompressionLevel(let lvl){
            Log4swift[Self.self].error("Invalid compression level: \(lvl)")
        } catch ZSTDError.decompressedSizeUnknown {
            Log4swift[Self.self].error("Unknown decompressed size")
        } catch {
            Log4swift[Self.self].error("Unknown error.")
        }
        
        //let rv = self.compress(withAlgorithm: .lzfse) ?? Data()
        //let rv = (self as NSData).zlibCompressed() as Data
        Log4swift[Self.self].info("in: '\(self.count.decimalFormatted)' out: '\(rv.count.decimalFormatted) bytes' in: '\(startDate.elapsedTime) ms'")
        return rv
    }
    
    public var zlibUncompressed: Data {
        let startDate = Date.init()
        var rv = Data()
        let processor = ZSTDProcessor(useContext: true)
        
        do {
            rv = try processor.decompressFrame(self)
        } catch ZSTDError.libraryError(let errStr) {
            Log4swift[Self.self].error("Library error: \(errStr)")
        } catch ZSTDError.invalidCompressionLevel(let lvl){
            Log4swift[Self.self].error("Invalid compression level: \(lvl)")
        } catch ZSTDError.decompressedSizeUnknown {
            Log4swift[Self.self].error("Unknown decompressed size")
        } catch {
            Log4swift[Self.self].error("Unknown error.")
        }
        
        //let rv = self.decompress(withAlgorithm: .lzfse) ?? Data()
        //let rv = (self as NSData).zlibUncompressed() as Data
        Log4swift[Self.self].info("in: '\(self.count.decimalFormatted)' out: '\(rv.count.decimalFormatted) bytes' in: '\(startDate.elapsedTime) ms'")
        return rv
    }
}
