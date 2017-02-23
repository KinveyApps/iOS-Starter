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
class Book: Entity {
    
    dynamic var title: String?
    let authors = List<Author>()
    
    override class func collectionName() -> String {
        //return the name of the backend collection corresponding to this entity
        return "Book"
    }
    
    //Map properties in your backend collection to the members of this entity
    override func propertyMapping(_ map: Map) {
        
        //This maps the "_id", "_kmd" and "_acl" properties
        super.propertyMapping(map)
        
        //Each property in your entity should be mapped using the following scheme:
        //<member variable> <- ("<backend property>", map["<backend property>"])
        title <- ("title", map["title"])
        authors <- ("authors", map["authors"])
    }
}

func <-(lhs: List<Author>, rhs: (String, Map)) {
    var list = lhs
    let transform = TransformOf<List<Author>, [[String : Any]]>(fromJSON: { (array) -> List<Author>? in
        if let array = array {
            list.removeAll()
            for item in array {
                if let item = Author(JSON: item) {
                    list.append(item)
                }
            }
            return list
        }
        return nil
    }, toJSON: { (list) -> [[String : Any]]? in
        if let list = list {
            return list.map { $0.toJSON() }
        }
        return nil
    })
    switch rhs.1.mappingType {
    case .fromJSON:
        list <- (rhs.1, transform)
    case .toJSON:
        list <- (rhs.1, transform)
    }
}
