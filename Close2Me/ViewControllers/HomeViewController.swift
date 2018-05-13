//
//  HomeViewController.swift
//  Close2Me
//
//  Created by Ale MQ on 29/4/18.
//  Copyright © 2018 Ale MQ. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    var userData : NSDictionary? = ["userName": "DrMolix"]

    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults.standard.string(forKey: Constants.Preferences.UserId) == nil {
            APIUtils().registerUser(userData: self.userData!) { (userId) -> Void in
                if let userId = userId {
                    print("Todo Bien!")
                    UserDefaults.standard.set(userId, forKey: Constants.Preferences.UserId)
                    UserDefaults.standard.set(self.userData![Constants.Model.UserName], forKey: Constants.Preferences.UserName)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

