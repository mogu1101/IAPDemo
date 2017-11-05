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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "刷新收据", style: .plain, target: self, action: #selector(refreshReceipt))
        
        view.addSubview(tableView)
    }
    
    func productIds() -> [String] {
        return ["1234", "123456"]
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
        let product = products[indexPath.row]
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        SVProgressHUD.show()
    }
    
}

extension ViewController: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        print("请求成功！")
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("请求失败！\nError：\(error)")
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

