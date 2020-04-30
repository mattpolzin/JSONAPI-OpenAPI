//
//  TestSuiteConfiguration.swift
//  
//
//  Created by Mathew Polzin on 4/29/20.
//

import Foundation

public struct TestSuiteConfiguration: Equatable {
    /// If `non-nil`, this will be the host that all API requests are
    /// made against. If `nil`, either the server defined by the OpenAPI
    /// documentation will be used or a test-specific override defined in
    /// `x-tests` will be usd.
    public let apiHostOverride: URL?

    public init(apiHostOverride: URL? = nil) {
        self.apiHostOverride = apiHostOverride
    }
}
