//
//  NetworkRequest.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

final class NetworkRequest {

    // MARK: - Variables
    
    private var request: URLRequest?
    private var task: URLSessionDataTask?
    
    // MARK: - Init
    
    /// Init a NetworkRequest object with the given configuration
    ///
    /// - Parameters:
    ///   - endPoint: the endpoint
    ///   - method: the http method (GET, POST, etc)
    ///   - json: the json object (optional)
    convenience init(endPoint: String, method: HttpMethod, json: NSDictionary?) {
        
        self.init()
        
        self.configureRequest(
            endPoint: endPoint,
            method: method,
            json: json)
    }
    
    // MARK: - Send and Cancel request
    
    /// Send the request to the given endpoint
    ///
    /// - Parameters:
    ///   - success: the success callback
    ///   - failure: the failure callback
    func send(success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        
        guard let wrapped = self.request else {
            DispatchQueue.main.async {
                failure(nil)
            }
            return
        }
        
        self.task = URLSession.shared.dataTask(with: wrapped, completionHandler: { (data, response, error) in
            
            // Check for response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error obtaing httpResponse")
                DispatchQueue.main.async {
                    failure(nil)
                }
                return
            }
            
            // Ensure the server responds with status code 200
            guard httpResponse.statusCode == 200 else {
                
                print("Status code is not 200")
                
                if error != nil {
                    DispatchQueue.main.async {
                        failure(error!.localizedDescription)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    failure("Status code: \(httpResponse.statusCode)")
                }
                
                return
            }
            
            guard let wrappedData = data else {
                print("Data is nil")
                DispatchQueue.main.async {
                    failure("No data")
                }
                return
            }
            
            DispatchQueue.main.async {
                success(wrappedData)
            }
        })
        
        if let wrappedTask = self.task {
            wrappedTask.resume()
        }
    }
    
    /// Cancel the current request
    func cancel() {
        print("Canceling request")
        
        if let task = self.task {
            task.cancel()
        }
    }
    
    // MARK: - Configure Request
    
    /// Private func to configure the request
    ///
    /// - Parameters:
    ///   - endPoint: the endpoint
    ///   - method: the http method
    ///   - json: the json object
    private func configureRequest(
        endPoint: String,
        method: HttpMethod,
        json: NSDictionary?) {
        
        guard let url = URL(string: endPoint) else {
            print("Error creating URL for \(endPoint)")
            return
        }
        
        self.request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: RequestValues.timeOut)
        
        self.request?.httpMethod = method.rawValue
        
        if (method == .POST || method == .PUT) {
            request?.addValue(
                RequestValues.contentTypeJsonValue,
                forHTTPHeaderField: RequestValues.contentTypeHeader)
        }
        
        if let wrappedJson = json {
            if let data = NetworkUtils.serializeJson(json: wrappedJson) {
                request?.httpBody = data
            }
        }
    }
}
