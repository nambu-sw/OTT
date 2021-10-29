//
//  MainViewController.swift
//  OTT
//
//  Created by MIJI SUH on 2021/10/25.
//

import UIKit
import JTAppleCalendar
import Alamofire
import SwiftyJSON

class MainViewController: UIViewController {
    
    @IBOutlet var calendarView: JTACMonthView!
    
    let testCalendar = Calendar(identifier: .gregorian)
    var ootd:[[String:Any]]?
    var calendarDataSource:[String:String] = [:]
    var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd.eee"
        return formatter
    }

    @IBAction func prevMonth(_ sender: Any) {
        calendarView.scrollToSegment(.previous)
    }
    
    @IBAction func nextMonth(_ sender: Any) {
        calendarView.scrollToSegment(.next)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendarView.scrollDirection = .horizontal
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        calendarView.showsHorizontalScrollIndicator = false
        
//        let visibleDates = calendarView.visibleDates()
//        print(visibleDates.monthDates)
        populateDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let strURL = "http://localhost:8000/ott/ootd/"
        
        callAPI(strURL:strURL, method:.get) { value in
            let json = JSON(value)
            // let result = json["success"].boolValue
            self.ootd = json["data"].arrayObject as? [[String:Any]]
            guard let ootd = self.ootd else { return }
            
            for item in ootd {
                guard let date = item["date"] as? String else { break }
                self.calendarDataSource[date] = "onlyData"
            }
            
            DispatchQueue.main.async {
                self.calendarView.reloadData()
            }
        }
    }
    
    func callAPI(strURL:String, method:HTTPMethod, parameters:Parameters?=nil, headers:HTTPHeaders?=nil, handler:@escaping (Any)->()) {
        let alamo = AF.request(strURL, method:method, parameters: parameters)
        alamo.responseJSON { response in
            switch response.result {
            case .success(let value):
                handler(value)
            case .failure(let error):
                print(error.errorDescription)
            }
        }
    }
    
    func configureCell(view: JTACDayCell?, cellState: CellState) {
        guard let cell = view as? DateCell  else { return }
        cell.dateLabel.text = cellState.text
        handleCellTextColor(cell: cell, cellState: cellState)
        handleCellSelected(cell: cell, cellState: cellState)
        handleCellEvents(cell: cell, cellState: cellState)
    }
    
    func handleCellTextColor(cell: DateCell, cellState: CellState) {
        if cellState.dateBelongsTo == .thisMonth {
            cell.dateLabel.textColor = UIColor.black
        } else {
            cell.dateLabel.textColor = UIColor.gray
        }
    }
    
    func handleCellSelected(cell: DateCell, cellState: CellState) {
        if cellState.isSelected {
            cell.selectedView.layer.cornerRadius = 20
            cell.selectedView.isHidden = false
        } else {
            cell.selectedView.isHidden = true
        }
    }
    
    func handleCellEvents(cell: DateCell, cellState: CellState) {
        let dateString = formatter.string(from: cellState.date)
        if calendarDataSource[dateString] == nil {
            cell.dotView.isHidden = true
        } else {
            cell.dotView.isHidden = false
        }
    }
    
    // 서버에서 날짜 정보 받아와서 해당 이미지 띄워주기
    func populateDataSource() {
        // You can get the data from a server.
        // Then convert that data into a form that can be used by the calendar.
        calendarDataSource = [
            "07-Jan-2021": "SomeData",
            "15-Jan-2021": "SomeMoreData",
            "15-Feb-2021": "MoreData",
            "21-Feb-2021": "onlyData",
        ]
        // update the calendar
        calendarView.reloadData()
    }
    
}

extension MainViewController: JTACMonthViewDataSource {
    func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
        // let formatter = DateFormatter()
        // formatter.dateFormat = "yyyy MM dd"
        // let startDate = formatter.date(from: "2018 01 01")!
        // let endDate = Date()
        // return ConfigurationParameters(startDate: startDate,
        //                                endDate: endDate,
        //                                generateInDates: .forAllMonths,
        //                                generateOutDates: .tillEndOfGrid)
        
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        formatter.dateFormat = "MMMM yyyy"
        
        var dateComponent = DateComponents()
        dateComponent.year = 1
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: dateComponent, to: startDate)
        
        let parameters = ConfigurationParameters(startDate: startDate,
                                                 endDate: endDate!,
                                                 numberOfRows: 6,
                                                 calendar: Calendar.current,
                                                 generateInDates: .forAllMonths,
                                                 generateOutDates: .off,
                                                 firstDayOfWeek: .sunday,
                                                 hasStrictBoundaries: true)
        
        return parameters
    }
}

extension MainViewController: JTACMonthViewDelegate {
    func calendar(_ calendar: JTACMonthView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTACDayCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCell
        
        self.calendar(calendar, willDisplay: cell, forItemAt: date, cellState: cellState, indexPath: indexPath)
        
        if cellState.dateBelongsTo == .thisMonth {
           cell.isHidden = false
        } else {
           cell.isHidden = true
        }
        
        if testCalendar.isDateInToday(date) {
            cell.dateLabel.textColor = UIColor.black
            cell.dateLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
            
        } else {
            cell.dateLabel.textColor = UIColor.black
        }
        
        return cell
    }
    
    func calendar(_ calendar: JTACMonthView, willDisplay cell: JTACDayCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        let cell = cell as! DateCell
        configureCell(view: cell, cellState: cellState)
        cell.dateLabel.text = cellState.text
    }
    
    func calendar(_ calendar: JTACMonthView, didSelectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        configureCell(view: cell, cellState: cellState)
        
        print("Selected date ", formatter.string(from: date))
        
        // 화면 이동
        if let ootdVC = self.storyboard?.instantiateViewController(withIdentifier: "ootdvc") as? OOTDViewController {
            
            // 데이터 전달
            ootdVC.date = formatter.string(from: date)
            ootdVC.mainViewController = self
            present(ootdVC, animated: true)
        }
    }

    func calendar(_ calendar: JTACMonthView, didDeselectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        configureCell(view: cell, cellState: cellState)
    }
    
    func calendar(_ calendar: JTACMonthView, shouldSelectDate date: Date, cell: JTACDayCell?, cellState: CellState) -> Bool {
        return true // Based on a criteria, return true or false
    }
    
    // 헤더
    func calendar(_ calendar: JTACMonthView, headerViewForDateRange range: (start: Date, end: Date), at indexPath: IndexPath) -> JTACMonthReusableView {
        let formatter = DateFormatter()  // Declare this outside, to avoid instancing this heavy class multiple times.
        formatter.dateFormat = "MMMM yyyy"

        let header = calendar.dequeueReusableJTAppleSupplementaryView(withReuseIdentifier: "DateHeader", for: indexPath) as! DateHeader
        header.monthTitle.text = formatter.string(from: range.start)
        
        return header
    }

    func calendarSizeForMonths(_ calendar: JTACMonthView?) -> MonthSize? {
        return MonthSize(defaultSize: 1)
    }
    
}
