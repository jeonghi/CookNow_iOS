//
//  SaveMyIngredientDTO.swift
//  CNNetwork
//
//  Created by 쩡화니 on 8/30/24.
//

import Foundation

public enum SaveMyIngredientDTO {
  
  public struct Request: Encodable {
    
    let itemList: [UserIngredient]
    
    public init(itemList: [UserIngredient]) {
      self.itemList = itemList
    }
  }
  
  public struct Response: Decodable {
    
    let userId: Int
    let itemList: [UserIngredient]
  }
}
