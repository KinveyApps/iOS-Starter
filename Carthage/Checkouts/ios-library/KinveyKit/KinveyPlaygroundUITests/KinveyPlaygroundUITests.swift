//
//  KinveyPlaygroundUITests.swift
//  KinveyPlaygroundUITests
//
//  Created by Victor Barros on 2015-09-24.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest

class KinveyPlaygroundUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    private func runMainLoop(seconds: NSTimeInterval = 0.2) {
        NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: seconds))
    }
    
    private func waitUntil(
        seconds: NSTimeInterval,
        function: String = __FUNCTION__,
        file: String = __FILE__,
        line: UInt = __LINE__,
        _ message: String = "",
        block:() -> Bool
    ) {
        let start = NSDate()
        while (!block() && NSDate().timeIntervalSinceDate(start) < seconds) {
            runMainLoop()
        }
        let result = block()
        if (!result) {
            _XCTPreformattedFailureHandler(self, result, file, line, "Timeout fail: block() returned false", message)
        }
    }
    
    private func openMIC(item: String) {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["MIC"].tap()
        tablesQuery.staticTexts[item].tap()
        
        runMainLoop()
        
        let webViewsQuery = app.webViews
        
        waitUntil(3) { return webViewsQuery.count == 1 }
        
        let usernameTextField = webViewsQuery.textFields["Username"]
        waitUntil(3) { return usernameTextField.exists }
        if (usernameTextField.exists) {
            usernameTextField.tap()
            runMainLoop(0.5)
            while ((usernameTextField.value as! String).characters.count > 0) {
                usernameTextField.typeText(XCUIKeyboardKeyDelete)
            }
            usernameTextField.typeText("ivan")
        }
        
        let passwordTextField = webViewsQuery.secureTextFields["Password"];
        waitUntil(3) { return passwordTextField.exists }
        if (passwordTextField.exists) {
            passwordTextField.tap()
            runMainLoop(0.5)
            while ((passwordTextField.value as! String).characters.count > 0) {
                passwordTextField.typeText(XCUIKeyboardKeyDelete)
            }
            passwordTextField.typeText("Zse45rfv")
        }
        
        usernameTextField.tap()
        
        webViewsQuery.buttons["Sign On"].tap()
        
        waitUntil(10) { return app.alerts.count > 0 && app.alerts.elementBoundByIndex(0).label == "Success" }
        
        if (app.alerts.count > 0) {
            app.alerts.elementBoundByIndex(0).buttons["OK"].tap()
        }
    }
    
    func testMIC() {
        openMIC("Login Page using KCSWebViewController")
    }
    
    func testMICModal() {
        openMIC("Login Page using KCSWebViewController (Modal Superview)")
    }
    
}
