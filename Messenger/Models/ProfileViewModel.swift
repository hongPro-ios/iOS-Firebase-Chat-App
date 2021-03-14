//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by JEONGSEOB HONG on 2021/03/15.
//

import Foundation


enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
    
}
