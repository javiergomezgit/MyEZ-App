//
//  SpecialsCustomCell.swift
//  MyEZ
//
//  Created by Javier Gomez on 7/24/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit

class DealsCustomCell: UITableViewCell {
    
    @IBOutlet weak var dealImageView: UIImageView!
    @IBOutlet weak var dealLabel: UILabel!
    
    
    func setDeals(deal: Deals) {
        dealImageView.image = deal.dealImage
        dealLabel.text = deal.dealTitle
    }
}

class Deals {
    
    var dealImage: UIImage
    var dealTitle: String
    var dealURL: String
    
    init(image: UIImage, title: String, url: String) {
        self.dealImage = image
        self.dealTitle = title
        self.dealURL = url
    }
}
