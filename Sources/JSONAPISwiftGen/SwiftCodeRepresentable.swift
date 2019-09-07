//
//  SwiftCodeRepresentable.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 7/27/19.
//

import Foundation
import SourceKittenFramework

public protocol SwiftCodeRepresentable {
    var swiftCode: String { get }
}

public extension SwiftCodeRepresentable {
    func formattedSwiftCode() throws -> String {
        // the Swift code needs to live in a file
        // for the sourcekit daemon to refer to it.

        let tmpFilename = "./tmpOut"
        let tmpFilepath = URL(fileURLWithPath: tmpFilename)
        try swiftCode.write(to: tmpFilepath, atomically: true, encoding: .utf8)
        try File(path: tmpFilename)!
            .format(trimmingTrailingWhitespace: true,
                    useTabs: false,
                    indentWidth: 4)
            .write(to: tmpFilepath, atomically: true, encoding: .utf8)

        let readBack = try String(contentsOf: tmpFilepath)
        try FileManager.default.removeItem(at: tmpFilepath)
        return readBack
    }
}
