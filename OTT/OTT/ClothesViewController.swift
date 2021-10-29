//
//  ClothesViewController.swift
//  OTT
//
//  Created by MIJI SUH on 2021/10/26.
//

import UIKit
import Alamofire
import SwiftyJSON

class ClothesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var category:String?
    var clothes:[[String:Any]]?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var removeBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let category = self.category,
              let category_name = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let strURL = "http://localhost:8000/ott/clothes/\(category_name)"
        callAPI(strURL:strURL, method:.get) { value in
            let json = JSON(value)
            // let result = json["success"].boolValue
            self.clothes = json["data"].arrayObject as? [[String:Any]]
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    @IBAction func actBack(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func actRemove(_ sender: Any) {
        if let selectedCells = collectionView.indexPathsForSelectedItems {
            // 1
            let items = selectedCells.map { $0.item }.sorted().reversed()
            // 2
            for item in items {
                guard let clothes = self.clothes else { return }
                let clothe = clothes[item]
                print(clothe)
                let id = clothe["id"] as? Int
                let strURL = "http://localhost:8000/ott/clothes/\(id!)"
                
                callAPI(strURL:strURL, method:.delete) { value in
                    let json = JSON(value)
                    // let result = json["success"].boolValue
                }
                // modelData.remove(at: item)
            }
            // 3
            collectionView.deleteItems(at: selectedCells)
            removeBtn.isEnabled = false
            
            DispatchQueue.main.async {
                self.viewWillAppear(true)
            }
        }
    }
    
    func callAPI(strURL:String, method:HTTPMethod, parameters:Parameters?=nil, headers:HTTPHeaders?=nil, handler:@escaping (Any)->()) {
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
    
    func getSavedImage(named: String) -> UIImage? {
        if let dir: URL
            = try? FileManager.default.url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: false) {
            let path: String
            = URL(fileURLWithPath: dir.absoluteString)
                .appendingPathComponent(named).path
            let image: UIImage? = UIImage(contentsOfFile: path)

            return image
        }
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let clothes = self.clothes {
            return clothes.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clothesCell", for: indexPath) as? ClothesCell else {
            return UICollectionViewCell()
        }
        
        guard let clothes = self.clothes,
              let name = clothes[indexPath.row]["image_filename"] as? String else { return cell }
        
        cell.imgView.image = getSavedImage(named: name)
        cell.isInEditingMode = isEditing
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isEditing {
            removeBtn.isEnabled = false
        } else {
            removeBtn.isEnabled = true
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.count == 0 {
            removeBtn.isEnabled = false
        }
    }
 
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        collectionView.allowsMultipleSelection = editing
        let indexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in indexPaths {
            let cell = collectionView.cellForItem(at: indexPath) as! ClothesCell
            cell.isInEditingMode = editing
        }
    }

}
