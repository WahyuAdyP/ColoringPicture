//
//  ImageListVC.swift
//  ColoringPicture
//
//  Created by Crocodic MBP-2 on 1/5/18.
//  Copyright © 2018 Crocodic. All rights reserved.
//

import UIKit

class ImageListVC: UIViewController {
    
    var imageDatas = [URL?]()
    var imgs = [String]()
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        print(OpenCVWrapper().openCVVersionString() ?? "")
        
        tableView.dataSource = self
        tableView.delegate = self
        
        let tiger = Bundle.main.url(forResource: "awesome_tiger", withExtension: "svg")
        let pizza = Bundle.main.url(forResource: "pizza", withExtension: "svg")
        let flower = Bundle.main.url(forResource: "hawaiiFlowers-3", withExtension: "svg")
        
        imgs.append("image13.PNG")
        imgs.append("supersonic-drawings.png")
        imgs.append("10 Gra (2).png")
        imgs.append("powder_baby.png")
        for i in 1 ... 13 {
            imgs.append("img\(i).jpg")
        }
//        imgs.append("scatch_img.jpg")
//        imgs.append("te.jpg")
        
        imageDatas.append(tiger)
        imageDatas.append(pizza)
        imageDatas.append(flower)
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ImageListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imgs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
        cell.imageView?.image = UIImage(named: imgs[indexPath.row])
        cell.textLabel?.text = imgs[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ImageCell
//        cell.setup(imageDatas[indexPath.row])
        return cell
    }
}

extension ImageListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ColoringPicture") as! MyViewController
//        vc.imageUrl = imageDatas[indexPath.row]
        vc.imgName = imgs[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
