//
//  QueryTest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import MapKit
@testable import Kinvey

class QueryTest: XCTestCase {
    
    func encodeQuery(_ query: Query) -> String {
        return query.queryParams.urlQueryEncoded.removingPercentEncoding!
    }
    
    func encodeURL(_ query: JsonDictionary) -> String {
        let data = try! JSONSerialization.data(withJSONObject: query)
        let str = String(data: data, encoding: String.Encoding.utf8)!
        return str
    }
    
    func testQueryEq() {
        XCTAssertEqual(encodeQuery(Query(format: "age == %@", 30)), "query=\(encodeURL(["age" : 30]))")
        XCTAssertEqual(encodeQuery(Query(format: "age = %@", 30)), "query=\(encodeURL(["age" : 30]))")
    }
    
    func testQueryGt() {
        XCTAssertEqual(encodeQuery(Query(format: "age > %@", 30)), "query=\(encodeURL(["age" : ["$gt" : 30]]))")
    }
    
    func testQueryGte() {
        XCTAssertEqual(encodeQuery(Query(format: "age >= %@", 30)), "query=\(encodeURL(["age" : ["$gte" : 30]]))")
    }
    
    func testQueryLt() {
        XCTAssertEqual(encodeQuery(Query(format: "age < %@", 30)), "query=\(encodeURL(["age" : ["$lt" : 30]]))")
    }
    
    func testQueryLte() {
        XCTAssertEqual(encodeQuery(Query(format: "age <= %@", 30)), "query=\(encodeURL(["age" : ["$lte" : 30]]))")
    }
    
    func testQueryNe() {
        XCTAssertEqual(encodeQuery(Query(format: "age != %@", 30)), "query=\(encodeURL(["age" : ["$ne" : 30]]))")
        XCTAssertEqual(encodeQuery(Query(format: "age <> %@", 30)), "query=\(encodeURL(["age" : ["$ne" : 30]]))")
    }
    
    func testQueryIn() {
        XCTAssertEqual(encodeQuery(Query(format: "colors IN %@", ["orange", "black"])), "query=\(encodeURL(["colors" : ["$in" : ["orange", "black"]]]))")
    }
    
    func testQueryOr() {
        XCTAssertEqual(encodeQuery(Query(format: "age = %@ OR age = %@", 18, 21)), "query=\(encodeURL(["$or" : [["age" : 18], ["age" : 21]]]))")
    }
    
    func testQueryAnd() {
        XCTAssertEqual(encodeQuery(Query(format: "age = %@ AND age = %@", 18, 21)), "query=\(encodeURL(["$and" : [["age" : 18], ["age" : 21]]]))")
    }
    
    func testQueryNot() {
        XCTAssertEqual(encodeQuery(Query(format: "NOT age = %@", 30)), "query=\(encodeURL(["$not" : [["age" : 30]]]))")
    }
    
    func testQueryRegex() {
        XCTAssertEqual(encodeQuery(Query(format: "name MATCHES %@", "acme.*corp")), "query=\(encodeURL(["name" : ["$regex" : "acme.*corp"]]))")
    }

    func testQueryBeginsWith() {
        XCTAssertEqual(encodeQuery(Query(format: "name BEGINSWITH %@", "acme")), "query=\(encodeURL(["name" : ["$regex" : "^acme"]]))")
    }

    
    func testQueryGeoWithinCenterSphere() {
        let resultString = encodeQuery(Query(format: "location = %@", MKCircle(center: CLLocationCoordinate2D(latitude: 40.74, longitude: -74), radius: 10000)))
        let expectString = encodeURL(["location" : ["$geoWithin" : ["$centerSphere" : [ [-74, 40.74], 10/6378.1 ]]]])
        
        XCTAssertTrue(resultString.hasPrefix("query={"))
        XCTAssertTrue(resultString.hasSuffix("}"))
        let resultQueryString = (resultString as NSString).substring(from: "query=".characters.count) as String
        let result = try! JSONSerialization.jsonObject(with: resultQueryString.data(using: String.Encoding.utf8)!, options: []) as? [String : [String : [String : [AnyObject]]]]
        let expect = try! JSONSerialization.jsonObject(with: expectString.data(using: String.Encoding.utf8)!, options: []) as? [String : [String : [String : [AnyObject]]]]
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(expect)
        
        if var result = result, var expect = expect {
            let centerSphereResult = result["location"]!["$geoWithin"]!["$centerSphere"]!
            let centerSphereExpect = expect["location"]!["$geoWithin"]!["$centerSphere"]!
            
            XCTAssertEqual(centerSphereResult.count, 2)
            XCTAssertEqual(centerSphereExpect.count, 2)
            
            if centerSphereResult.count == 2 && centerSphereExpect.count == 2 {
                let coordinatesResult = centerSphereResult[0] as! [Double]
                let coordinatesExpect = centerSphereExpect[0] as! [Double]
                
                XCTAssertEqual(coordinatesResult.count, 2)
                XCTAssertEqual(coordinatesExpect.count, 2)
                
                XCTAssertEqual(coordinatesResult, coordinatesExpect)
                
                XCTAssertEqualWithAccuracy(centerSphereResult[1] as! Double, centerSphereExpect[1] as! Double, accuracy: 0.00001)
            }
        }
    }
    
    func testQueryGeoWithinPolygon() {
        var coordinates = [CLLocationCoordinate2D(latitude: 40.74, longitude: -74), CLLocationCoordinate2D(latitude: 50.74, longitude: -74), CLLocationCoordinate2D(latitude: 40.74, longitude: -64)]
        let resultString = encodeQuery(Query(format: "location = %@", MKPolygon(coordinates: &coordinates, count: 3)))
        let expectString = encodeURL(["location" : ["$geoWithin" : ["$geometry" : ["type" : "Polygon", "coordinates" : [[-74, 40.74], [-74, 50.74], [-64, 40.74]]]]]])
        
        XCTAssertTrue(resultString.hasPrefix("query={"))
        XCTAssertTrue(resultString.hasSuffix("}"))
        let resultQueryString = (resultString as NSString).substring(from: "query=".characters.count) as String
        let result = try! JSONSerialization.jsonObject(with: resultQueryString.data(using: String.Encoding.utf8)!) as? [String : [String : [String : [String : AnyObject]]]]
        let expect = try! JSONSerialization.jsonObject(with: expectString.data(using: String.Encoding.utf8)!) as? [String : [String : [String : [String : AnyObject]]]]
        
        if var result = result, var expect = expect {
            let geometryResult = result["location"]!["$geoWithin"]!["$geometry"]!
            let geometryExpect = expect["location"]!["$geoWithin"]!["$geometry"]!
            
            XCTAssertEqual(geometryResult["type"] as? String, geometryExpect["type"] as? String)
            
            let coordinatesResult = geometryResult["coordinates"] as? [[Double]]
            let coordinatesExpect = geometryExpect["coordinates"] as? [[Double]]
            
            XCTAssertNotNil(coordinatesResult)
            XCTAssertNotNil(coordinatesExpect)
            
            if let coordinatesResult = coordinatesResult, let coordinatesExpect = coordinatesExpect {
                XCTAssertEqual(coordinatesResult.count, coordinatesExpect.count)
                for (index, _) in coordinatesResult.enumerated() {
                    XCTAssertEqual(coordinatesResult[index].count, coordinatesExpect[index].count)
                }
            }
        }
    }
    
    func testSortAscending() {
        XCTAssertEqual(encodeQuery(Query(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])), "sort=\(encodeURL(["name" : 1]))")
    }
    
    func testSortDescending() {
        XCTAssertEqual(encodeQuery(Query(sortDescriptors: [NSSortDescriptor(key: "name", ascending: false)])), "sort=\(encodeURL(["name" : -1]))")
    }
    
    func testSkip() {
        XCTAssertEqual(encodeQuery(Query { $0.skip = 100 }), "skip=100")
    }
    
    func testLimit() {
        XCTAssertEqual(encodeQuery(Query { $0.limit = 100 }), "limit=100")
    }
    
    func testSkipAndLimit() {
        XCTAssertEqual(encodeQuery(Query { $0.skip = 100; $0.limit = 300 }), "skip=100&limit=300")
    }
    
    func testPredicateSortSkipAndLimit() {
        XCTAssertEqual(encodeQuery(Query { $0.predicate = NSPredicate(format: "lastName == %@", "Barros"); $0.sortDescriptors = [NSSortDescriptor(key: "age", ascending: false)]; $0.skip = 2; $0.limit = 5 }), "query=\(encodeURL(["lastName" : "Barros"]))&limit=5&skip=2&sort=\(encodeURL(["age" : -1]))")
    }
    
}
