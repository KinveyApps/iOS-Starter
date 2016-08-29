# PromiseKit OMGHTTPURLRQ Extensions ![Build Status]

This project provides convenience methods on NSURLSession using [OMGHTTPURLRQ].

## CococaPods

```ruby
pod "PromiseKit/OMGHTTPURLRQ" ~> 4.0
```

The extensions are built into `PromiseKit.framework` thus nothing else is needed.

## Carthage

```ruby
github "PromiseKit/OMGHTTPURLRQ" ~> 1.0
```

The extensions are built into their own framework:

```swift
// swift
import PromiseKit
import OMGHTTPURLRQ
import PMKOMGHTTPURLRQ
```

```objc
// objc
@import PromiseKit;
@import OMGHTTPURLRQ;
@import PMKOMGHTTPURLRQ;
```


[Build Status]: https://travis-ci.org/PromiseKit/OMGHTTPURLRQ.svg?branch=master
