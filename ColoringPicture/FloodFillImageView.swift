//
//  FloodFillImageView.swift
//  HalloWorld
//
//  Created by Crocodic MBP-2 on 1/6/18.
//  Copyright © 2018 Crocodic Studio. All rights reserved.
//

import UIKit

class FloodFillImageView: UIImageView {

    var tolorance: Int = 100
    var newColor: UIColor = UIColor.white
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        self.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        self.addGestureRecognizer(pan)
        
        self.isUserInteractionEnabled = true
    }
    
    override init(image: UIImage?) {
        super.init(image: image)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        self.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        self.addGestureRecognizer(pan)
        
        self.isUserInteractionEnabled = true
    }
    
    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        self.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        self.addGestureRecognizer(pan)
        
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func panGesture(_ pan: UIPanGestureRecognizer) {
        var tpoint = pan.location(in: self)
        tpoint.x = tpoint.x * 2
        tpoint.y = tpoint.y * 2
        
        let pixelColor = image!.getPixelColor(point: tpoint)
        if pixelColor == UIColor.init(red: 0, green: 0, blue: 0, alpha: 1) {
            return
        }
        
        let image1: UIImage? = image?.floodFill(from: tpoint, with: newColor, andTolerance: tolorance, andActionTap: false, sameImage: { (isSame) in
            print("Same image")
        })
        
        DispatchQueue.main.async(execute: {
            self.image = image1
        })
        
        print(tpoint)
    }
    
    @objc func tapGesture(_ tap: UITapGestureRecognizer) {
        var tpoint = tap.location(in: self)
        tpoint.x = tpoint.x * 2
        tpoint.y = tpoint.y * 2
        
        let pixelColor = image!.getPixelColor(point: tpoint)
        
        if pixelColor == UIColor.init(red: 0, green: 0, blue: 0, alpha: 1) {
            return
        }
        
        let image1: UIImage? = image?.floodFill(from: tpoint, with: newColor, andTolerance: tolorance, andActionTap: true, sameImage: { (isSame) in
            print("Same image")
        })
        
        DispatchQueue.main.async(execute: {
            self.image = image1
        })
    }
    
    
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        //  Converted with Swiftify v1.0.6491 - https://objectivec2swift.com/
//        //Get touch Point
//        
//        var tpoint: CGPoint = (event!.allTouches?.first?.location(in: self))!
//        //Convert Touch Point to pixel of Image
//        //This code will be according to your need
//        tpoint.x = tpoint.x * 2
//        tpoint.y = tpoint.y * 2
//        //Call function to flood fill and get new image with filled color
//        
//        let pixelColor = image!.getPixelColor(pos: tpoint)
//        
//        print(pixelColor)
//        print(UIColor.init(red: 0, green: 0, blue: 0, alpha: 1))
//        if pixelColor == UIColor.init(red: 0, green: 0, blue: 0, alpha: 1) {
//            print("tap on black color")
//            return
//        }
//        
//        let image1: UIImage? = image?.floodFill(from: tpoint, with: newColor, andTolerance: tolorance)
//        
//        DispatchQueue.main.async(execute: {(_: Void) -> Void in
//            self.image = image1
//        })
//
//    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

