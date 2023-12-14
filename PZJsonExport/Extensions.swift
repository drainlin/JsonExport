//
//  Extension+String.swift
//  PZJsonExport
//
//  Created by 邓榆麟 on 2023/12/13.
//  Copyright © 2023 z. All rights reserved.
//

import Foundation
extension String {
    private var camelName: String {
        var result = ""
        var flag = false
        forEach { c in
            let s = String(c)
            if s == "_" {
                flag = true
            } else {
                if flag {
                    result += s.uppercased()
                    flag = false
                } else {
                    result += s
                }
            }
        }
        return result
    }

    private var underscore_name: String {
        var result = ""
        forEach { c in
            let num = c.unicodeScalars.map { $0.value }.last!
            let s = String(c)
            if num > 64 && num < 91 {
                result += "_"
                result += s.lowercased()
            } else {
                result += s
            }
        }
        return result
    }

    enum JsonKeyType {
        case camel, underscore
    }

     func convertJsonKeyName(_ keyType: JsonKeyType) -> String {
         if(keyType == .camel){
             return self.snakeCaseToCamelCase(self)
         }else{
             return self.camelCaseToSnakeCase(self)
         }
    }
    private func camelCaseToSnakeCase(_ input: String) -> String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: input.count)

        var snakeCase = regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "$1_$2")
        snakeCase = snakeCase.lowercased()

        return snakeCase
    }

    private func snakeCaseToCamelCase(_ input: String) -> String {
        var components = input.components(separatedBy: "_")
        guard let firstComponent = components.first else {
            return input
        }

        let camelCase = components.dropFirst().reduce(firstComponent) { result, component in
            return result + component.capitalizingFirstLetter()
        }

        return camelCase
    }
}
extension String {
    public func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    public mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }
}

enum OutputPropertyMode {
    case DefaultMode
    case LowerCamelMode
    case SnakeMode
}
