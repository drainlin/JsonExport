//
//  ViewController.swift
//  PZJsonExport
//
//  Created by z on 2018/4/12.
//  Copyright © 2018年 z. All rights reserved.
//

import AddressBook
import Cocoa
import SwiftyJSON

class ViewController: NSViewController, NSTextViewDelegate, NSUserNotificationCenterDelegate {
    @IBOutlet var inputScrollView: NSScrollView!
    @IBOutlet var inputTextView: NSTextView!
    @IBOutlet var headerScrollView: NSScrollView!
    @IBOutlet var headerTextView: NSTextView!
    @IBOutlet var messagesScrollView: NSScrollView!
    @IBOutlet var messagesTextView: NSTextView!
    @IBOutlet var validJsonTipsTF: NSTextField!
    @IBOutlet var tipsTextField: NSTextField!

    @IBOutlet var keywordDropFix: NSTextField!
    @IBOutlet var defaultRadio: NSButton!
    @IBOutlet var snakeRadio: NSButton!
    @IBOutlet var lowerCamleRadio: NSButton!
    @IBAction func saveFiles(_ sender: NSButton) {
        saveFiles()
    }

    @IBAction func rootClassChanged(_ sender: NSTextField) {
        PZJsonInfo.shared.rootClassName = sender.stringValue.count > 0 ? sender.stringValue : "RootClass"
        parse()
    }

    @IBAction func keywordDropFixChanged(_ sender: Any) {
        parse()
    }

    @IBAction func classPrefixChanged(_ sender: NSTextField) {
        PZJsonInfo.shared.classPrefix = sender.stringValue
        parse()
    }

    @IBAction func selectLowerCalme(_ sender: Any) {
        switchPropertyOutputMode(type: .LowerCamelMode)
    }

    @IBAction func selectSnack(_ sender: Any) {
        switchPropertyOutputMode(type: .SnakeMode)
    }

    @IBAction func selectDefault(_ sender: Any) {
        switchPropertyOutputMode(type: .DefaultMode)
    }

    let parser = PZParse()
    var statementString: String = ""
    var classes = [String]()
    var classInfo: [String: String] = [:]
    var mapTable: [String: String] = [:]
    var mode: OutputPropertyMode = .DefaultMode

    var validJson: Bool? {
        didSet {
            if validJson == true {
                self.tipsTextField.textColor = NSColor.green
                self.tipsTextField.stringValue = "JSON格式正确"
            } else {
                self.tipsTextField.textColor = NSColor.red
                self.tipsTextField.stringValue = "JSON格式有误"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        [inputScrollView, headerScrollView, messagesScrollView].forEach { scrollView in
            let lineNumberView = NoodleLineNumberView(scrollView: scrollView)
            scrollView?.hasHorizontalRuler = false
            scrollView?.hasVerticalRuler = true
            scrollView?.verticalRulerView = lineNumberView
            scrollView?.rulersVisible = true
        }

        [headerTextView, messagesTextView].forEach { textView in
            textView?.font = NSFont.systemFont(ofSize: 14)
            textView?.isAutomaticQuoteSubstitutionEnabled = false
        }

        inputTextView.isAutomaticQuoteSubstitutionEnabled = false
        inputTextView.delegate = self
        inputTextView.becomeFirstResponder()
    }

    func textDidChange(_ notification: Notification) {
        let droplast = keywordDropFix.stringValue.replacingOccurrences(of: " ", with: "")
        if droplast != "" {
            KEYWORDSUFFIX = droplast
        } else {
            KEYWORDSUFFIX = "Field"
        }
        parse()
    }

    func parse() {
        guard inputTextView.string.count > 0 else { return }
        parser.parse(inputTextView.string, mode: mode) { result, _ in
            if let dictionary = result {
                self.validJson = true
                self.headerTextView.string = dictionary[self.parser.headerKey]!
                self.messagesTextView.string = dictionary[self.parser.messagesKey]!
            } else {
                self.validJson = false
            }
        }
    }
}

// MARK: - From JSONExport: https://github.com/Ahmed-Ali/JSONExport

extension ViewController {
    func saveFiles() {
        guard headerTextView.string.count > 0 && messagesTextView.string.count > 0 else {
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.allowsOtherFileTypes = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.prompt = "保存"
        openPanel.beginSheetModal(for: view.window!) { response in
            if response.rawValue == NSFileHandlingPanelOKButton {
                self.saveToPath(openPanel.url!.path)
                self.showDoneSuccessfully()
            }
        }
    }

    /**
     Saves all the generated files in the specified path

     - parameter path: in which to save the files
     */
    func saveToPath(_ path: String) {
        var error: NSError?

        for (idx, content) in [headerTextView.string, messagesTextView.string].enumerated() {
            let fileContent = content

            let fileExtension = [PZJsonInfo.shared.fileName(header: true), PZJsonInfo.shared.fileName(header: false)][idx]

            let filePath = "\(path)/\(fileExtension)"

            do {
                try fileContent.write(toFile: filePath, atomically: false, encoding: String.Encoding.utf8)
            } catch let error1 as NSError {
                error = error1
            }
            if error != nil {
                showError(error!)
                break
            }
        }
    }

    // MARK: - Messages

    /**
     Shows the top right notification. Call it after saving the files successfully
     */
    func showDoneSuccessfully() {
        let notification = NSUserNotification()
        notification.title = "保存成功!"
        notification.informativeText = "你的模型文件已经保存到指定文件夹"
        notification.deliveryDate = Date()

        let center = NSUserNotificationCenter.default
        center.delegate = self
        center.deliver(notification)
    }

    // MARK: - NSUserNotificationCenterDelegate

    func userNotificationCenter(_ center: NSUserNotificationCenter,
                                shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }

    /**
     Shows an NSAlert for the passed error
     */
    func showError(_ error: NSError!) {
        if error == nil {
            return
        }
        let alert = NSAlert(error: error)
        alert.runModal()
    }

    func switchPropertyOutputMode(type: OutputPropertyMode) {
        switch type {
        case .DefaultMode:
            lowerCamleRadio.state = .off
            snakeRadio.state = .off
            defaultRadio.state = .on
        case .LowerCamelMode:
            lowerCamleRadio.state = .on
            snakeRadio.state = .off
            defaultRadio.state = .off
        case .SnakeMode:
            lowerCamleRadio.state = .off
            snakeRadio.state = .on
            defaultRadio.state = .off
        }
        mode = type
        parse()
    }
}
