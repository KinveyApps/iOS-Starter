//
//  XCUIElement.swift
//  MICSampleApp
//
//  Created by Victor Barros on 2015-12-13.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest

extension XCUIElement {
    
    func clearAndEnterText(text: String) -> Void {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        
        if stringValue.characters.count > 0 {
            var deleteString: String = ""
            for _ in 1...stringValue.characters.count {
                deleteString += "\u{8}"
            }
            self.typeText(deleteString)
        } else {
            NSThread.sleepForTimeInterval(1)
        }
        
        self.typeText(text)
    }
    
}
