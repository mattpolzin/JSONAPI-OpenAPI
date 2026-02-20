//
//  SwiftCodeRepresentable.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 7/27/19.
//

import Foundation
import SwiftFormat

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
        let formatter = SwiftFormatter(configuration: configuration)
        var output = ""
        try formatter.format(contentsOf: tmpFilepath, to: &output)

        return output
    }
}

fileprivate let configuration: Configuration = {
    var configuration = Configuration()
    configuration.tabWidth = 4
    configuration.indentation = .spaces(4)
    return configuration
}()
