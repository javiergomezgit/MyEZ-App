//
//  UnitCollectionViewCell.swift
//  MyEZ
//
//  Created by Javier Gomez on 10/5/18.
//  Copyright © 2018 JDev. All rights reserved.
//

import UIKit

class UnitCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageUnit: UIImageView!
    @IBOutlet weak var nameUnit: UILabel!
    @IBOutlet weak var viewCell: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
