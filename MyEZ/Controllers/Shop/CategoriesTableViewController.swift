//
//  CategoriesTableViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 8/27/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit

class CategoriesTableViewController: UIViewController {

    @IBOutlet weak var tableCategories: UITableView!
    @IBOutlet weak var subcategoriesView: UIView!
    @IBOutlet weak var subcategoriesStackView: UIStackView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    var categories: [Category] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        createArray()
        
        let label1 = UILabel()
        label1.text = "helo"
        label1.backgroundColor = .orange
        label1.textAlignment = .center
        
        let button1 = UIButton()
        button1.backgroundColor = .red
        button1.titleLabel?.text = "but"
        
        subcategoriesStackView.addArrangedSubview(label1)
        subcategoriesStackView.addArrangedSubview(button1)
        
        let nib = UINib.init(nibName: "CategoriesTableViewCell", bundle: nil)
        self.tableCategories.register(nib, forCellReuseIdentifier: "CategoriesCell")
    }
    
    func createArray() {
        
        let categoriesImages = [UIImage(named: "WS"), UIImage(named: "G"), UIImage(named: "IPS"), UIImage(named: "C"), UIImage(named: "B"), UIImage(named: "I"), UIImage(named: "IB"), UIImage(named: "A"), UIImage(named: "S"), UIImage(named: "SS")]
        
        let categoriesNames = ["WATER SLIDES", "GAMES", "INTERACTIVE PLAY SYSTEM", "COMBOS", "BOUNCERS", "OBSTACLE COURSE", "CUSTOM INFLATABLES", "ACCESSORIES", "SLIDES", "SLIP & SLIDES"]
        
        for i in 0...categoriesNames.count-1 {
            categories.append(Category(imageCategory: categoriesImages[i]!, nameCategory: categoriesNames[i]))
        }
    }
}

extension CategoriesTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoriesCell", for: indexPath) as! CategoriesTableViewCell
        
        let category = categories[indexPath.row]
        
        cell.setCategory(category: category)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print (indexPath.row)
        print (categories[indexPath.row].nameCategory)
        
        heightConstraint.constant = 0
        for subview in subcategoriesView.subviews {
            subview.removeFromSuperview()
        }
    }
}


class Category{

    var imageCategory: UIImage
    var nameCategory: String
    
    init(imageCategory: UIImage, nameCategory: String) {
        self.imageCategory = imageCategory
        self.nameCategory = nameCategory
    }
}
