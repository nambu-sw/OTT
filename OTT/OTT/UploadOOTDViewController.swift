//
//  UploadOOTDViewController.swift
//  OTT
//
//  Created by 김나연 on 2021/10/28.
//

import UIKit

class UploadOOTDViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clothesCell", for: indexPath) as? ClothesCell else {
            return UICollectionViewCell()
        }
        
        return cell
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
