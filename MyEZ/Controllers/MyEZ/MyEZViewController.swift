//
//  MyEZViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 9/22/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import SCLAlertView
import NVActivityIndicatorView


extension MyEZViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userUnits.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,  insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset = 15
        return UIEdgeInsets(top: CGFloat(inset), left: CGFloat(inset), bottom: CGFloat(inset), right: CGFloat(inset))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let sizeWidth = (imagesCollectionView.frame.width / 2) - 23
        let sizeHeight = sizeWidth + (sizeWidth * 0.1)

        return CGSize.init(width: sizeWidth, height: sizeHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UnitCell", for: indexPath) as! UnitCollectionViewCell

        let value = Array(userUnits.values)[indexPath.row]
        print (value.imageUnit.length)
        print (userUnits.count)
        
        
            _  = Array(userUnits.keys)[indexPath.row]
            cell.nameUnit.text = value.model
            cell.imageUnit.image = UIImage(data: value.imageUnit as Data)

            cell.contentView.layer.cornerRadius = 12.0
            cell.contentView.layer.borderWidth = 1.0
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 1.0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
       
        //guard let cell = collectionView.cellForItem(at: indexPath) else { return }
  
        selectedCell = indexPath.row
        guard let imageToShow = UIImage(data: (Array(userUnits.values)[self.selectedCell]).imageUnit as Data) else { return }
        let unitSelected = String(Array(userUnits.values)[self.selectedCell].model)
        
        
        let popOverVC = UIStoryboard(name: "MyEZ", bundle: nil).instantiateViewController(withIdentifier: "downoadMyez") as! DownloadMyezViewController
        
        popOverVC.imageSelected = imageToShow
        popOverVC.unitModelSelected = unitSelected
        
        self.addChild(popOverVC)
        popOverVC.view.frame = self.view.frame
        self.view.addSubview(popOverVC.view)
        popOverVC.didMove(toParent: self)
    }
}



class MyEZViewController: UIViewController{
    
    
    var modelUnit = ""
    let cellIdentifier = "UnitCell"
    var selectedCell = 0
    
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var ownedUnitsLabel: UILabel!
    @IBOutlet weak var addUnitsButton: UIButton!
    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var loadingIndicator: NVActivityIndicatorView!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showUnit":
            guard let detailViewController = segue.destination as? DownloadMyezViewController else { return }
            
            detailViewController.imageSelected = UIImage(data: (Array(userUnits.values)[selectedCell]).imageUnit as Data)!
            
        default: return
        }
    }
    
    
    @IBAction func addUnit(_ sender: UIButton) {
    
        refreshUnits(emailUer: userInformation.email)
        
        
//        let alert = SCLAlertView()//(appearance: appearance)
//
//        let serialToSearch = alert.addTextField("Serial Number")
//        serialToSearch.autocorrectionType = .no
//        serialToSearch.autocapitalizationType = .none
//        serialToSearch.spellCheckingType = .no
//        serialToSearch.keyboardType = UIKeyboardType.default
//
//        alert.addButton("Add") {
//
//            serialToSearch.text = (serialToSearch.text?.uppercased())!
//
//            if serialToSearch.text != "" {
//                self.searchSerial(serialToAdd: serialToSearch.text!)
//            } else {
//                let alert = SCLAlertView()
//                alert.showWarning("Missing Info", subTitle: "You have to type the serial number")
//            }
//        }
//        alert.showEdit("Add Unit",
//                       subTitle: "Enter the Serial Number of your unit",
//                       closeButtonTitle: "Cancel",
//                       colorStyle: 0x4c86fb,
//                       colorTextButton: 0xFFFFFF)
//
        
    }
    
    override func viewWillAppear(_ animated: Bool) {

        loadingIndicator.type = .ballClipRotateMultiple
        
        navigationController?.navigationBar.isHidden = true // for navigation bar hide

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isNewUser() == true {
            performSegue(withIdentifier: "myezWalk", sender: self)
        }

        imagesCollectionView.register(UINib(nibName: "UnitCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: cellIdentifier)

        if (userUnits.count != 0) {
            loadingIndicator.startAnimating()

            downloadUnitImages()
        }
        
        loadInfoHeader()
        

        print (userInformation.typeUser)
        categoryImage.image = UIImage(named: userInformation.typeUser)
       
    }
    
    func isNewUser() -> Bool{
        
        let preferences = UserDefaults.standard
        var newUser = false
        
        if preferences.object(forKey: "newUser") as? Bool == true {
            preferences.set(false, forKey: "newUser")
            newUser = true
        }
        return newUser
    }
    
    
    var unitImagesArray = [UIImage]()
    
    func downloadUnitImages() {
        
        let storage = Storage.storage()
        
        let storageRef = storage.reference()
        
        var count = 0
        
        let userUnitsTemp = userUnits
        print (userUnitsTemp)
        print (userUnits)
        
        for userUnit in userUnitsTemp {
            
            let path = "UnitImages/" + (userUnit.value.model) + ".jpg"
            print (path)

            // Create a reference to the file you want to download
            let islandRef = storageRef.child(path)

            // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
            islandRef.getData(maxSize: 1 * 1100 * 1100) { data, error in
                if let error = error {
                    // Uh-oh, an error occurred!
                    print (error)
                    count += 1
                } else {
                    // Data for "images/island.jpg" is returned
                    //self.unitImagesArray.append(UIImage(data: data!)!)
                    userUnits.updateValue(UnitInfo(model: userUnit.value.model , imageUnit: data! as NSData), forKey: userUnit.key)
                    count += 1
                    print (count)
                    if count == userUnitsTemp.count {
                        //self.imagesCollectionView.reloadData()
                        
                        self.imagesCollectionView.reloadData()
                        self.imagesCollectionView.collectionViewLayout.invalidateLayout() // or reloadData()

                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            self.backView.isHidden = true
                            
                        }
                    }
                }
            }
        }
    }
    
    func loadInfoHeader(){
        
        let weight = Int(userInformation.weight) ?? 0
        print (userInformation.typeUser)
        
        print (weight)
        userInformation.typeUser =  checkTypeUser(weightUnits: weight)
        print (userInformation.typeUser)
        categoryImage.image = UIImage(named: userInformation.typeUser)
        categoryLabel.text = userInformation.typeUser.uppercased()
        ownedUnitsLabel.text = "You own \(userInformation.weight) Pounds of inflatable"
    }

    func refreshUnits(emailUer: String) {
        
        //old address
        //let url = "https://spreadsheets.google.com/feeds/list/1NJcnjUVUAMErnngAsqqtDsPQHgZR7ZnicSncPZ-nAfc/od6/public/values?alt=json"
        
        let url = "https://spreadsheets.google.com/feeds/list/1_SzSNbdrNSpnW3WbHjh8Y0aiFwS1LbYHEYDVSW2srsQ/od6/public/values?alt=json"
        
        let urlObject = URL(string: url)
        
        var weightUpdated = 0
        
        if userUnits.count != 0 {
            loadingIndicator.startAnimating()
        }
        
        URLSession.shared.dataTask(with: urlObject!) {(data, response, error) in
            do {
                let units = try JSONSerialization.jsonObject(with: data!) as! [String : Any]
                
                if let feed = units["feed"] as? [String: Any]{
                    
                    if let entries = feed["entry"] as? [Any] {
                        
                        outer: for entry in entries {
                            
                            if let sales = entry as? [String: Any] {
                                
                                if let sale = sales["content"] as? [String: Any] {

                                    if let contents = sale["$t"] as? String {
                                        
                                        let content = (contents as AnyObject).components(separatedBy: ",")
                                        
                                        let emailContent = content[0].components(separatedBy: " ")
                                        
                                        let email = emailContent[1]
                                        
                                        if email == userInformation.email {
                                            let modelContent = content[1].components(separatedBy: " ")
                                            let model = modelContent[2]
                                            
                                            let weightContent = content[2].components(separatedBy: ": ")
                                            let weight = weightContent[1]
                                            
                                            let serialContent = content[3].components(separatedBy: ": ")
                                            let serial = serialContent[1]

                                            weightUpdated += Int(weight) ?? 0

                                            userUnits[serial] = UnitInfo(model: model, imageUnit: NSData())
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                self.updateInfo(weightUpdated: weightUpdated)
                
                DispatchQueue.main.async {
                    self.downloadUnitImages()
                    self.imagesCollectionView.reloadData()
                }
                
            } catch {
                print (error.localizedDescription)
            }
           
            DispatchQueue.main.async {
                let alert = SCLAlertView()
                alert.showSuccess("Done!", subTitle: "Library Updated",
                                  colorStyle: 0xc77306,
                                  colorTextButton: 0xFFFFFF)
            }
        }.resume()
    }
    
    
    func updateInfo(weightUpdated: Int) {
        
        
        print (userUnits.count)
        
        
        userInformation.typeUser =  checkTypeUser(weightUnits: weightUpdated)
        userInformation.weight = String(weightUpdated)

        print (weightUpdated)
        
        var ref : DatabaseReference!
        ref = Database.database().reference()
        
        ref.child("users").child(userInformation.userId).updateChildValues(["typeUser": userInformation.typeUser])
        ref.child("users").child(userInformation.userId).updateChildValues(["weightOwned": weightUpdated])
        
        for unit in userUnits {
          
            print (unit.key)
            print (unit.value)
            
            ref.child("users").child(userInformation.userId).child("units").updateChildValues([unit.key: unit.value.model])
        }
        
        self.loadInfoHeader()

    }
}

