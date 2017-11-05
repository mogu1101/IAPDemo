//
//  IAPAgent.swift
//  InAppPurchaseTestDemo
//
//  Created by Liujinjun on 2017/11/5.
//  Copyright © 2017年 Liujinjun. All rights reserved.
//

import UIKit
import StoreKit
import SVProgressHUD
import Alamofire
import Mantle

class IAPAgent: NSObject {
    
    static let shareAgent = IAPAgent()
    
    let SANDBOX = "https://sandbox.itunes.apple.com/verifyReceipt"
    
}

extension IAPAgent: SKPaymentTransactionObserver {
    
    @available(iOS 3.0, *)
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("交易完成！")
                // 收据验证
                verifyReceipt(paymentTransaction: transaction)
            case .purchasing:
                print("商品被添加进queue")
            case .restored:
                print("恢复商品购买")
                finishTransaction(transaction)
            case .deferred:
                print("最终状态未确定")
            case .failed:
                print("交易失败！")
                finishTransaction(transaction)
            }
        }
    }
    
}

extension IAPAgent {
    
    // MARK: - Utils
    
    func verifyReceipt(paymentTransaction: SKPaymentTransaction) {
        let receiptUrl = Bundle.main.appStoreReceiptURL
        let receiptData = try? Data(contentsOf: receiptUrl!)
        let receiptString = receiptData?.base64EncodedString(options: .endLineWithLineFeed)
        
        let url = URL(string: SANDBOX)!
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "POST"
        
        let payload = "{\"receipt-data\" : \"" + receiptString! + "\", \"password\" : \"bc177479afc84088b3424915c415fb8d\"}"
        print(payload)
        let payloadData = payload.data(using: .utf8)
        
        request.httpBody = payloadData;
        
        // 提交验证请求，并获得官方的验证JSON结果
        let result = try? NSURLConnection.sendSynchronousRequest(request, returning: nil)
        
        // 官方验证结果为空
        if (result == nil) {
            //验证失败
            print("验证失败")
            finishTransaction(paymentTransaction)
            return
        }
        let dict: [String: Any]! = try? JSONSerialization.jsonObject(with: result!, options: .allowFragments) as! [String : Any]
        if (dict != nil) {
            guard let status = dict["status"] as? Int else {
                finishTransaction(paymentTransaction)
                return
            }
            if (status == 0) {
                print(dict!)
                print("验证成功！")
            } else {
                print("验证失败！")
            }
            finishTransaction(paymentTransaction)
        }
    }
    
    func finishTransaction(_ transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
        SVProgressHUD.dismiss()
    }
    
    func convertDictionaryToString(dict:[String:AnyObject]) -> String {
        var result:String = ""
        do {
            //如果设置options为JSONSerialization.WritingOptions.prettyPrinted，则打印格式更好阅读
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.init(rawValue: 0))
            
            if let JSONString = String(data: jsonData, encoding: String.Encoding.utf8) {
                result = JSONString
            }
            
        } catch {
            result = ""
        }
        return result
    }
    
}
