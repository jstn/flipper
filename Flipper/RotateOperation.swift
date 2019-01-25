//
//  RotateOperation.swift
//  Flipper
//
//  Created by Justin Ouellette on 1/22/19.
//  Copyright © 2019 Justin Ouellette. All rights reserved.
//

import Cocoa

class RotateOperation : Operation {
    static let queue = OperationQueue()
    static let tkhdData: Data = Data(bytes: [0x5C, 0x74, 0x6B, 0x68, 0x64]) // "\tkhd"
    static let mtrxData: Data = Data(bytes: [0x40]) // "@"
    static let rotations: [Int: Data] = [
        0: Data(bytes: [0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0]),
        90: Data(bytes: [0,0,0,0,0,1,0,0,0,0,0,0,255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]),
        180: Data(bytes: [255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0]),
        270: Data(bytes: [0,0,0,0,255,255,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
    ]
    
    private var rotation: Int
    private var path: String
    
    init(path: String, rotation: Int) {
        self.rotation = rotation
        self.path = path
        super.init()
    }
    
    override func main() {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                let directoryURL = URL(fileURLWithPath: path)
                if let contents = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                    for url in contents {
                        let op = RotateOperation(path: url.path, rotation: rotation)
                        RotateOperation.queue.addOperation(op)
                    }
                }
                
                return
            }
        } else {
            print("[\(path)] does not exist")
            return
        }
        
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            print("[\(path)] could not read file attributes")
            return
        }
        
        guard let fileSize = attributes[.size] as? NSNumber else {
            print("[\(path)] could determine file size")
            return
        }
        
        guard let fileHandle = FileHandle(forUpdatingAtPath: path) else {
            print("[\(path)] could not read file")
            return
        }
        
        var n: Int = 0
        var offset: Int = 0
        var tkhdIndex: Int? = nil
        var mtrxIndex: Int? = nil
        var buffer: Data? = nil
        let bufferLength: Int = 32768
        let fileLength: Int = Int(fileSize.uint64Value)

        while tkhdIndex == nil {
            autoreleasepool {
                n = n + 1
                offset = bufferLength * n
                if offset > fileLength {
                    offset = fileLength - bufferLength
                    tkhdIndex = 0 // last chance summer dance
                }
                fileHandle.seek(toFileOffset: UInt64(offset))
                buffer = fileHandle.readData(ofLength: bufferLength)
                if let range = buffer!.range(of: RotateOperation.tkhdData) {
                    tkhdIndex = range.lowerBound
                }
            }
        }
        
        if tkhdIndex! == 0 {
            print("[\(path)] could not find header")
            fileHandle.closeFile()
            return
        }
        
        let tkhdOffset: Int = (bufferLength * n) + tkhdIndex!
        fileHandle.seek(toFileOffset: UInt64(tkhdOffset))
        buffer = fileHandle.readData(ofLength: bufferLength)
        
        if let range = buffer!.range(of: RotateOperation.mtrxData) {
            mtrxIndex = range.lowerBound
        } else {
            print("[\(path)] could not find rotation matrix")
            fileHandle.closeFile()
            return
        }

        let mtrxOffset = UInt64(tkhdOffset + mtrxIndex! - 32)
        fileHandle.seek(toFileOffset: mtrxOffset)
        fileHandle.write(RotateOperation.rotations[rotation]!)
        fileHandle.closeFile()
    }
}
