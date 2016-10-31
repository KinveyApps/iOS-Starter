//
//  RealmResults.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class Results<T: Object>: NSFastEnumeration, Collection {
    
    typealias Iterator = RealmSwift.Results<T>.Iterator
    typealias SubSequence = RealmSwift.Results<T>.SubSequence
    typealias Index = RealmSwift.Results<T>.Index
    typealias _Element = RealmSwift.Results<T>._Element
    
    let results: RealmSwift.Results<T>
    
    init(_ results: RealmSwift.Results<T>) {
        self.results = results
    }
    
    var count: Int {
        return results.count
    }
    
    func countByEnumerating(with state: UnsafeMutablePointer<NSFastEnumerationState>, objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>, count len: Int) -> Int {
        return results.countByEnumerating(with: state, objects: buffer, count: len)
    }
    
    var startIndex: Index {
        get {
            return results.startIndex
        }
    }
    
    var endIndex: Index {
        get {
            return results.endIndex
        }
    }
    
    subscript (position: Index) -> _Element {
        get {
            return results[position]
        }
    }
    
    func makeIterator() -> Iterator {
        return results.makeIterator()
    }
    
    subscript (bounds: Range<Index>) -> SubSequence {
        get {
            return results[bounds]
        }
    }
    
    func prefix(upTo end: Index) -> SubSequence {
        return results.prefix(upTo: end)
    }
    
    func suffix(from start: Index) -> SubSequence {
        return results.suffix(from: start)
    }
    
    func prefix(through position: Index) -> SubSequence {
        return results.prefix(through: position)
    }
    
    var isEmpty: Bool {
        get {
            return results.isEmpty
        }
    }
    
    var first: Iterator.Element? {
        get {
            return results.first
        }
    }
    
    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index value immediately after `i`.
    public func index(after i: Int) -> Int {
        return results.index(after: i)
    }
    
}
