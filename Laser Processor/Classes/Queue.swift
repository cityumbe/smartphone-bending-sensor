//
//  Queue.swift
//  NTBSwift
//
//  Created by Kåre Morstøl on 11/07/14. modified by Xinhong on 26 Apr, 2016
//
//  Using the "Two-Lock Concurrent Queue Algorithm" from http://www.cs.rochester.edu/research/synchronization/pseudocode/queues.html#tlq, without the locks.


// should be an inner class of Queue, but inner classes and generics crash the compiler, SourceKit (repeatedly) and occasionally XCode.
class _QueueItem<T> {
    let value: T!
    var next: _QueueItem?
    
    init(_ newvalue: T?) {
        self.value = newvalue
    }
}

///
/// A standard queue (FIFO - First In First Out). Supports simultaneous adding and removing, but only one item can be added at a time, and only one item can be removed at a time.
///
public class Queue<T> {
    
    var _front: _QueueItem<T>
    var _back: _QueueItem<T>
    private var _size: Int
    
    public init () {
        // Insert dummy item. Will disappear when the first item is added.
        _back = _QueueItem(nil)
        _front = _back
        _size = 0
    }
    
    /// Add a new item to the back of the queue.
    public func enqueue (value: T) {
        _back.next = _QueueItem(value)
        _back = _back.next!
        _size = _size + 1
    }
    
    /// Return and remove the item at the front of the queue.
    public func dequeue () -> T? {
        if let newhead = _front.next {
            _front = newhead
            _size = _size - 1
            return newhead.value
        } else {
            return nil
        }
    }
    
    public func isEmpty() -> Bool {
        return _front === _back
    }
    
    public func size() -> Int {
        return _size
    }
}