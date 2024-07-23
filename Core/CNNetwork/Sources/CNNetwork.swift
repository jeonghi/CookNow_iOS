//
//  CNNetwork.swift
//  CNNetwork
//
//  Created by 쩡화니 on 7/23/24.
//

import Foundation
import Alamofire
import Common

protocol NetworkType: AnyObject {
  associatedtype Target: TargetType
  func responseData<R: Decodable>(_ target: Target,
                       _ responseType: R.Type,
                       logging: Bool,
                       completion: @escaping ((Result<R, Error>) -> Void)) where Target: TargetType, R: Decodable
  func responseData(_ target: Target,
                    logging: Bool,
                    completion: @escaping (HTTPURLResponse?, Data?, Error?) -> Void) where Target: TargetType
}

final class Network<Target: TargetType>: NetworkType {
  
  func responseData<R: Decodable>(_ target: Target,
                       _ responseType: R.Type,
                       logging: Bool = true,
                       completion: @escaping ((Result<R, Error>) -> Void)) where Target: TargetType, R: Decodable {
    responseData(target) { res, data, error in
      
      if let error = error {
        completion(.failure(error))
        return
      }
      
      if let data {
        do {
          let decodedData = try JSONDecoder().decode(responseType, from: data)
          completion(.success(decodedData))
          return
        } catch {
          CNLog.e("Error decoding type: \(type(of: responseType)) + \(error)")
          completion(.failure(error))
          return
        }
      } else {
        CNLog.i("no response data")
        completion(.failure(CNNetworkError()))
        return
      }
    }
  }
  
  func responseData(_ target: Target,
                    logging: Bool = true,
                    completion: @escaping (HTTPURLResponse?, Data?, Error?) -> Void) where Target: TargetType {
    
    guard let urlRequest = target.urlRequest else {
      completion(nil, nil, CNNetworkError(reason: .BadParameter, message: "잘못된 urlRequest임"))
      CNLog.e("잘못된 urlRequest")
      return
    }
    
    let sessionType = target.sessionType
    let apiType = target.apiType
    
    API
      .session(sessionType)
      .request(target)
      .validate { request, response, data in
        if let data {
          var json: Any? = nil
          do {
            json = try JSONSerialization.jsonObject(with: data, options: [])
          } catch {
            CNLog.e(error)
          }
          
          if let commonError = CNNetworkError(response: response, data: data, type: apiType) {
            return .failure(commonError)
          }
          
          else {
            return .success(Void())
          }
        }
        else {
          return .failure(CNNetworkError(reason: .Unknown, message: "data is nil."))
        }
      }
      .responseData { [unowned self] response in
        if let afError = response.error, let retryError = self.getRequestRetryFailedError(error: afError) {
          CNLog.e("response:\n api error: \(retryError)")
          completion(nil, nil, retryError)
        }
        else if let afError = response.error, self.getCommonError(error: afError) == nil {
          //일반에러
          CNLog.e("response:\n not api error: \(afError)")
          completion(nil, nil, afError)
        }
        else if let data = response.data, let response = response.response {
          if let commonError = CNNetworkError(response: response, data: data, type: apiType) {
            completion(nil, nil, commonError)
            return
          }
          
          completion(response, data, nil) // ⭐️ 정상적인 응답
        }
        else {
          //data or response 가 문제
          CNLog.e("response:\n error: response or data is nil.")
          completion(nil, nil, CNNetworkError(reason: .Unknown, message: "response or data is nil."))
        }
      }
  }
  
  func getRequestRetryFailedError(error:Error) -> CNNetworkError? {
    if let afError = error as? AFError {
      switch afError {
      case .requestRetryFailed(let retryError, _):
        return retryError as? CNNetworkError
      default:
        break
      }
    }
    return nil
  }
  
  func getCommonError(error: Error) -> CNNetworkError? {
    if let afError = error as? AFError {
      switch afError {
      case .responseValidationFailed(let reason):
        switch reason {
        case .customValidationFailed(let error):
          return error as? CNNetworkError
        default:
          break
        }
      case .requestAdaptationFailed(let error):
        return error as? CNNetworkError
      default:
        break
      }
    }
    return nil
  }
}
