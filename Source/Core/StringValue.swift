//
//  StringValue.swift
//  ELWebService
//
//  Created by Manoj Kumar Mahapatra on 10/9/19.
//  Copyright © 2019 WalmartLabs. All rights reserved.
//

import Foundation

/// Types with obvious representation as a `String` should be conforming to this protocol.
public protocol StringValue {
    var stringValue: String { get }
}

extension String: StringValue {
    public var stringValue: String {
        return self
    }
}
extension StaticString: StringValue {
    public var stringValue: String {
        return "\(self)"
    }
}
extension Substring: StringValue {
    public var stringValue: String {
        return String(self)
    }
}
extension URL: StringValue {
    public var stringValue: String {
        return absoluteString
    }
}
extension Int: StringValue {
    public var stringValue: String {
        return "\(self)"
    }
}
extension Bool: StringValue {
    public var stringValue: String {
        return self ? "true" : "false"
    }
}
