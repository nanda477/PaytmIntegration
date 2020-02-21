//
//  ViewController.swift
//  PaytmIntegration
//
//  Created by D2V iMac on 18/02/20.
//  Copyright © 2020 D2V iMac. All rights reserved.
//

import UIKit
import PaymentSDK

class ViewController: UIViewController {
    
    var txnController = PGTransactionViewController()
    
    var serv = PGServerEnvironment()
    
     var order_ID:String?
      var cust_ID:String?
      var params = [String:String]()

    @IBOutlet weak var amountTF: UITextField!
    @IBOutlet weak var payBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
    }
    
    
    @IBAction func payAction(_ sender: Any) {
        
        if amountTF.text != "" {
            let amountdata = amountTF.text!
            payViaPaytm(amount: amountdata)
        }
        
    }
    
    func payViaPaytm(amount: String) {
        
        order_ID = String((0...100).randomElement()!)
               cust_ID = String((0...100).randomElement()!)
                      params = ["MID": "HJgAdo86670166137575",
                                "ORDER_ID": order_ID,
                                "CUST_ID": cust_ID,
                                "MOBILE_NO": "7777777777",
                                "EMAIL": "username@emailprovider.com",
                                "CHANNEL_ID":"WAP",
                                "INDUSTRY_TYPE_ID":"Retail",
                                "WEBSITE": "WEBSTAGING",
                                "TXN_AMOUNT": amount,
                                "CALLBACK_URL" : "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=\(order_ID!)"
                          ] as! [String : String]
               print(params)
               
               
               var request = URLRequest.init(url: URL(string: "http://192.188.1.102:8888/PHP/generateChecksum.php")!)
               request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
               request.httpMethod = "POST"
        
               request.httpBody = params.percentEncoded()
               
                payBtn.setTitle("Loading...", for: .normal)
               let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    self.payBtn.setTitle("Paynow", for: .normal)
                }
                
                   guard let data = data,
                       let response = response as? HTTPURLResponse,
                       error == nil else {                                              // check for fundamental networking error
                       print("error", error ?? "Unknown error")
                       return
                   }

                   guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                       print("statusCode should be 2xx, but is \(response.statusCode)")
                       print("response = \(response)")
                       return
                   }

                   let responseString = String(data: data, encoding: .utf8)
                   print("responseString = \(responseString!)")
                   
                   do  {
                       if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject] {
                           
                           let chm = json["CHECKSUMHASH"] as? String ?? ""
                           print(chm)
                           self.setupPaytm(checkSum: chm, params: self.params)
                       }
                           
                           
                       }catch {
                           print("Eerror")
                       }
               }

               task.resume()
    }
    
   
    private func setupPaytm(checkSum:String,params:[String:String]) {
           serv = serv.createStagingEnvironment()
           let type :ServerType = .eServerTypeStaging
           let order = PGOrder(orderID: "", customerID: "", amount: "", eMail: "", mobile: "")
           order.params = params
           //"CHECKSUMHASH":"oCDBVF+hvVb68JvzbKI40TOtcxlNjMdixi9FnRSh80Ub7XfjvgNr9NrfrOCPLmt65UhStCkrDnlYkclz1qE0uBMOrmu
           order.params["CHECKSUMHASH"] = checkSum
                DispatchQueue.main.async {
                     self.txnController =  (self.txnController.initTransaction(for: order) as? PGTransactionViewController)!
                              self.txnController.title = "Paytm Payments"
                              self.txnController.setLoggingEnabled(true)
                              
                             
                                  self.txnController.serverType = type
                            
                              self.txnController.merchant = PGMerchantConfiguration.defaultConfiguration()
                              self.txnController.delegate = self
                              self.navigationController?.pushViewController(self.txnController
                                  , animated: true)
                }
          
       }
       


}

//MARK : Delegate Methods

extension ViewController : PGTransactionDelegate {
    
    //this function triggers when transaction gets finished
    func didFinishedResponse(_ controller: PGTransactionViewController, response responseString: String) {
        
        let msg : String = responseString
        var titlemsg : String = ""
        if let data = responseString.data(using: String.Encoding.utf8) {
            do {
                if let jsonresponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any] , jsonresponse.count > 0{
                    titlemsg = jsonresponse["STATUS"] as? String ?? ""
                }else{
                    let actionSheetController: UIAlertController = UIAlertController(title: titlemsg , message: msg, preferredStyle: .alert)
                         let cancelAction : UIAlertAction = UIAlertAction(title: "OK", style: .cancel) {
                             action -> Void in
                             controller.navigationController?.popViewController(animated: true)
                         }
                         actionSheetController.addAction(cancelAction)
                         self.present(actionSheetController, animated: true, completion: nil)
                }
            } catch {
                print("Something went wrong")
            }
        }
            let actionSheetController: UIAlertController = UIAlertController(title: titlemsg , message: msg, preferredStyle: .alert)
                 let cancelAction : UIAlertAction = UIAlertAction(title: "OK", style: .cancel) {
                     action -> Void in
                     controller.navigationController?.popViewController(animated: true)
                 }
                 actionSheetController.addAction(cancelAction)
                 self.present(actionSheetController, animated: true, completion: nil)
        
        
     
    }
    //this function triggers when transaction gets cancelled
    func didCancelTrasaction(_ controller : PGTransactionViewController) {
        controller.navigationController?.popViewController(animated: true)
    }
    //Called when a required parameter is missing.
    func errorMisssingParameter(_ controller : PGTransactionViewController, error : NSError?) {
        controller.navigationController?.popViewController(animated: true)
    }
}




extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
