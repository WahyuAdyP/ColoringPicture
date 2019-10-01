//
//  ColorCell.swift
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/3/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

import UIKit

class ColorCell: UICollectionViewCell {
    
    @IBOutlet weak var selectedView: UIImageView!
    
    override func prepareForReuse() {
        selectedView.isHidden = true
        selectedView.tintColor = UIColor.white
        self.backgroundColor = UIColor.white
        if let gradientLayer = self.layer.sublayers?[0] as? RadianGradientLayer, gradientLayer.name == "gradientLayer" {
            gradientLayer.removeFromSuperlayer()
        }
    }
    
    override var isSelected: Bool {
        didSet{
            updateSelected()
        }
    }
    
    func updateSelected() {
        selectedView.isHidden = !self.isSelected
        selectedView.tintColor = UIColor.white
        guard let backColor = self.backgroundColor else { return }
        let color = backColor.isLight ? UIColor.black : UIColor.white
        let imageTemplate = selectedView.image?.withRenderingMode(.alwaysTemplate)
        selectedView.image = imageTemplate
        selectedView.tintColor = color
    }
}

//extension UIColor {
//    func isLight() -> Bool {
//        guard let components = cgColor.components else { return false }
//        let count = components.count
//        
//        var redBrightness: CGFloat = 0
//        var greenBrightness: CGFloat = 0
//        var blueBrightness: CGFloat = 0
//        
//        if count == 2 {
//            redBrightness = ((components[0]) * 299)
//            greenBrightness = ((components[0]) * 587)
//            blueBrightness = ((components[0]) * 114)
//        } else {
//            redBrightness = components[0] * 299
//            greenBrightness = components[1] * 587
//            blueBrightness = components[2] * 114
//        }
//        
//        let brightness = (redBrightness + greenBrightness + blueBrightness) / 1000
//        return brightness > 0.5
//    }
//}
