//
//  OOTDViewController.swift
//  OTT
//
//  Created by MIJI SUH on 2021/10/25.
//

import UIKit
import Alamofire
import SwiftyJSON

class OOTDViewController: UIViewController {
    var mainViewController:MainViewController?
    var date:String? // 캘린더에서 받아온 날짜 데이터
    var isOOTDExisting = false
    var ootd:[String:String]?
    
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let date = self.date else { return }
        dateLbl?.text = date
        
        // 코디 불러오기
        guard let date = self.date,
              let date = date.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let strURL = "http://localhost:8000/ott/ootd/\(date)"
        callAPI(strURL:strURL, method:.get) { value in
            let json = JSON(value)
            print(json)
            let result = json["success"].boolValue
            if result == true {
                self.isOOTDExisting = true
            }
            self.ootd = json["data"].dictionaryObject as? [String:String]
            
            guard let ootd = self.ootd,
                let image_filename = ootd["image_filename"] as? String else { return }
            
            print(image_filename)
            self.imageView.image = self.getSavedImage(named: image_filename)
        }
    }
    
    @IBAction func actBack(_ sender: Any) {
        self.mainViewController?.viewWillAppear(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVC = segue.destination as? UploadOOTDViewController {
            destVC.date = date
            destVC.isOOTDExisting = isOOTDExisting
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
    
}
