//
//  RadianGradientLayer.swift
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/5/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

import UIKit

class RadianGradientLayer: CALayer {
    
    override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }
    
    init(center: CGPoint, radius: CGFloat, colors: [CGColor]){
        
        self.center = center
        self.radius = radius
        self.colors = colors
        
        super.init()
        
        self.setNeedsDisplay()
        
    }
    
    init(frame: CGRect) {
        super.init()
        self.frame = frame
        
        self.setNeedsDisplay()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
    }
    
    var center: CGPoint = CGPoint(x: 50, y: 50) {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var radius: CGFloat = 20 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var colors: [CGColor] = [UIColor(red: 251/255, green: 237/255, blue: 33/255, alpha: 1.0).cgColor, UIColor(red: 251/255, green: 179/255, blue: 108/255, alpha: 1.0).cgColor] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(in context: CGContext) {
        
        context.saveGState()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0,1.0]) else { return }
        
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)
        
    }
}
