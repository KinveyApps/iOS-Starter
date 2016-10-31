//
//  PerformanceTestData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-21.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class PerformanceTestData: UIViewController {
    
    let client = Client(appKey: "kid_b1d6IY_x7l", appSecret: "079412ee99f4485d85e6e362fb987de8")
    
    func store<T: Persistable>() -> DataStore<T> where T: NSObject {
        return DataStore<T>.collection(.network, client: self.client)
    }
    
    @IBOutlet dynamic weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var deltaSetSwitch: UISwitch!
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        return dateFormatter
    }()
    
    lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 3
        numberFormatter.minimumFractionDigits = 3
        return numberFormatter
    }()
    
    var startDate: Date! {
        didSet {
            let timeIntervalSinceReferenceDate = startDate.timeIntervalSinceReferenceDate
            let milliseconds = Int((timeIntervalSinceReferenceDate * 1000).truncatingRemainder(dividingBy: 1000))
            startDateLabel.text = "\(dateFormatter.string(from: startDate)).\(milliseconds)"
            endDateLabel.text = ""
            durationLabel.text = ""
        }
    }
    
    var endDate: Date! {
        didSet {
            let timeIntervalSinceReferenceDate = endDate.timeIntervalSinceReferenceDate
            let milliseconds = Int((timeIntervalSinceReferenceDate * 1000).truncatingRemainder(dividingBy: 1000))
            endDateLabel.text = "\(dateFormatter.string(from: endDate)).\(milliseconds)"
            durationLabel.text = "\(numberFormatter.string(from: NSNumber(value: endDate.timeIntervalSince(startDate)))!) second(s)"
        }
    }
    
    func test() {
    }
    
    @IBAction func runTouchUpInside(_ sender: AnyObject) {
        if client.activeUser != nil {
            test()
        } else {
            User.login(username: "test", password: "test", client: client) { user, error in
                if let _ = user {
                    self.test()
                }
            }
        }
    }
    
}
