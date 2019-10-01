//
//  Extensions.swift
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/9/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

import Foundation

//On the top of your swift
extension UIImage {
    func getPixelColor(point: CGPoint) -> UIColor {
        guard let pixelData = self.cgImage!.dataProvider!.data else {
            return UIColor.clear
        }
        let data = CFDataGetBytePtr(pixelData)
        let x = Int(point.x)
        let y = Int(point.y)
        let index = Int(self.size.width) * y + x
        let expectedLengthA = Int(self.size.width * self.size.height)
        let expectedLengthRGB = 3 * expectedLengthA
        let expectedLengthRGBA = 4 * expectedLengthA
        let numBytes = CFDataGetLength(pixelData)
        switch numBytes {
        case expectedLengthA:
            return UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat((data?[index])!)/255.0)
        case expectedLengthRGB:
            return UIColor(red: CGFloat((data?[3*index])!)/255.0, green: CGFloat((data?[3*index+1])!)/255.0, blue: CGFloat((data?[3*index+2])!)/255.0, alpha: 1.0)
        case expectedLengthRGBA:
            return UIColor(red: CGFloat((data?[4*index])!)/255.0, green: CGFloat((data?[4*index+1])!)/255.0, blue: CGFloat((data?[4*index+2])!)/255.0, alpha: CGFloat((data?[4*index+3])!)/255.0)
        default:
            // unsupported format
            return UIColor.clear
            
        }
    }
}

extension UIColor{
    func isEqualToColor(_ color: UIColor, withTolerance tolerance: CGFloat = 0.0) -> Bool{
        
        var r1 : CGFloat = 0
        var g1 : CGFloat = 0
        var b1 : CGFloat = 0
        var a1 : CGFloat = 0
        var r2 : CGFloat = 0
        var g2 : CGFloat = 0
        var b2 : CGFloat = 0
        var a2 : CGFloat = 0
        
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        print(abs(r1 - r2))
        print(abs(b1 - b2))
        print(abs(g1 - g2))
        print(abs(a1 - a2))
        return
            abs(r1 - r2) <= tolerance &&
                abs(g1 - g2) <= tolerance &&
                abs(b1 - b2) <= tolerance &&
                abs(a1 - a2) <= tolerance
    }
    
}
