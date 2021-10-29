//
//  CategoryViewController.swift
//  OTT
//
//  Created by MIJI SUH on 2021/10/26.
//

import UIKit
import Alamofire
import SwiftyJSON

class CategoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var categories:[[String:Any]]?
    var categoryCnt:Int?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categoryTf: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let strURL = "http://localhost:8000/ott/category/"
        
        callAPI(strURL:strURL, method:.get) { value in
            let json = JSON(value)
            // let result = json["success"].boolValue
            self.categoryCnt = json["count"].intValue
            self.categories = json["data"].arrayObject as? [[String:Any]]
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func actBack(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func addCategory(_ sender: Any) {
        guard let category_name = categoryTf.text else { return }
        
        let strURL = "http://localhost:8000/ott/category/"
        let params:Parameters = ["category_name":category_name]
        
        callAPI(strURL:strURL, method:.post, parameters: params) { value in
            let json = JSON(value)
            // let result = json["success"].boolValue
            self.categoryCnt = json["count"].intValue
            self.categories = json["data"].arrayObject as? [[String:Any]]
            
            DispatchQueue.main.async {
                self.viewWillAppear(true)
                self.categoryTf.text = ""
            }
        }
    }
    
    func callAPI(strURL:String, method:HTTPMethod, parameters:Parameters?=nil, headers:HTTPHeaders?=nil, handler:@escaping (Any)->()) { // 다른 곳에서 실행될 수도 있으므로
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let categoryCnt = self.categoryCnt {
            print(categoryCnt)
            return categoryCnt
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)

        guard let categories = self.categories else { return cell }
        
        let category = categories[indexPath.row]
        let name = category["category_name"] as? String
        
        let lbl = cell.viewWithTag(1) as? UILabel
        lbl?.text = name
        
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let categories = self.categories else { return }
            
            let category = categories[indexPath.row]
            guard let name = category["category_name"] as? String,
                  let category_name = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            
            let strURL = "http://localhost:8000/ott/category/\(category_name)"
            
            callAPI(strURL:strURL, method:.delete) { value in
                let json = JSON(value)
                // let result = json["success"].boolValue
                self.categoryCnt = json["count"].intValue
                
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.endUpdates()
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVC = segue.destination as? ClothesViewController,
           let selectdeIndex = self.tableView.indexPathForSelectedRow?.row {
            guard let categories = self.categories else { return }
            let category = categories[selectdeIndex]
            let selectedCategory = category["category_name"] as? String
            destVC.category = selectedCategory
        }
    }

}
