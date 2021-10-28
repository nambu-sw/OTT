//
//  UploadOOTDViewController.swift
//  OTT
//
//  Created by 김나연 on 2021/10/28.
//

import UIKit
import DropDown
import Alamofire
import SwiftyJSON
import RxSwift
import RxCocoa

class UploadOOTDViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var date:String? // 캘린더에서 받아온 날짜 데이터
    var category:String?
    var clothes:[[String:Any]]?
    var image_filename:String?
    
    let bag = DisposeBag()
    
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var categoryBtn: UIButton!
    @IBOutlet weak var ootdView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(date)
        guard let date = self.date else { return }
        dateLbl?.text = date
    }
    
    @IBAction func actBack(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func uploadOOTD(_ sender: Any) {
        // 코디 이미지 로컬 저장
        guard let image = ootdView.transfromToImage() else { return }
        
        let rotatedImage = rotateImage(image: image)
        let data = rotatedImage?.pngData() // 회전된 데이터
        try? data?.write(to: getFileName()) // try-catch문 : 에러 발생시 nil 반환 (예외 처리 안함)
        
        // 로컬에 저장된 이미지 DB에 저장
        guard let date = self.date,
              let image_filename = self.image_filename else { return }
        
        let strURL = "http://localhost:8000/ott/ootd/"
        let params:Parameters = ["date":date, "image_filename":image_filename, "image_desc":"-"]
        
        callAPI(strURL:strURL, method:.post, parameters: params) { value in
            let json = JSON(value)
            let result = json["success"].boolValue
            
            if result {
                self.showResult(title: "코디 등록", message: "코디 등록 성공")
            } else {
                self.showResult(title: "코디 등록", message: "코디 등록 실패")
            }
        }
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
            category = item
            categoryBtn.titleLabel?.text = "\(item)"
            
            // 옷 가져오기
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
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let clothes = self.clothes,
              let name = clothes[indexPath.row]["image_filename"] as? String else { return }
        
        var imageView:UIImageView!
        imageView = UIImageView(frame: CGRect(x:0, y:0, width:100, height:100))
        
        imageView.image = getSavedImage(named: name)
        imageView.layer.position = CGPoint(x:ootdView.bounds.width/2, y:ootdView.bounds.height/2)
        
        ootdView.addSubview(imageView)
        
        imageView.isUserInteractionEnabled = true
        setupInputBinding(myView:imageView)
    }
    
    private func setupInputBinding(myView:UIImageView) {
        let panGesture = UIPanGestureRecognizer()
        myView.addGestureRecognizer(panGesture)
        panGesture.rx.event.asDriver { _ in .never() }
        .drive(onNext: { [weak self] sender in
            guard let view = self?.view,
                  let senderView = sender.view else {
                      return
                  }
            
            // view에서 움직인 정보
            let transition = sender.translation(in: view)
            senderView.center = CGPoint(x: senderView.center.x + transition.x, y: senderView.center.y + transition.y)
            
            sender.setTranslation(.zero, in: view) // 움직인 값을 0으로 초기화
        }).disposed(by: bag)
    }
    
}

extension UIView {
    func transfromToImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
        defer {
            UIGraphicsEndImageContext()
        }
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }
}

extension UploadOOTDViewController:UINavigationControllerDelegate, UIImagePickerControllerDelegate {
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
        let filename = getDocuments().appendingPathComponent("ootd_\(uniquename).png")
        print(filename)
        image_filename = "ootd_\(uniquename).png"
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
