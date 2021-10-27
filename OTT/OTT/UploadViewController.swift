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
            category_name = item
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
    
    // 로컬에 저장한 이미지의 파일 url로 DB에 저장
    @IBAction func saveImage(_ sender: Any) {
        guard let image_filename = self.image_filename else { return }
        guard let image_desc = self.descTf.text else { return }
        guard let category_name = self.category_name else { return }
        
//        guard let category_name = self.category_name else { return }
//        guard let category = category_name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let strURL = "http://localhost:8000/ott/clothes/"
        let params:Parameters = ["image_filename":image_filename, "image_desc":image_desc, "category_name":category_name]
        
        callAPI(strURL:strURL, method:.post, parameters: params) { value in
            let json = JSON(value)
            let result = json["success"].boolValue
            
            if result {
                self.showResult(title: "사용자 등록", message: "사용자 등록 성공")
            } else {
                self.showResult(title: "사용자 등록", message: "사용자 등록 실패")
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
    
}

extension UploadViewController:UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 이미지 정보가 info로 들어옴
        guard let image = info[.originalImage] as? UIImage else { return } // Any 타입에서 형변환
        
        imageView?.image = image
        
        dismiss(animated: true) // present의 반대
        
        // 데이터 로컬에 저장하기
        let rotatedImage = rotateImage(image: image)
        let data = rotatedImage?.pngData() // 회전된 데이터
        try? data?.write(to: getFileName()) // try-catch문 : 에러 발생시 nil 반환 (예외 처리 안함)
    }
    
    // 폴더 경로
    func getDocuments() -> URL {
        // 이미지 url 가져오기
        // 폴더 경로 가져오기 - Document
        // 반환: [URL] -> 해당하는 폴더들이 반환
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) // 사용자가 사용할 수 있는 폴더 -> 1개만 존재
        return urls[0]
    }
    
    // 파일 경로
    func getFileName() -> URL {
        // full path 생성
        // let filename = getDocuments().appendingPathComponent("test.png")
        
        // 파일 이름 중복 처리 -> 날짜로 하거나 process info
        let uniquename = ProcessInfo.processInfo.globallyUniqueString
        let filename = getDocuments().appendingPathComponent("image_\(uniquename).png")
        print(filename)
        image_filename = "image_\(uniquename).png"
        return filename
    }
    
    // 이미지 회전
    func rotateImage(image:UIImage)->UIImage? {
        if(image.imageOrientation == .up) {// orientation: 방향
            return image
        }
        
        // 'up'이 아니면 다시 그려서 캡쳐해서 반환
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size)) // 좌표 설정 -> 원점
        
        let copy = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return copy
    }
}

extension UIViewController { // UIViewController 상속 받은 모든 곳에서 사용 가능
    func showResult(title:String, message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "확인", style: .default)
        alert.addAction(action1)
        
        self.present(alert, animated: true)
    }
}
