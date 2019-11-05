//
//  RegisterUserInteractor.swift
//  Jirassic
//
//  Created by Baluta Cristian on 14/06/15.
//  Copyright (c) 2015 Cristian Baluta. All rights reserved.
//

import Foundation
import RCLog

class RegisterUserInteractor: RepositoryInteractor {

    var onRegisterSuccess: (() -> ())?
    var onRegisterFailure: (() -> ())?
	
	func registerWithCredentials (_ credentials: UserCredentials) {
		
		self.repository.registerWithCredentials(credentials) { [weak self] (error) in
            if let error = error {
                let errorString = error.userInfo["error"] as? NSString
                RCLogO(errorString)
                self?.onRegisterFailure?()
            } else {
                self?.onRegisterSuccess?()
            }
        }
	}
}
