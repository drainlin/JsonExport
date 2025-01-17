//
//  PZParse.swift
//  PZJsonExport
//
//  Created by Pace.Z on 2018/4/14.
//  Copyright © 2018年 z. All rights reserved.
//

import AddressBook
import Cocoa
import SwiftyJSON

class PZJsonInfo {
    static let shared = PZJsonInfo()

    var rootClassName: String = "RootClass"
    var classPrefix: String?

    var classNames: [String] = []
    /// 字典中的数组映射表，key: 当前字典名, value 对应的数组名
    var mappingTable: [String: String] = [:]
    /// 关键字替换映射表，key 是类名，value 是对应关系数组.
    /// 如：id -> idField, value 是 [@"idField":@"id"]， key 是 A（类名）
    var mappingKeywordsTable: [String: [String]] = [String: Array]()
    /// key: className, value: @property (nonatomic,...) type *name;\n ...
    var headerInfo: [String: String] = [:]
    var messagesInfo: [String: String] = [:]

    private init() {}

    func removeAll() {
        classNames.removeAll()
        mappingTable.removeAll()
        headerInfo.removeAll()
        messagesInfo.removeAll()
        mappingKeywordsTable.removeAll()
    }

    func fileName(header: Bool = true) -> String {
        return rootClassName + (header ? ".h" : ".m")
    }
}

class PZParse {
    private let jsonInfo = PZJsonInfo.shared
    public let headerKey = "header"
    public let messagesKey = "messages"

    private func removeAll() {
        jsonInfo.removeAll()
    }

    func parse(_ jsonString: String, mode: OutputPropertyMode, handle: @escaping (_ content: [String: String]?, _ error: Error?) -> Void) {
        runOnBackground {
            guard let data = jsonString.data(using: String.Encoding.utf8) else {
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                // 清空之前的数据
                self.jsonInfo.removeAll()

                if let object = json as? [String: Any] {
                    if object.keys.isEmpty {
                        return
                    }
                    self.parse(json: JSON(object), mode: mode)
                } else if let object = json as? [Any], let first = object.first {
                    if object.isEmpty {
                        return
                    }
                    self.parse(json: JSON(first), mode: mode)
                }

                let header = [self.makeupCopyrights(header: true),
                              self.makeupRefrence(header: true),
                              self.makeupImplicitState(),
                              self.makeupHeaderClasses()].reduce("", +)
                let messages = [self.makeupCopyrights(header: false),
                                self.makeupRefrence(header: false),
                                self.makeupMessagesClasses()].reduce("", +)

                self.runOnUiThread {
                    handle([self.headerKey: header, self.messagesKey: messages], nil)
                }
            } catch {
                print(error.localizedDescription)
                self.runOnUiThread {
                    handle(nil, error)
                }
            }
        }
    }

    private func makeupCopyrights(header: Bool) -> String {
        var copyrights = "//\n//\t\(jsonInfo.fileName(header: header))\n"
        if let me = ABAddressBook.shared()?.me() {
            if let firstName = me.value(forProperty: kABFirstNameProperty as String) as? String {
                copyrights += "//\n//\tCreate by \(firstName)"
                if let lastName = me.value(forProperty: kABLastNameProperty as String) as? String {
                    copyrights += " \(lastName)"
                }
            }
            copyrights += " on \(getTodayFormattedDay())\n//\tCopyright © \(getYear())"
            if let organization = me.value(forProperty: kABOrganizationProperty as String) as? String {
                copyrights += " \(organization)"
            }
            copyrights += ". All rights reserved.\n//\n"
        }
        return copyrights
    }

    private func makeupRefrence(header: Bool) -> String {
        return header == true ? "\n#import <UIKit/UIKit.h>\n" : "\n#import \"\(jsonInfo.rootClassName).h\"\n"
    }

    private func makeupImplicitState() -> String {
        guard jsonInfo.classNames.count > 1 else {
            return ""
        }
        var implicitState = jsonInfo.classNames.reversed()
            .filter { key -> Bool in
                key != jsonInfo.rootClassName
            }.map { key -> String in
                (jsonInfo.classPrefix ?? "") + key.capitalizingFirstLetter() + ","
            }
            .reduce("\n@class ", +)
        let range: Range = implicitState.index(implicitState.endIndex, offsetBy: -1) ..< implicitState.endIndex
        implicitState.replaceSubrange(range, with: ";\n")
        return implicitState
    }

    private func makeupHeaderClasses() -> String {
        var tmpString = ""
        for className in jsonInfo.classNames.reversed() {
            let prefix = className != jsonInfo.rootClassName ? (jsonInfo.classPrefix ?? "") : ""
            tmpString.append("\n@interface \(prefix + className.capitalizingFirstLetter()) : NSObject \n\n")
            if let value = jsonInfo.headerInfo[className] {
                tmpString.append(value)
            }
            tmpString.append("\n@end\n")
        }
        return tmpString
    }

    private func makeupMessagesClasses() -> String {
        var tmpString = ""
        for className in jsonInfo.classNames.reversed() {
            let prefix = jsonInfo.classPrefix ?? ""
            if className == jsonInfo.rootClassName {
                tmpString.append("\n@implementation \(className.capitalizingFirstLetter())\n")
            } else {
                tmpString.append("\n@implementation \(prefix + className.capitalizingFirstLetter())\n")
            }
            if let mappingClassName = jsonInfo.mappingTable[className] {
                tmpString.append("\n+ (NSDictionary *)mj_objectClassInArray {\n \treturn @{@\"\(mappingClassName)\" : [\(prefix + mappingClassName.capitalizingFirstLetter()) class]};\n}\n")
            }
            if let mappingKeywords = jsonInfo.mappingKeywordsTable[className] {
                tmpString.append("\n+ (NSDictionary *)mj_replacedKeyFromPropertyName {\n \treturn @{\(mappingKeywords.map { $0 + "," }.reduce("", +))};\n}\n")
            }
            tmpString.append("\n@end\n")
        }

        return tmpString
    }
}

// MARK: - parse

private extension PZParse {
    /// 其中 json: JSON 是字典
    func parse(_ className: String? = nil, json: JSON, mode: OutputPropertyMode) {
        let shared = PZJsonInfo.shared
        var tmpClassName = shared.rootClassName
        if let tmpName = className {
            if !tmpName.isEmpty {
                tmpClassName = tmpName
            }
        }

        var headerInfoString = ""
        for (originName, subJson): (String, JSON) in json {
            var name = originName
            switch mode {
            case .DefaultMode:
                break
            case .LowerCamelMode:
                name = name.convertJsonKeyName(.camel)
            case .SnakeMode:
                name = name.convertJsonKeyName(.underscore)
            }
            var qualifier = ""
            var type = ""
            if name == "id" {
                print(name)
            }

            var key = name

            if check(name) == true {
                key += KEYWORDSUFFIX
                if jsonInfo.mappingKeywordsTable[tmpClassName] == nil {
                    jsonInfo.mappingKeywordsTable[tmpClassName] = ["@\"\(key)\":@\"\(name)\""]
                } else {
                    jsonInfo.mappingKeywordsTable[tmpClassName]?.append("@\"\(key)\":@\"\(name)\"")
                }
            }
            if mode != .DefaultMode && originName != name{
                
                if jsonInfo.mappingKeywordsTable[tmpClassName] == nil {
                    jsonInfo.mappingKeywordsTable[tmpClassName] = ["@\"\(name)\":@\"\(originName)\""]
                } else {
                    jsonInfo.mappingKeywordsTable[tmpClassName]?.append("@\"\(name)\":@\"\(originName)\"")
                }
            }

            switch subJson.type {
            case .array:
                qualifier = "strong"
                let first = subJson.arrayValue.first
                if first?.type == .dictionary {
                    type = "NSArray <\(jsonInfo.classPrefix ?? "")\(key.capitalizingFirstLetter()) *> *"
                    shared.mappingTable[tmpClassName] = key
                    parse(key, json: first!, mode: mode)
                } else if first?.type == .string {
                    type = "NSArray <NSString *> *"
                } else if first?.type == .number {
                    type = "NSArray <NSNumber *> *"
                } else {
                    type = "NSArray *"
                }
            case .dictionary:
                qualifier = "strong"
                type = "\(jsonInfo.classPrefix ?? "")\(key.capitalizingFirstLetter()) *"
                parse(key, json: subJson, mode: mode)
            case .string:
                qualifier = "copy"
                type = "NSString *"
            case .number:
                qualifier = "assign"
                let tmpNumber: NSNumber = subJson.numberValue
                if String(cString: tmpNumber.objCType) == "d" ||
                    String(cString: tmpNumber.objCType) == "f" {
                    type = "CGFloat"
                } else {
                    type = "NSInteger"
                }
            case .bool:
                qualifier = "assign"
                type = "BOOL"
            default:
                qualifier = "strong"
                type = "NSObject *"
            }
            headerInfoString.append("@property (nonatomic, \(qualifier)) \(type) \(key);\n")
        }
        shared.headerInfo[tmpClassName] = headerInfoString
        if shared.classNames.contains(tmpClassName) == false {
            shared.classNames.append(tmpClassName)
        }
    }

    /// 检测属性名是否包含关键字
    func check(_ property: String) -> Bool {
        var tmpString = false
        for keyword in KEYWORDS {
            if keyword == property {
                tmpString = true
                break
            }
        }
        return tmpString
    }
}

// MARK: - From JSONExport: https://github.com/Ahmed-Ali/JSONExport

private extension PZParse {
    /// Returns the current year as String
    func getYear() -> String {
        return "\((Calendar.current as NSCalendar).component(.year, from: Date()))"
    }

    /// Returns today date in the format dd/mm/yyyy
    func getTodayFormattedDay() -> String {
        let components = (Calendar.current as NSCalendar).components([.day, .month, .year], from: Date())
        return "\(components.year!)/\(components.month!)/\(components.day!)"
    }

    func runOnBackground(_ task: @escaping () -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            task()
        }
    }

    func runOnUiThread(_ task: @escaping () -> Void) {
        DispatchQueue.main.async { () in
            task()
        }
    }
}
