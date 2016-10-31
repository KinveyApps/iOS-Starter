//
//  PeformanceTestLongData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class PerformanceTestLongData: PerformanceTestData {
    
    override func test() {
        startDate = Date()
        let store: DataStore<LongData> = self.store()
        store.find(deltaSet: deltaSetSwitch.isOn) { results, error in
            self.endDate = Date()
            self.durationLabel.text = "\(self.durationLabel.text ?? "")\n\(results?.count ?? 0)"
        }
    }
    
}
