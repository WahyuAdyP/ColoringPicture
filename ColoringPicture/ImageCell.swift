//
//  ImageCell.swift
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/5/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

import UIKit
import SVGKit

class ImageCell: UITableViewCell {
    
    @IBOutlet weak var layerView: LayerDrawingView!
    @IBOutlet weak var title: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(_ url: URL?) {
        title.text = url?.lastPathComponent.replacingOccurrences(of: ".svg", with: "")
        layerView.isUserInteractionEnabled = false
        
        let source = SVGKSourceURL.source(from: url)
        _ = SVGKImage.image(with: source, onCompletion: { loadedImage, parseResult in
            DispatchQueue.main.async(execute: {
                if let img = loadedImage {
                    let layerViewSize = self.layerView.frame.size
                    let imgSize = img.uiImage.size
                    
                    var scaling: CGFloat = 0
                    if imgSize.width > imgSize.height {
                        scaling = layerViewSize.width / imgSize.width
                    } else {
                        scaling = layerViewSize.height / imgSize.height
                    }
                    
                    self.layerView.scaleForCTM = scaling
                    self.layerView.drawingLayer = img.caLayerTree
                    self.layerView.savedIdentifier = (url?.lastPathComponent)!
                    self.layerView.updateColor(when: .last)
                }
            })
        })
    }

}
