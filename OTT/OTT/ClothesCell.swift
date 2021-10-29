//
//  ClothesCell.swift
//  OTT
//
//  Created by MIJI SUH on 2021/10/27.
//

import UIKit

class ClothesCell: UICollectionViewCell {
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var checkLbl: UILabel!
    
    var isInEditingMode: Bool = false {
        didSet {
            checkLbl.text = ""
            checkLbl.isHidden = !isInEditingMode
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isInEditingMode {
                checkLbl.text = isSelected ? "✓" : ""
            }
        }
    }
}
