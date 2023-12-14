//
//  MainWindowController.swift
//  PZJsonExport
//
//  Created by 邓榆麟 on 2023/12/14.
//  Copyright © 2023 z. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.delegate=self
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(self)
    }
}
