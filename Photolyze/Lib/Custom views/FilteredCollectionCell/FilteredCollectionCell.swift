//
//  FilteredCollectionCell.swift
//  Photolyze
//
//  Created by Mac on 05.09.2019.
//  Copyright © 2019 Lammax. All rights reserved.
//

import UIKit
import CoreImage



class FilteredCollectionCell: UICollectionViewCell {
    
    private let context = CIContext()
    let asyncQueue = DispatchQueue(label: "com.lammax.ios_\(Date())", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem)
    
    private var filter: CIFilter?
    
    // MARK: ImageForFilterDelegate
    var currentFilteredImage: CIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var metalView: VideoMetalView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(filterName: String?) {
        self.layoutIfNeeded()
        
        if let label = self.textLabel {
            label.text = filterName
        }
        
        if let filterName = filterName {
            self.filter = CIFilter(name: filterName)
        }
    }
    
    private func doFilterUsual(with image: CIImage) {
        asyncQueue.async {
            self.filter?.setValue(image, forKey: kCIInputImageKey)
            if let ciImage = self.filter?.value(forKey: kCIOutputImageKey) as? CIImage,
               let cgImage = self.context.createCGImage(ciImage, from: ciImage.extent) {
                DispatchQueue.main.async {
                    self.currentFilteredImage = ciImage
                    self.imageView.image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
                }
            } else {
                DispatchQueue.main.async {
                    self.currentFilteredImage = image
                    self.imageView.image = nil
                }
            }
        }
    }
    
    private func doFilterMetal(with image: CIImage) {
        asyncQueue.async {
            self.filter?.setValue(image, forKey: kCIInputImageKey)
            if let ciImage = self.filter?.value(forKey: kCIOutputImageKey) as? CIImage {
                self.currentFilteredImage = ciImage
                ciImage.oriented(.right)
                DispatchQueue.main.async {
                    self.metalView.image = ciImage
                }
            } else {
                self.currentFilteredImage = image
                DispatchQueue.main.async {
                    self.metalView.image = nil
                }
            }
        }
    }

}

extension FilteredCollectionCell: ImageForFilterDelegate {
    func update(with image: CIImage) {
        self.doFilterUsual(with: image)
        //self.doFilterMetal(with: image)
    }
}
