//
//  OOTDViewController.swift
//  OTT
//
//  Created by MIJI SUH on 2021/10/25.
//

import UIKit

class OOTDViewController: UIViewController {
    
    var date:String? // 캘린더에서 받아온 날짜 데이터
    
    @IBOutlet weak var dateLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let date = self.date else { return }
        dateLbl?.text = date
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVC = segue.destination as? UploadOOTDViewController {
            destVC.date = date
        }
        
    }
    
}
