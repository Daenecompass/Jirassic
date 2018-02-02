//
//  ComputerWakeUpInteractor.swift
//  Jirassic
//
//  Created by Baluta Cristian on 27/12/15.
//  Copyright © 2015 Cristian Baluta. All rights reserved.
//

import Foundation

class ComputerWakeUpInteractor: RepositoryInteractor {
    
    var settings: Settings!
    let typeEstimator = TaskTypeEstimator()
    let reader: ReadTasksInteractor!
    
    override init (repository: Repository) {
        settings = SettingsInteractor().getAppSettings()
        reader = ReadTasksInteractor(repository: repository)
        super.init(repository: repository)
    }
    
	func runWith (lastSleepDate date: Date?) {
		
        guard let date = date else {
            return
        }
        if let type = estimationForDate(date) {
            if type == .startDay {
                if settings.settingsTracking.trackStartOfDay {
                    let startDate = settings.settingsTracking.startOfDayTime.dateByKeepingTime()
                    if Date() > startDate {
                        save(task: Task(dateEnd: Date(), type: TaskType.startDay))
                    }
                }
            } else if (type == .scrum && settings.settingsTracking.trackScrum) || (type == .lunch && settings.settingsTracking.trackLunch) {
                
                var task = Task(dateEnd: Date(), type: type)
                task.startDate = date
                save(task: task)
            }
        }
    }
    
    func estimationForDate (_ date: Date) -> TaskType? {
        
		let existingTasks = reader.tasksInDay(Date())
        
        guard existingTasks.count > 0 else {
            return TaskType.startDay
        }
        
        let estimatedType: TaskType = typeEstimator.taskTypeAroundDate(date, withSettings: settings)
        
        switch estimatedType {
        case .scrum:
            if !TaskFinder().scrumExists(existingTasks) {
                return TaskType.scrum
            }
            break
        case .lunch:
            if !TaskFinder().lunchExists(existingTasks) {
                return TaskType.lunch
            }
            break
        case .meeting:
            if settings.settingsTracking.trackMeetings {
                return TaskType.meeting
            }
            break
        default:
            return nil
        }
        return nil
	}
    
    func save (task: Task) {
        let saveInteractor = TaskInteractor(repository: localRepository)
        saveInteractor.saveTask(task, allowSyncing: true, completion: { savedTask in
            InternalNotifications.notifyAboutNewlyAddedTask(savedTask)
        })
    }
}
