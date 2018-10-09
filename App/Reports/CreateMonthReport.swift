//
//  CreateMonthReport.swift
//  Jirassic
//
//  Created by Cristian Baluta on 09/10/2018.
//  Copyright © 2018 Imagin soft. All rights reserved.
//

import Foundation

class CreateMonthReport {

    let createReport = CreateReport()
    /// Returns reports collected from all days in the month
    /// @parameters
    /// tasks - All tasks in a month
    func reports (fromTasks tasks: [Task], targetHoursInDay: Double?) -> [Report] {

        guard var referenceDate = tasks.first?.endDate else {
            return []
        }

        // Group tasks by days
        var days = [[Task]]()
        for task in tasks {
            var t = [Task]()
            if referenceDate.isSameDayAs(task.endDate) {
                t.append(task)
            } else {
                referenceDate = task.endDate
                days.append(t)
                t = []
                t.append(task)
            }
        }

        // Iterate over days and create reports
        var dayReports = [[Report]]()
        for day in days {
            let r = createReport.reports(fromTasks: day, targetHoursInDay: targetHoursInDay)
            dayReports.append(r)
        }

        var reports = [Report]()
        for day in dayReports {

        }

        return reports
    }
}
