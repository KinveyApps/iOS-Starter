//
//  MICSampleAppUITests.swift
//  MICSampleAppUITests
//
//  Created by Victor Barros on 2015-12-11.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest

class MICSampleAppUITests: XCTestCase {
        
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
    
    func testMICLogin() {
        let app = XCUIApplication()
        
        let appKeyTextField = app.textFields["App Key"]
        appKeyTextField.tap()
        appKeyTextField.typeText("kid_W1rPs9qy0")
        
        let appSecretTextField = app.textFields["App Secret"]
        appSecretTextField.tap()
        appSecretTextField.typeText("75f94ea7477c4bb7bd28c93b703bd10b")
        
        let redirectUriTextField = app.textFields["Redirect URI"]
        redirectUriTextField.tap()
        redirectUriTextField.typeText("kinveyAuthDemo://")
        
        XCUIApplication().buttons["Present MIC View Controller to Login"].tap()
        
        NSThread.sleepForTimeInterval(3)
        
        let webViewsQuery = app.webViews
        XCTAssertTrue(webViewsQuery.textFields["Username"].exists)

        let username = "ivan"
        let usernameTextField = webViewsQuery.textFields["Username"]
        if let value = usernameTextField.value as? String where value != username {
            usernameTextField.clearAndEnterText(username)
        }
        
        webViewsQuery.secureTextFields["Password"].clearAndEnterText("")
        
        webViewsQuery.buttons["Sign On"].tap()
        
        NSThread.sleepForTimeInterval(5)
        
        app.buttons["OK"].tap()
    }
    
    
}
