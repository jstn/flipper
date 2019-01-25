//
//  DropView.swift
//  Flipper
//
//  Created by Justin Ouellette on 1/22/19.
//  Copyright © 2019 Justin Ouellette. All rights reserved.
//

import Cocoa

class DropView : NSView {
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var dropdownMenu: NSPopUpButton!
    private var observation: NSKeyValueObservation?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
        observation = RotateOperation.queue.observe(\.operationCount, options: [.new, .old], changeHandler: { [weak self] (queue, change) in
            guard let self = self else { return }

            if change.newValue! <= 0 {
                DispatchQueue.main.async { [weak self] in
                    if let self = self {
                        self.progressIndicator.stopAnimation(nil)
                        NSSound(named: "flipper")?.play()
                    }
                }
            } else if change.oldValue! == 0 {
                DispatchQueue.main.async { [weak self] in
                    if let self = self {
                        self.progressIndicator.startAnimation(nil)
                    }
                }
            }
        })
    }
    
    deinit {
        unregisterDraggedTypes()
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        layer?.backgroundColor = NSColor.selectedControlColor.cgColor
        return NSDragOperation.copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        layer?.backgroundColor = NSColor.clear.cgColor

        if RotateOperation.queue.operationCount > 0 {
            return false
        }

        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if RotateOperation.queue.operationCount > 0 {
            return false
        }

        let t = NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")
        if let board = sender.draggingPasteboard.propertyList(forType: t) as? NSArray {
            for path in board {
                let op = RotateOperation(path: path as! String, rotation: dropdownMenu.selectedItem!.tag)
                RotateOperation.queue.addOperation(op)
            }
        }

        return true
    }
}
