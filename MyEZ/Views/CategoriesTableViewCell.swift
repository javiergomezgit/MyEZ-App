//
//  CategoriesTableViewCell.swift
//  MyEZ
//
//  Created by Javier Gomez on 8/27/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit

class CategoriesTableViewCell: UITableViewCell {

    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categoryImage: UIImageView!
    
    func setCategory(category: Category) {
        categoryImage.image = category.imageCategory
        categoryLabel.text = category.nameCategory
    }
    
}
