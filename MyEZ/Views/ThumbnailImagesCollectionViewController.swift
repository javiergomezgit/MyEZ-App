//
//  ThumbnailImagesCollectionViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 9/5/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit

class ThumbnailImagesCollectionViewController: UICollectionViewController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "thumbnailCell", for: indexPath) as! ThumbnailImagesCollectionViewCell

        cell.thumbnailImageView.image = UIImage(named: "AppIcon")

        return cell
    }
    
    
}
