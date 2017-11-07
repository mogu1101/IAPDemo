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
                verifyReceipt(paymentTransaction: transaction)
//                finishTransaction(transaction)
            case .deferred:
                print("最终状态未确定")
            case .failed:
                print("交易失败！")
                finishTransaction(transaction)
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        SVProgressHUD.dismiss()
        SVProgressHUD.showSuccess(withStatus: "恢复成功")
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        SVProgressHUD.dismiss()
        SVProgressHUD.showError(withStatus: "恢复错误")
    }
    
}

extension IAPAgent {
    
    // MARK: - Utils
    
    func verifyReceipt(paymentTransaction: SKPaymentTransaction?) {
        let receiptUrl = Bundle.main.appStoreReceiptURL
        let receiptData = try? Data(contentsOf: receiptUrl!)
        let receiptString = receiptData?.base64EncodedString(options: .endLineWithLineFeed)
        
        let url = URL(string: SANDBOX)!
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "POST"
        
        let payload = "{\"receipt-data\" : \"" + receiptString! + "\", \"password\" : \"bc177479afc84088b3424915c415fb8d\"}"
        let payloadData = payload.data(using: .utf8)
        
        request.httpBody = payloadData;
        
        // 提交验证请求，并获得官方的验证JSON结果
        let result = try? NSURLConnection.sendSynchronousRequest(request, returning: nil)
        
        // 官方验证结果为空
        if (result == nil) {
            //验证失败
            print("验证失败")
            SVProgressHUD.showError(withStatus: "验证失败")
            if let transaction = paymentTransaction {
                finishTransaction(transaction)
            }
            return
        }
        let dict: [String: Any]! = try? JSONSerialization.jsonObject(with: result!, options: .allowFragments) as! [String : Any]
        if (dict != nil) {
            guard let status = dict["status"] as? Int else {
                if let transaction = paymentTransaction {
                    finishTransaction(transaction)
                }
                return
            }
            if (status == 0) {
                print(dict!)
                print("验证成功！")
                SVProgressHUD.showSuccess(withStatus: "验证成功")
            } else {
                print("验证失败！")
                SVProgressHUD.showError(withStatus: "验证失败")
            }
            if let transaction = paymentTransaction {
                finishTransaction(transaction)
            }
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
