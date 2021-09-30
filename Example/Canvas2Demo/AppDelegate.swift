//
//  AppDelegate.swift
//  Canvas2Demo
//
//  Created by ViTiny on 2020/7/31.
//  Copyright © 2020 ViTiny. All rights reserved.
//

import Cocoa
import Canvas2

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var app: NSApplication!
    
    var viewController: ViewController? { app.mainWindow?.contentViewController as? ViewController }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    @IBAction func selectAll(_ sender: Any) {
        viewController?.canvasView?.selectAllItems()
    }
    
}

