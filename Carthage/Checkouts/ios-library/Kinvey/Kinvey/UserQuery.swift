//
//  UserQuery.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-21.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/**
 Struct that contains all the parameters available for user lookup.
 */
public final class UserQuery: Mappable, BuilderType {
    
    /// Filter by User's ID
    public var userId: String?
    
    /// Filter by User's Username
    public var username: String?
    
    /// Filter by User's First Name
    public var firstName: String?
    
    /// Filter by User's Last Name
    public var lastName: String?
    
    /// Filter by User's Email
    public var email: String?
    
    /// Filter by User's Facebook ID
    public var facebookId: String?
    
    /// Filter by User's Facebook Name
    public var facebookName: String?
    
    /// Filter by User's Twitter ID
    public var twitterId: String?
    
    /// Filter by User's Twitter Name
    public var twitterName: String?
    
    /// Filter by User's Google ID
    public var googleId: String?
    
    /// Filter by User's Google Given Name
    public var googleGivenName: String?
    
    /// Filter by User's Google Family Name
    public var googleFamilyName: String?
    
    /// Filter by User's LinkedIn ID
    public var linkedInId: String?
    
    /// Filter by User's LinkedIn First Name
    public var linkedInFirstName: String?
    
    /// Filter by User's LinkedIn Last Name
    public var linkedInLastName: String?
    
    /// Default Constructor.
    public init() {
    }
    
    /// Constructor for object mapping.
    public init?(map: Map) {
    }
    
    /// Performs the object mapping.
    public func mapping(map: Map) {
        userId <- map["_id"]
        username <- map["username"]
        firstName <- map["first_name"]
        lastName <- map["last_name"]
        email <- map["email"]
        facebookId <- map["_socialIdentity.facebook.id"]
        facebookName <- map["_socialIdentity.facebook.name"]
        twitterId <- map["_socialIdentity.twitter.id"]
        twitterName <- map["_socialIdentity.twitter.name"]
        googleId <- map["_socialIdentity.google.id"]
        googleGivenName <- map["_socialIdentity.google.given_name"]
        googleFamilyName <- map["_socialIdentity.google.family_name"]
        linkedInId <- map["_socialIdentity.linkedIn.id"]
        linkedInFirstName <- map["_socialIdentity.linkedIn.firstName"]
        linkedInLastName <- map["_socialIdentity.linkedIn.lastName"]
    }
    
}
