//
//  Book.swift
//  Bookshelf
//
//  Created by Victor Barros on 2016-02-08.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Kinvey
import ObjectMapper

/*
 If you want to save the authors when you save a Book, here is some collection hooks that can help you:
 
function onPreSave(request, response, modules) {
  var collectionAccess = modules.collectionAccess;
  var bluebird = modules.bluebird;
  var logger = modules.logger;
  var authorCollectionName = 'Author';
  var authorCollection = collectionAccess.collection(authorCollectionName);
  var promises = [];
  request.body.authors.forEach(function(author, index) {
    author._id = collectionAccess.objectID(author._id);
    var promise = authorCollection.saveAsync(author);
    promise.then(function(author) {
      request.body.authors[index] = {
        "collection" : authorCollectionName,
        "_id" : author._id
      }
    });
    promises.push(promise);
  });
  bluebird.all(promises).then(function() {
    response.continue();
  });
}
 
function onPostSave(request, response, modules) {
  var collectionAccess = modules.collectionAccess;
  var bluebird = modules.bluebird;
  var authorCollectionName = 'Author';
  var authorCollection = collectionAccess.collection(authorCollectionName);
  var book = response.body;
  var authors = [];
  var authorsPromises = [];
  book.authors.forEach(function(author, authorIndex) {
    var query = {'_id' : modules.collectionAccess.objectID(author._id)};
    var promise = authorCollection.findOneAsync(query);
    promise.then(function(author) {
      authors.push(author);
    });
    authorsPromises.push(promise);
  });
  bluebird.all(authorsPromises).then(function() {
    book.authors = authors;
    response.body = book;
    response.continue();
  });
}
 
function onPostFetch(request, response, modules) {
	var collectionAccess = modules.collectionAccess;
  var logger = modules.logger;
  var bluebird = modules.bluebird;
  var bookCollection = collectionAccess.collection('Book');
  var authorCollection = collectionAccess.collection('Author');
  var query = {};
  bookCollection.findAsync(query).then(function(books) {
    var results = [];
    var booksPromises = [];
    books.forEach(function(book, bookIndex) {
      var authors = [];
      var authorsPromises = [];
      book.authors.forEach(function(author, authorIndex) {
        var query = {'_id' : modules.collectionAccess.objectID(author._id)};
        var promise = authorCollection.findOneAsync(query);
        promise.then(function(author) {
          authors.push(author);
        });
        authorsPromises.push(promise);
      });
      var promise = bluebird.all(authorsPromises).then(function() {
        book.authors = authors;
        results.push(book);
      });
      booksPromises.push(promise);
    });
    bluebird.all(booksPromises).then(function() {
      response.body = results;
      response.continue(200);
    });
  });
}
 
 */
class Book: Entity, Codable {
    
    @objc dynamic var title: String?
    let authors = List<Author>()
    
    override class func collectionName() -> String {
        //return the name of the backend collection corresponding to this entity
        return "Book"
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case authors
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        if let authors = try container.decodeIfPresent(List<Author>.self, forKey: .authors) {
            self.authors.removeAll()
            self.authors.append(objectsIn: authors)
        }
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(authors, forKey: .authors)
    }
    
    @available(*, deprecated)
    required init?(map: Map) {
        super.init(map: map)
    }
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
}
