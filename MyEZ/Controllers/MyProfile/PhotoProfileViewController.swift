//
//  PhotoProfileViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 9/24/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit
import YPImagePicker
import AVFoundation
import AVKit

class PhotoProfileViewController: UIViewController {

    @IBOutlet weak var imageProfile: UIImageView!
    
    override func viewDidLoad() {
        showPicker()
    }
    
    func showPicker() {
        
        var config = YPImagePickerConfiguration()
        
        /* Set this to true if you want to force the  library output to be a squared image. Defaults to false */
        config.library.onlySquare = true
        
        /* Set this to true if you want to force the camera output to be a squared image. Defaults to true */
        config.onlySquareImagesFromCamera = true
        
        /* Ex: cappedTo:1024 will make sure images from the library or the camera will be
         resized to fit in a 1024x1024 box. Defaults to original image size. */
        config.targetImageSize = .cappedTo(size: 1024)
        config.targetImageSize = .cappedTo(size: 800)
        
        /* Choose what media types are available in the library. Defaults to `.photo` */
        config.library.mediaType = .photo
        
        /* Enables selecting the front camera by default, useful for avatars. Defaults to false */
        // config.usesFrontCamera = true
        
        /* Adds a Filter step in the photo taking process. Defaults to true */
        config.showsPhotoFilters = false
        
        /* Enables you to opt out from saving new (or old but filtered) images to the
         user's photo library. Defaults to true. */
        config.shouldSaveNewPicturesToAlbum = false
        
        /* Defines which screen is shown at launch. Video mode will only work if `showsVideo = true`.
         Default value is `.photo` */
        config.startOnScreen = .photo
        
        /* Defines which screens are shown at launch, and their order.
         Default value is `[.library, .photo, .video]` */
        config.screens = [.photo, .library]
        
        /* Adds a Crop step in the photo taking process, after filters. Defaults to .none */
        //config.showsCrop = .rectangle(ratio: (16/9))
        config.showsCrop = .rectangle(ratio: (1/1))
        
        /* Defines the overlay view for the camera. Defaults to UIView(). */
        // let overlayView = UIView()
        // overlayView.backgroundColor = .red
        // overlayView.alpha = 0.3
        // config.overlayView = overlayView
        
        /* Customize wordings */
        config.wordings.libraryTitle = "Gallery"
        
        /* Defines if the status bar should be hidden when showing the picker. Default is true */
        config.hidesStatusBar = false
        
        /* Defines if the bottom bar should be hidden when showing the picker. Default is false */
        config.hidesBottomBar = false
        
        config.library.maxNumberOfItems = 5
        
        /* Disable scroll to change between mode */
        // config.isScrollToChangeModesEnabled = false
        //        config.library.minNumberOfItems = 2
        config.library.maxNumberOfItems = 1
        
        /* Skip selection gallery after multiple selections */
        config.library.skipSelectionsGallery = true
        
        let picker = YPImagePicker(configuration: config)
        
        
        picker.didFinishPicking { [unowned picker] items, cancelled in
            
            if cancelled {
                picker.dismiss(animated: true, completion: nil)
                _ = self.navigationController?.popViewController(animated: true)
                return
            }
            
            if let photo = items.singlePhoto {
                print(photo.fromCamera) // Image source (camera or library)
                print(photo.image) // Final image selected by the user
                print(photo.originalImage) // original image selected by the user, unfiltered
                print(photo.modifiedImage) // Transformed image, can be nil
                print(photo.exifMeta) // Print exif meta data of original image.
                
                self.imageProfile.image = photo.image
                
                self.saveImageDocumentDirectory()
                
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true, completion: nil)
                                
                
            }
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
        
    }
    
    func saveImageDocumentDirectory(){
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("MyEZProfileImage.png")
        let image =  self.imageProfile.image //UIImage(named: "MyEZProfileImage.png")
        print(paths)
        let imageData = image?.pngData()
        fileManager.createFile(atPath: paths as String, contents: imageData, attributes: nil)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "showProfileScreen" {
//            let dvc = segue.destination as! MyProfileViewController
//            dvc.newImageGroup = self.imageGroup.image
//        }
//    }


}
