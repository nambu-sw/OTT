//
//  UploadViewController.swift
//  OTT
//
//  Created by MIJI SUH on 2021/10/26.
//

import UIKit
import DropDown
import Alamofire
import SwiftyJSON

class UploadViewController: UIViewController {
    
    var mainViewController:MainViewController?
    
    let picker = UIImagePickerController()
    var category_name:String?
    var image_filename:String?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var categoryBtn: UIButton!
    @IBOutlet weak var descTf: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categoryBtn.layer.shadowColor = UIColor.gray.cgColor
        categoryBtn.layer.shadowOpacity = 1.0
        categoryBtn.layer.shadowOffset = CGSize.zero
        categoryBtn.layer.shadowRadius = 6
        categoryBtn.layer.cornerRadius = 10
        
        picker.delegate = self
    }
    
    @IBAction func actBack(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func dropdown(_ sender: Any) {
        let dropDown = DropDown()
        var dataSource:[String] = []
        
        let strURL = "http://localhost:8000/ott/category/"
        
        callAPI(strURL:strURL, method:.get) { value in
            let json = JSON(value)
            // let result = json["success"].boolValue
            let categories = json["data"].arrayObject as? [[String:String]]
            
            for category in categories! {
                let name = category["category_name"]
                dataSource.append(name!)
            }
            
            dropDown.dataSource = dataSource
            dropDown.anchorView = self.categoryBtn
            dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
            dropDown.width = 150
            dropDown.textColor = UIColor.gray
            dropDown.selectedTextColor = UIColor.black
            // dropDown.textFont = UIFont.systemFont(ofSize: 20)
            if let font = UIFont(name: "NotoSerifKR-Regular", size: 15) {
                dropDown.textFont = font
            }
            // dropDown.backgroundColor = UIColor.white
            // dropDown.selectionBackgroundColor = UIColor.white
            dropDown.cellHeight = 40
            dropDown.cornerRadius = 15
            dropDown.show()
            
            dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
                print("????????? ????????? : \(item)")
                print("????????? : \(index)")
                dropDown.clearSelection()
                category_name = item
                categoryBtn.titleLabel?.text = "\(item)"
            }
        }
    }
    
    @IBAction func uploadImage(_ sender: Any) {
        let alert = UIAlertController(title: "??????", message: "???????????????", preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "?????? ????????????", style: .default) { _ in
            self.picker.sourceType = .camera
            self.present(self.picker, animated: true)
        }
        
        let action2 = UIAlertAction(title: "?????? ????????????????????? ?????? ????????????", style: .default) { _ in
            self.picker.sourceType = .photoLibrary
            self.present(self.picker, animated: true)
        }
        
        let action3 = UIAlertAction(title: "?????? ???????????? ?????? ????????????", style: .default) { _ in
            self.picker.sourceType = .savedPhotosAlbum
            self.present(self.picker, animated: true)
        }
        
        let action4 = UIAlertAction(title: "??????", style: .cancel)
        
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(action3)
        alert.addAction(action4)
        
        present(alert, animated: true)
    }
    
    @IBAction func saveImage(_ sender: Any) {
        // ????????? ????????? ????????????
        guard let image = imageView.image else { return }
        let rotatedImage = rotateImage(image: image)
        let data = rotatedImage?.pngData() // ????????? ?????????
        try? data?.write(to: getFileName()) // try-catch??? : ?????? ????????? nil ?????? (?????? ?????? ??????)
        
        // ????????? ????????? ???????????? ?????? url??? DB??? ??????
        guard let image_filename = self.image_filename else { return }
        guard let image_desc = self.descTf.text else { return }
        guard let category_name = self.category_name else { return }
        
        let strURL = "http://localhost:8000/ott/clothes/"
        let params:Parameters = ["image_filename":image_filename, "image_desc":image_desc, "category_name":category_name]
        
        callAPI(strURL:strURL, method:.post, parameters: params) { value in
            let json = JSON(value)
            let result = json["success"].boolValue
            
            if result {
                self.showResult(title: "??? ??????", message: "??? ?????? ??????")
            } else {
                self.showResult(title: "??? ??????", message: "??? ?????? ??????")
            }
        }
    }
    
    func callAPI(strURL:String, method:HTTPMethod, parameters:Parameters?=nil, headers:HTTPHeaders?=nil, handler:@escaping (Any)->()) { // ?????? ????????? ????????? ?????? ????????????
        let alamo = AF.request(strURL, method:method, parameters: parameters)
        alamo.responseJSON { response in
            switch response.result {
            case .success(let value):
                handler(value)
            case .failure(let error):
                print(error.errorDescription)
            }
        }
    }
    
}

extension UploadViewController:UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // ????????? ????????? info??? ?????????
        guard let image = info[.originalImage] as? UIImage else { return } // Any ???????????? ?????????
        
        imageView?.image = image
        
        dismiss(animated: true) // present??? ??????
    }
    
    // ?????? ??????
    func getDocuments() -> URL {
        // ????????? url ????????????
        // ?????? ?????? ???????????? - Document
        // ??????: [URL] -> ???????????? ???????????? ??????
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) // ???????????? ????????? ??? ?????? ?????? -> 1?????? ??????
        return urls[0]
    }
    
    // ?????? ??????
    func getFileName() -> URL {
        // full path ??????
        // let filename = getDocuments().appendingPathComponent("test.png")
        
        // ?????? ?????? ?????? ?????? -> ????????? ????????? process info
        let uniquename = ProcessInfo.processInfo.globallyUniqueString
        let filename = getDocuments().appendingPathComponent("clothes_\(uniquename).png")
        print(filename)
        image_filename = "clothes_\(uniquename).png"
        return filename
    }
    
    // ????????? ??????
    func rotateImage(image:UIImage)->UIImage? {
        if(image.imageOrientation == .up) {// orientation: ??????
            return image
        }
        
        // 'up'??? ????????? ?????? ????????? ???????????? ??????
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size)) // ?????? ?????? -> ??????
        
        let copy = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return copy
    }
}

extension UIViewController { // UIViewController ?????? ?????? ?????? ????????? ?????? ??????
    func showResult(title:String, message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "??????", style: .default)
        alert.addAction(action1)
        
        self.present(alert, animated: true)
    }
}
