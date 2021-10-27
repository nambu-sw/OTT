//
//  UploadViewController.swift
//  OTT
//
//  Created by MIJI SUH on 2021/10/26.
//

import UIKit
import DropDown

class UploadViewController: UIViewController {

    let picker = UIImagePickerController()
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var categoryBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categoryBtn.layer.shadowColor = UIColor.gray.cgColor
        categoryBtn.layer.shadowOpacity = 1.0
        categoryBtn.layer.shadowOffset = CGSize.zero
        categoryBtn.layer.shadowRadius = 6
        categoryBtn.layer.cornerRadius = 10

        picker.delegate = self
    }
    
    @IBAction func dropdown(_ sender: Any) {
        let dropDown = DropDown()
        
        dropDown.dataSource = ["모자", "아우터", "상의", "하의", "신발", "가방"]
        dropDown.anchorView = categoryBtn
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        dropDown.width = 150
        dropDown.textColor = UIColor.black
        dropDown.selectedTextColor = UIColor.blue
        dropDown.textFont = UIFont.systemFont(ofSize: 20)
        dropDown.backgroundColor = UIColor.white
        dropDown.selectionBackgroundColor = UIColor.white
        dropDown.cellHeight = 50
        dropDown.cornerRadius = 15
        dropDown.show()
        
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            print("선택한 아이템 : \(item)")
            print("인덱스 : \(index)")
            dropDown.clearSelection()
            categoryBtn.titleLabel?.text = "\(item)"
        }
    }
    
    @IBAction func uploadImage(_ sender: Any) {
        let alert = UIAlertController(title: "알림", message: "선택하세요", preferredStyle: .actionSheet)
                
                let action1 = UIAlertAction(title: "사진 촬영하기", style: .default) { _ in
                    self.picker.sourceType = .camera
                    self.present(self.picker, animated: true)
                    
                }
                
                let action2 = UIAlertAction(title: "포토 라이브러리에서 사진 가져오기", style: .default) { _ in
                    self.picker.sourceType = .photoLibrary
                    self.present(self.picker, animated: true)
                }
                
                let action3 = UIAlertAction(title: "사진 앨범에서 사진 가져오기", style: .default) { _ in
                    self.picker.sourceType = .savedPhotosAlbum
                    self.present(self.picker, animated: true)
                }
                
                let action4 = UIAlertAction(title: "취소", style: .cancel)

                alert.addAction(action1)
                alert.addAction(action2)
                alert.addAction(action3)
                alert.addAction(action4)
                
                present(alert, animated: true)
    }
}

extension UploadViewController:UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 이미지 정보가 info로 들어옴
        guard let image = info[.originalImage] as? UIImage else { return } // Any 타입에서 형변환
            
        imageView?.image = image
            
        dismiss(animated: true) // present의 반대
    }
}
