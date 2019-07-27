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
        return try File(contents: self.swiftCode).format(trimmingTrailingWhitespace: false,
                                                         useTabs: true,
                                                         indentWidth: 4)
    }
}
