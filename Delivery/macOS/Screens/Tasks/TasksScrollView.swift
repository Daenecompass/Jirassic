//
//  TasksScrollView.swift
//  Jirassic
//
//  Created by Baluta Cristian on 28/03/15.
//  Copyright (c) 2015 Cristian Baluta. All rights reserved.
//

import Cocoa

class TasksScrollView: NSScrollView {
	
    fileprivate var tableView: NSTableView!
    fileprivate var dataSource: DataSource?
    fileprivate let localPreferences = RCPreferences<LocalPreferences>()
	
	var didAddRow: ((_ row: Int) -> ())?
    var didRemoveRow: ((_ row: Int) -> ())?
    var didChangeSettings: (() -> ())?
    var didEndDay: ((_ shouldSaveToJira: Bool, _ shouldRoundTime: Bool) -> ())?
	
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    convenience init (tasks: [Task]) {
        self.init(frame: NSRect.zero)
        self.setup()
        
        let dataSource = TasksDataSource(tableView: tableView, tasks: tasks)
        tableView!.dataSource = dataSource
        tableView!.delegate = dataSource
        
        dataSource.didAddRow = { [weak self] (row: Int) -> Void in
            self?.didAddRow!(row)
        }
        dataSource.didRemoveRow = { [weak self] (row: Int) -> Void in
            self?.didRemoveRow!(row)
        }
        dataSource.didEndDay = { [weak self] (_ shouldSaveToJira: Bool, _ shouldRoundTime: Bool) -> Void in
            self?.didEndDay!(shouldSaveToJira, shouldRoundTime)
        }
        
        self.dataSource = dataSource
    }
    
    convenience init (reports: [Report]) {
        self.init(frame: NSRect.zero)
        self.setup()
        
        let dataSource = ReportsDataSource(tableView: tableView, reports: reports)
        tableView!.dataSource = dataSource
        tableView!.delegate = dataSource
        
        let headerView = ReportsHeaderView()
        headerView.didChangeSettings = { [weak self] in
            self?.didChangeSettings!()
        }
        
        let settings = SettingsInteractor().getAppSettings()
        headerView.workdayTime = Date.secondsToPercentTime(settings.settingsTracking.endOfDayTime.timeIntervalSince(settings.settingsTracking.startOfDayTime))
        let totalTime = StatisticsInteractor().workedTime(fromReports: reports)
        headerView.workedTime = localPreferences.bool(.usePercents)
            ? "\(Date.secondsToPercentTime(totalTime))"
            : Date(timeIntervalSince1970: totalTime).HHmmGMT()
        tableView!.headerView = headerView
        
        self.dataSource = dataSource
    }
    
    fileprivate func setup() {        
        
        self.automaticallyAdjustsContentInsets = false
        self.contentInsets = NSEdgeInsetsMake(0, 0, 0, 0)
        self.drawsBackground = false
        self.hasVerticalScroller = true
        
        tableView = NSTableView(frame: self.frame)
        tableView!.selectionHighlightStyle = NSTableView.SelectionHighlightStyle.none
        tableView!.backgroundColor = NSColor.clear
        tableView!.headerView = nil
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "taskColumn"))
        column.width = 400
        tableView.addTableColumn(column)
        
        self.documentView = tableView!
//        tableView!.constrainToSuperview()
	}
	
	func reloadData() {
		tableView!.reloadData()
	}
    
    func reloadReports (_ reports: [Report]) {
        dataSource = ReportsDataSource(tableView: tableView, reports: reports)
        tableView!.dataSource = dataSource
        tableView!.delegate = dataSource
        tableView!.reloadData()
    }
	
	func addTask (_ task: Task) {
        if let dataSource = tableView.dataSource as? TasksDataSource {
            dataSource.addTask(task)
        }
	}
	
    func removeTaskAtRow (_ row: Int) {
        if let dataSource = tableView.dataSource as? TasksDataSource {
            dataSource.removeTaskAtRow(row)
        }
	}
}
