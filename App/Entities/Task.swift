//
//  Task.swift
//  Jirassic
//
//  Created by Baluta Cristian on 21/11/15.
//  Copyright © 2015 Cristian Baluta. All rights reserved.
//

import Foundation

enum TaskType: Int {
	
	case issue = 0
	case startDay = 1
	case scrum = 2
	case lunch = 3
	case meeting = 4
    case gitCommit = 5
    case waste = 6
    case learning = 7
    case coderev = 8
    case endDay = 9
}

enum TaskSubtype: Int {
	
//	case IssueBegin = 0
	case issueEnd = 1
//	case ScrumBegin = 2
	case scrumEnd = 3
//	case LunchBegin = 4
	case lunchEnd = 5
//	case MeetingBegin = 6
	case meetingEnd = 7
    case gitCommitEnd = 8
//    case wasteBegin = 9
    case wasteEnd = 10
//    case learningBegin = 11
    case learningEnd = 12
//    case coderevBegin = 13
    case coderevEnd = 14
    
    var defaultTaskNumber: String? {
        switch self {
            case .scrumEnd: return "scrum"
            case .lunchEnd: return "lunch"
            case .meetingEnd: return "meeting"
            case .wasteEnd: return "waste"
            case .learningEnd: return "learning"
            case .coderevEnd: return "coderev"
            default: return nil
        }
    }
    var defaultNotes: String {
        switch self {
            case .scrumEnd: return "Scrum meeting"
            case .lunchEnd: return "Lunch break"
            case .meetingEnd: return "Meeting"
            case .wasteEnd: return "Wasted time"
            case .learningEnd: return "Learning time"
            case .coderevEnd: return "Code reviews"
            default: return ""
        }
    }
}

struct Task {
    
    var lastModifiedDate: Date?
    var startDate: Date?
	var endDate: Date
	var notes: String?
    var taskNumber: String?
    var taskTitle: String?
	var taskType: TaskType
    var objectId: String
}

extension Task {
	
    init () {
        self.endDate = Date()
        self.taskType = TaskType.issue
        self.objectId = String.random()
    }
    
	init (endDate: Date, type: TaskType) {
		
		self.endDate = endDate
		self.taskType = type
        self.objectId = String.random()
        
        var subtype: TaskSubtype?
		
		switch (type) {
			case TaskType.issue:	subtype = .issueEnd
			case TaskType.startDay:	self.notes = "Working day started"
            case TaskType.endDay:   self.notes = "Working day ended"
			case TaskType.scrum:	subtype = .scrumEnd
			case TaskType.lunch:	subtype = .lunchEnd
			case TaskType.meeting:	subtype = .meetingEnd
            case TaskType.gitCommit:subtype = .gitCommitEnd
            case TaskType.waste:    subtype = .wasteEnd
            case TaskType.learning: subtype = .learningEnd
            case TaskType.coderev:  subtype = .coderevEnd
        }
        if let s = subtype {
            self.taskNumber = s.defaultTaskNumber
            self.notes = s.defaultNotes
        }
	}
	
	init (subtype: TaskSubtype) {
		
        self.endDate = Date()
        self.objectId = String.random()
        self.notes = subtype.defaultNotes
        self.taskNumber = subtype.defaultTaskNumber
        
		switch (subtype) {
			case .issueEnd:		self.taskType = TaskType.issue
			case .scrumEnd:		self.taskType = TaskType.scrum
			case .lunchEnd:		self.taskType = TaskType.lunch
			case .meetingEnd:	self.taskType = TaskType.meeting
            case .gitCommitEnd:	self.taskType = TaskType.gitCommit
            case .wasteEnd:     self.taskType = TaskType.waste
            case .learningEnd:  self.taskType = TaskType.learning
            case .coderevEnd:   self.taskType = TaskType.coderev
		}
	}
}

typealias TaskCreationData = (
    dateStart: Date?,
    dateEnd: Date,
    taskNumber: String,
    notes: String,
    taskType: TaskType
)
