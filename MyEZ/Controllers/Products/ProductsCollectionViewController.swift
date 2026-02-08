//
//  ProductsCollectionViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 8/29/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit

struct Product {
    var imageName: String
}

class ProductsCollectionViewController: UIViewController {
    
    let reuseIdentifier = "Cell"
    var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet var collectionView: UICollectionView!
    
    var products: [Product] = [Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon"),
                               Product(imageName: "AppIcon")]
    
    let viewProductSegue = "viewProducSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        setupCollectionView()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        setupCollectionViewItemSize()
    }

    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let nib = UINib(nibName: "ProductCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: reuseIdentifier)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let item = sender as? Product
        
        if segue.identifier == viewProductSegue {
            if let vc = segue.destination as? ProductViewController {
                vc.imageName = item?.imageName
            }
        }
    }
    
    private func setupCollectionViewItemSize() {
        if collectionViewFlowLayout == nil {
            
            self.collectionView.backgroundColor = UIColor(red: 241/255, green: 241/255, blue: 241/255, alpha: 1.0)//UIColor(red: 241, green: 241, blue: 241, alpha: 1.0)
            
//            let numberOfItemForRow: CGFloat = 3
//            let lineSpacing: CGFloat = 1
//            let interItemSpacing: CGFloat = 1
//
//            let width = (collectionView.frame.width - (numberOfItemForRow - 1) * interItemSpacing) / numberOfItemForRow
//            let height = width * 1.30
//
//            collectionViewFlowLayout = UICollectionViewFlowLayout()
//            collectionViewFlowLayout.itemSize = CGSize(width: width, height: height)
//            collectionViewFlowLayout.sectionInset = UIEdgeInsets.zero
//            collectionViewFlowLayout.scrollDirection = .vertical
//            collectionViewFlowLayout.minimumLineSpacing = lineSpacing
//            collectionViewFlowLayout.minimumInteritemSpacing = interItemSpacing
//
//            collectionView.setCollectionViewLayout(collectionViewFlowLayout, animated: true)
            
        }
    }
}


extension ProductsCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
   
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ProductCollectionViewCell
        
        cell.productImageView.image = UIImage(named: products[indexPath.row].imageName)
        cell.salePriceLabel.text = "$ 898,344"
        cell.reguarPriceLabel.text = "$ 898,344"
        cell.nameProductLabel.text = "Other Name not so long maybe or maybe-ws1230-ip"
        
        if indexPath.row == 2 {
            cell.favoriteImageView.image = UIImage(named: "IconHeart")
            cell.inStockImageView.alpha = 0
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print (indexPath.row)
        
        let item = products[indexPath.item]
        performSegue(withIdentifier: viewProductSegue, sender: item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let sizeWidth = (collectionView.frame.width / 2) - 22
        let sizeHeight = sizeWidth * 1.4
        
        print (sizeWidth)
        print(sizeHeight)
        
        return CGSize.init(width: sizeWidth, height: sizeHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,  insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset = 14
        return UIEdgeInsets(top: CGFloat(inset), left: CGFloat(inset), bottom: CGFloat(inset), right: CGFloat(inset))
    }
    
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//
//        return 10
//    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return CGFloat(10)
//    }
}




// MARK: UICollectionViewDelegate

/*
 // Uncomment this method to specify if the specified item should be highlighted during tracking
 override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
 return true
 }
 */

/*
 // Uncomment this method to specify if the specified item should be selected
 override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
 return true
 }
 */

/*
 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
 override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
 return false
 }
 
 override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
 return false
 }
 
 override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
 
 }
 */
