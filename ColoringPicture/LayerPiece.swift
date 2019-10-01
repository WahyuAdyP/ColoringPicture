//
//  LayerPiece.swift
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/20/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

import Foundation

class ColorIdentity: NSObject, NSCoding {
    var point: CGPoint!
    var undoColor: [UIColor]!
    var redoColor: [UIColor]!
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        
        self.point = aDecoder.decodeCGPoint(forKey: "point")
        if let undoColor = aDecoder.decodeObject(forKey: "undoColor") as? [UIColor] { self.undoColor = undoColor }
        if let redoColor = aDecoder.decodeObject(forKey: "redoColor") as? [UIColor] { self.redoColor = redoColor }
    }
    
    convenience init(point: CGPoint, undoColor: [UIColor], redoColor: [UIColor]) {
        self.init()
        self.point = point
        self.undoColor = undoColor
        self.redoColor = redoColor
    }
    
    func encode(with coder: NSCoder) {
        if let point = point { coder.encode(point, forKey: "point") }
        if let undoColor = undoColor { coder.encode(undoColor, forKey: "undoColor") }
        if let redoColor = redoColor { coder.encode(redoColor, forKey: "redoColor") }
    }
}
