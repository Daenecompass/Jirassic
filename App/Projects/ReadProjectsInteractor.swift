//
//  ReadReportsInteractor.swift
//  Jirassic
//
//  Created by Cristian Baluta on 12/01/2020.
//  Copyright © 2020 Imagin soft. All rights reserved.
//

import Foundation
import RCLog

class ReadProjectsInteractor: RepositoryInteractor {
    
    // Return a list of all projects
    func allProjects() -> [Project] {
        return self.repository.projects()
    }
}
