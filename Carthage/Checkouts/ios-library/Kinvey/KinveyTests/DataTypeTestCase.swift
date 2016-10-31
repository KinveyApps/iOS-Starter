//
//  DataTypeTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class DataTypeTestCase: StoreTestCase {
    
    func testSave() {
        signUp()
        
        let store = DataStore<DataType>.collection()
        let dataType = DataType()
        dataType.boolValue = true
        dataType.colorValue = UIColor.orange
        
        let fullName = FullName()
        fullName.firstName = "Victor"
        fullName.lastName = "Barros"
        dataType.fullName = fullName
        
        let fullName2 = FullName2()
        fullName2.firstName = "Victor"
        fullName2.lastName = "Barros"
        fullName2.fontDescriptor = UIFontDescriptor(name: "Arial", size: 12)
        dataType.fullName2 = fullName2
        
        let tuple = save(dataType, store: store)
        
        XCTAssertNotNil(tuple.savedPersistable)
        if let savedPersistable = tuple.savedPersistable {
            XCTAssertTrue(savedPersistable.boolValue)
        }
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query, readPolicy: .forceNetwork) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
                
                if let dataType = results.first {
                    XCTAssertTrue(dataType.boolValue)
                    XCTAssertEqual(dataType.colorValue, UIColor.orange)
                    
                    XCTAssertNotNil(dataType.fullName)
                    if let fullName = dataType.fullName {
                        XCTAssertEqual(fullName.firstName, "Victor")
                        XCTAssertEqual(fullName.lastName, "Barros")
                    }
                    
                    XCTAssertNotNil(dataType.fullName2)
                    if let fullName = dataType.fullName2 {
                        XCTAssertEqual(fullName.firstName, "Victor")
                        XCTAssertEqual(fullName.lastName, "Barros")
                        XCTAssertEqual(fullName.fontDescriptor, UIFontDescriptor(name: "Arial", size: 12))
                    }
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
}

class UIColorTransformType : TransformType {
    
    typealias Object = UIColor
    typealias JSON = JsonDictionary
    
    func transformFromJSON(_ value: Any?) -> UIColor? {
        if let value = value as? JsonDictionary,
            let red = value["red"] as? CGFloat,
            let green = value["green"] as? CGFloat,
            let blue = value["blue"] as? CGFloat,
            let alpha = value["alpha"] as? CGFloat
        {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        return nil
    }
    
    func transformToJSON(_ value: UIColor?) -> JsonDictionary? {
        if let value = value {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 9
            value.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return [
                "red" : red,
                "green" : green,
                "blue" : blue,
                "alpha" : alpha
            ]
        }
        return nil
    }
    
}

class DataType: Entity {
    
    dynamic var boolValue: Bool = false
    dynamic var fullName: FullName?
    
    fileprivate dynamic var fullName2Value: String?
    dynamic var fullName2: FullName2?
    
    dynamic var objectValue: NSObject?
    
    fileprivate dynamic var colorValueString: String?
    dynamic var colorValue: UIColor? {
        get {
            if let colorValueString = colorValueString,
                let data = colorValueString.data(using: String.Encoding.utf8),
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
            {
                return UIColorTransformType().transformFromJSON(json as AnyObject?)
            }
            return nil
        }
        set {
            if let newValue = newValue,
                let json = UIColorTransformType().transformToJSON(newValue),
                let data = try? JSONSerialization.data(withJSONObject: json),
                let stringValue = String(data: data, encoding: String.Encoding.utf8)
            {
                colorValueString = stringValue
            } else {
                colorValueString = nil
            }
        }
    }
    
    override class func collectionName() -> String {
        return "DataType"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        boolValue <- map["boolValue"]
        colorValue <- (map["colorValue"], UIColorTransformType())
        fullName <- map["fullName"]
        fullName2 <- (map["fullName2"], FullName2TransformType())
    }
    
    override class func ignoredProperties() -> [String] {
        return ["objectValue", "colorValue", "fullName2"]
    }
    
}

class FullName: Entity {
    
    dynamic var firstName: String?
    dynamic var lastName: String?
    
    override class func collectionName() -> String {
        return "FullName"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        firstName <- map["firstName"]
        lastName <- map["lastName"]
    }
    
}

class FullName2TransformType: TransformType {
    
    typealias Object = FullName2
    typealias JSON = JsonDictionary
    
    func transformFromJSON(_ value: Any?) -> FullName2? {
        if let value = value as? JsonDictionary {
            return FullName2(JSON: value)
        }
        return nil
    }
    
    func transformToJSON(_ value: FullName2?) -> JsonDictionary? {
        if let value = value {
            return value.toJSON()
        }
        return nil
    }
    
}

class FullName2: NSObject, Mappable {
    
    dynamic var firstName: String?
    dynamic var lastName: String?
    dynamic var fontDescriptor: UIFontDescriptor?
    
    override init() {
    }
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        firstName <- map["firstName"]
        lastName <- map["lastName"]
        fontDescriptor <- (map["fontDescriptor"], UIFontDescriptorTransformType())
    }
    
}

class UIFontDescriptorTransformType: TransformType {
    
    typealias Object = UIFontDescriptor
    typealias JSON = JsonDictionary
    
    func transformFromJSON(_ value: Any?) -> Object? {
        if let value = value as? JsonDictionary,
            let fontName = value[UIFontDescriptorNameAttribute] as? String,
            let fontSize = value[UIFontDescriptorSizeAttribute] as? CGFloat
        {
            return UIFontDescriptor(name: fontName, size: fontSize)
        }
        return nil
    }
    
    func transformToJSON(_ value: Object?) -> JSON? {
        if let value = value {
            return [
                UIFontDescriptorNameAttribute : value.fontAttributes[UIFontDescriptorNameAttribute]!,
                UIFontDescriptorSizeAttribute : value.fontAttributes[UIFontDescriptorSizeAttribute]!
            ]
        }
        return nil
    }
    
}
