//
//  APIUtils.swift
//  Close2Me
//
//  Created by Ale MQ on 30/4/18.
//  Copyright © 2018 Ale MQ. All rights reserved.
//

import Foundation

class APIUtils {

    let kDefaultUrl:String = "http://nodejs-mongo-persistent-close2me.193b.starter-ca-central-1.openshiftapps.com"
    let kregisterUser:String = "registerUser"
    let kUpdateUserData:String = "updateUserData"

    var errorMessage = ""

    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    func registerUser(userData: NSDictionary, completion: @escaping (String?) -> ()) {
        dataTask?.cancel()
        if var urlComponents = URLComponents(string: kDefaultUrl + "/" + kregisterUser) {
            guard let url = urlComponents.url else { return }
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            if let postData = (try? JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted)) {
                request.httpBody = postData
                
                dataTask = defaultSession.dataTask(with: request) { data, response, error in
                    defer {
                        self.dataTask = nil
                    }
                    if let error = error {
                        self.errorMessage += "DataTask error: " + error.localizedDescription + "\n"
                    } else if let myData = data,
                        let response = response as? HTTPURLResponse,
                        response.statusCode == 200 {
                        do {
                            if let jsonResult = try JSONSerialization.jsonObject(with: myData, options : []) as? Dictionary<String, Any> {
                                if jsonResult["result"] as? String == "error" {
                                    print("Error description: \(jsonResult["message"] as? String ?? "No description message")")
                                }
                                else {
                                    let userId = jsonResult[Constants.Model.UserId] as? String
                                    print("UserId is \(userId ?? "InvalidId")")
                                    completion(userId)
                                }
                            }
                        } catch let error as NSError {
                            print(error.localizedDescription)
                        }
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
                dataTask?.resume()
            }
        }
    }
    
    func sendUserData(userData: NSDictionary, completion: @escaping ([userInfo]) -> ()) {
        var myDataTask : URLSessionDataTask?
        //myDataTask?.cancel()
        if var urlComponents = URLComponents(string: kDefaultUrl + "/" + kUpdateUserData) {
            guard let url = urlComponents.url else { return }
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"

            if let postData = (try? JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted)) {
                request.httpBody = postData

                myDataTask = defaultSession.dataTask(with: request) { data, response, error in
                    defer {
                        myDataTask = nil
                    }
                    if let error = error {
                        self.errorMessage += "DataTask error: " + error.localizedDescription + "\n"
                        print("\(self.errorMessage)")
                    } else if let myData = data,
                        let response = response as? HTTPURLResponse,
                        response.statusCode == 200 {
                        do {
                            if let jsonResult = try JSONSerialization.jsonObject(with: myData, options : []) as? [Dictionary<String, Any>] {
                                var usersInfoArray = [userInfo]()
                                for data: Dictionary<String, Any> in jsonResult {
                                    if let userId = data[Constants.Model.UserId] as? String,
                                    let userName = data[Constants.Model.UserName] as? String,
                                    let userLatitude = (data[Constants.Model.UserLatitude] as? NSNumber)?.doubleValue,
                                    let userLongitude = (data[Constants.Model.UserLongitude] as? NSNumber)?.doubleValue {
                                        print("\(userName)'s latitude is \(userLatitude)")
                                        print("\(userName)'s longitude is \(userLongitude)")

                                        let newUserInfo:userInfo = userInfo()
                                        newUserInfo.userId = userId
                                        newUserInfo.userName = userName
                                        newUserInfo.coordinate.latitude = userLatitude
                                        newUserInfo.coordinate.longitude = userLongitude
                                        usersInfoArray.append(newUserInfo)
                                    }
                                }
                                completion(usersInfoArray)
                            }
                        } catch let error as NSError {
                            print(error.localizedDescription)
                        }
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
                myDataTask?.resume()
                //            Equals to...
                //            if let myDataTask = dataTask {
                //                myDataTask.resume()
                //            }
            }
        }
    }
}
