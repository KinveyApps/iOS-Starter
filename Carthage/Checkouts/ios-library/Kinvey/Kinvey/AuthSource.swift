//
//  SocialChannel.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/**
 Authentication Source for login with a social identity.
 */
public enum AuthSource: String {

    /// Facebook social identity
    case facebook = "facebook"
    
    /// Twitter social identity
    case twitter = "twitter"
    
    /// Google+ social identity
    case googlePlus = "google"
    
    /// LinkedIn social identity
    case linkedIn = "linkedIn"
    
    /// Kinvey MIC social identity
    case kinvey = "kinveyAuth"
    
}
