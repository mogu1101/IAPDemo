//
//  ViewController.swift
//  InAppPurchaseTestDemo
//
//  Created by Liujinjun on 2017/11/5.
//  Copyright © 2017年 Liujinjun. All rights reserved.
//

import UIKit
import StoreKit
import SVProgressHUD

class ViewController: UIViewController {
    
    static let cellId = "productCell"
    var products = [SKProduct]()
    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: UIScreen.main.bounds, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ViewController.cellId)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
        requestProductData()
    }
    
    func setupSubviews() {
        title = "IAP Demo"
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "刷新收据", style: .plain, target: self, action: #selector(refreshReceipt))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "恢复", style: .plain, target: self, action: #selector(restoreTransaction))
        
        view.addSubview(tableView)
    }
    
    func productIds() -> [String] {
        return ["00001", "00002", "00003", "00004"]
    }
    
    func requestProductData() {
        if SKPaymentQueue.canMakePayments() {
            let productsRequest = SKProductsRequest(productIdentifiers: Set(productIds()))
            productsRequest.delegate = self
            productsRequest.start()
            SVProgressHUD.show()
        } else {
            print("不允许App内购")
        }
    }
    
    func refreshReceipt() {
        print("refreshReceipt")
        let refreshRequst = SKReceiptRefreshRequest()
        refreshRequst.delegate = self
        refreshRequst.start()
        SVProgressHUD.show(withStatus: "刷新中")
    }
    
    func restoreTransaction() {
        SKPaymentQueue.default().restoreCompletedTransactions()
        SVProgressHUD.show(withStatus: "恢复中")
    }

}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let product = products[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ViewController.cellId, for: indexPath)
        cell.textLabel?.text = "\(product.localizedTitle) ￥\(product.price)"
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let product = products[indexPath.row]
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        SVProgressHUD.show()
    }
    
}

extension ViewController: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        print("请求成功！")
        if (request.isKind(of: SKReceiptRefreshRequest.self)) {
            SVProgressHUD.dismiss()
            SVProgressHUD.showSuccess(withStatus: "刷新收据成功")
            IAPAgent.shareAgent.verifyReceipt(paymentTransaction: nil)
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("请求失败！\nError：\(error)")
        if (request.isKind(of: SKReceiptRefreshRequest.self)) {
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: "刷新收据失败")
        }
    }
    
}

extension ViewController: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        if products.count == 0 {
            print("没有商品！")
        } else {
            print("productIds: \(response.invalidProductIdentifiers)")
            self.products = products
            tableView.reloadData()
        }
        SVProgressHUD.dismiss()
    }
    
}

