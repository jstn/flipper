//
//  AppDelegate.swift
//  Flipper
//
//  Created by Justin Ouellette on 1/22/19.
//  Copyright © 2019 Justin Ouellette. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        RotateOperation.queue.underlyingQueue = DispatchQueue.global(qos: .userInitiated)
        RotateOperation.queue.maxConcurrentOperationCount = 4
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        RotateOperation.queue.waitUntilAllOperationsAreFinished()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
