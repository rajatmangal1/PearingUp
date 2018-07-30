//
//  MakePostViewController.swift
//  Pearing_Up
//
//  Created by waz on 2018-06-27.
//  Copyright © 2018 Manan Maniyar. All rights reserved.
// change made

import UIKit
import Alamofire
import SwiftyJSON

class MakePostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let myGroup = DispatchGroup()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextView: UITextField!
    @IBOutlet weak var descriptionTextView: UITextField!
    @IBOutlet weak var locationTextView: UITextField!
    @IBOutlet weak var fruitPickerView: UIPickerView!
    
    var fileLocation : NSURL!
    var id : String = ""
    let url = "https://pearingup.herokuapp.com/"
    
    let fruit = ["Almond" , "Apple" , "Apricot", "Avocado", "Blood Orange", "Cherry", "Citron", "Feijoa", "Fig", "Grapefruit", "Hardy Citrus","Jujube", "Kaffir Lime", "Kiwi", "Kumquat","Lemon", "Lime","Loquat", "Mandarin Orange", "Medlar", "Mulberry", "Navel Orange", "Nectarine", "Olive", "Pawpaw", "Peach", "Pear", "Persimmon", "Plum", "Pomegranate","Quince" , "Sour Orange"]
    
    var pickedFruit = "Almond"
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        
        label.text = fruit[row]
        
        return label
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return fruit[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fruit.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //label.text = fruit[row] // fruit[row] is what is selected
        pickedFruit = fruit[row]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        myGroup.notify(queue: .main) {
            self.update_data()
        }
    }
    
    func update_data() {
        //self.bookmarked_posts.dataSource = self
        //bookmarked_posts.reloadData()
        print("Data Reloaded")
    }
    
    
    @IBAction func CreatePost(_ sender: Any) {
        myGroup.enter()
        if(titleTextView.text == "" ){
            print("title field required")
            displayAlert(message: "title field required")
            return
        }
        else if(locationTextView.text == ""){
            print("location field required")
            displayAlert(message: "location field required")
            return
        }
        else if(imageView.image == nil ){
            print("image required")
            displayAlert(message: " image required")
            return
        }
        else{
            //UPLOAD PICTURE
            let imageData = UIImageJPEGRepresentation(self.imageView.image!, 0.2)!
            upload_data(imageData : imageData) { responseId in
                self.id = responseId.string!
                
                print("https://pearingup.herokuapp.com/upload/")
                let info_param : [String: String] = ["fruits":self.pickedFruit]
                print(self.pickedFruit)
                let username = User.Data.username
                
                let title = self.titleTextView.text!.replacingOccurrences(of: " ", with: "_")
                
                let user_params : [String: Any] = ["owner": username, "info": info_param, "additional_msg": self.descriptionTextView.text!,"title":title]
                
                //UPLOAD POST
                let url_post = "https://pearingup.herokuapp.com/uploadPostDetails/" + self.id
                print(url_post)
                self.makePost(url: url_post, params: user_params)
                self.myGroup.leave()
                self.performSegue(withIdentifier: "uploadToExplore", sender: self)
            }
        }
    }
    
    
    //Completion handler to retrieve json response data
    func uploadData(url : String, params : [String : Any], completion: @escaping (JSON) -> Void){
        Alamofire.request(url, method: .post, parameters: params).responseJSON{
            response in
            if response.result.isSuccess{
                print("---------if response result issuccess-----------")
                completion(JSON(response.result.value!))
            }
            else{
                print("error occured")
            }
        }
    }
    
    func makePost(url: String, params: [String : Any]){
        self.myGroup.enter()
        
        uploadData(url: url, params: params) { response in
            // Do your stuff here
            let temp : JSON = response
            
            print(temp)
            
            // this  is the most is made successfully
            
            if( temp["code"].exists() ){
                print("---------if temp code exists-----------")
                
                if(temp["code"] == 409){
                    self.displayAlert(message: "server errror-------------------")
                }
            }
            if( temp["id"].exists() ){
                
                self.id = temp["id"].string!
            }
            
        }
        self.myGroup.leave()
    }
    
    func upload_data(imageData : Data, completionHandler : @escaping (JSON)->()){
        
        self.myGroup.enter()
        
        print("Came in here")
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(imageData, withName: "file", fileName: "tree.jpg", mimeType: "image/png")
        }, to:"http://pearingup.herokuapp.com/upload")
        { (result) in
            switch result {
            case .success(let upload, _,_ ):
                upload.uploadProgress(closure: { (progress) in
                    print("uploading")
                })
                upload.responseJSON { response in
                    let temp : JSON = JSON(response.result.value!)
                    print("The id of the image is : ")
                    print(temp)
                    completionHandler(temp["id"])
                    
                    
                    self.myGroup.leave()
                }
            case .failure(let encodingError):
                print("failed")
                print(encodingError)
                
            }
        }
        
    }
    
    @IBAction func addImg(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a Source", preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action:UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            } else {
                print("camera not available")
            }
        
            picker.sourceType = .camera
            self.present(picker, animated: true, completion: nil)
        }))
        

        actionSheet.addAction(UIAlertAction(title: "Photo Library" , style: .default, handler: {(action:UIAlertAction) in picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        }))
        print("Loading Image Picker")
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil ))
        self.present(actionSheet, animated:true, completion: nil)
    }
    
    
    func imagePickerController( _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        print("pic")
        fileLocation = info[UIImagePickerControllerImageURL] as! NSURL
        print(fileLocation)
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage //2
        imageView.image = chosenImage //4
        dismiss(animated:true, completion: nil) //5
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    func displayAlert(message: String){
        
        let alert_toDisplay = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        
        alert_toDisplay.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            // self.titleText.text = "yoo"
        }))
        self.present(alert_toDisplay, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
