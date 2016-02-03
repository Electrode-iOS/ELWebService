# ELWebService [![Build Status](https://travis-ci.org/Electrode-iOS/ELWebService.svg?branch=master)](https://travis-ci.org/Electrode-iOS/ELWebService) [![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

ELWebService (previously named Swallow) simplifies interaction with HTTP web services by providing a concise API for encoding `NSURLRequest` objects and processing the resulting `NSURLResponse` object. Designed as a lightweight utility for communicating with web services, ELWebService is not intended to be a fully-featured networking library. By default ELWebService uses the shared `NSURLSession` instance to create data tasks but can be configured to work with any `NSURLSession` instance using a [protocol](#sessiondatataskdatasource).

See the [ELWebService Programming Guide](/docs/Programming-Guide.md) for more information. 

## Requirements

ELWebService requires Swift 2.1 and Xcode 7.2.

## Installation

### Carthage

Install with [Carthage](https://github.com/Carthage/Carthage) by adding the framework to your project's [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

```
github "Electrode-iOS/ELWebService" ~> 2.2.0
```

### Manual

Install manually by adding `ELWebService.xcodeproj` to your project and configuring your target to link `ELWebService.framework`.

## Usage

Below is a quick overview of how to get started using ELWebService. See the [ELWebService Programming Guide](/docs/Programming-Guide.md) for detailed usage information.


### Sending HTTP Requests

`WebService` provides an API for making a HTTP request and processing the response data.

```
let service = WebService(baseURLString: "https://brewhapi.herokuapp.com/")

service
  .GET("/brewers")
  .setParameters(["state" : "New York"])
  .response { (response: NSURLResponse?, data: NSData?) in
    // process response data
  }
  .resume()
```

To handle the event of a failure provide a closure for error handling by calling the `responseError()` method.

```
let service = WebService(baseURLString: "https://brewhapi.herokuapp.com/")

service
  .GET("/brewers")
  .setParameters(["state" : "New York"])
  .response { (response: NSURLResponse?, data: NSData?) in
    // process response data
  }
  .responseError { (error: ErrorType) in
    // handle error
  }
  .resume()
```

The error handler will only be called after a request results in an error. If an error occurs all other response handlers will not be called. This pattern allows you to cleanly separate the logic for handling success and failure cases.

### JSON

Use the `responseJSON()` method to serialize a successful response as a JSON value of type `AnyObject`.

```
let service = WebService(baseURLString: "https://brewhapi.herokuapp.com/")

service
  .GET("/brewers")
  .setParameters(["state" : "New York"])
  .responseJSON { (json: AnyObject) in
    // process response as JSON
  }
  .resume()
```

### Request Parameters

Request parameters are percent encoded and appended as a query string of the request URL for `GET` and `HEAD` requests. For all other request methods, parameters are sent as the request body and are encoded based on the `parameterEncoding` endpoint option.

##### Parameter Encodings

- `.Percent` - Encode parameters as a percent encoded query string.
- `.JSON` - Encode parameters as a JSON object.

##### Sending Parameters

Send a `GET` request with query parameters.

```
let service = WebService(baseURLString: "http://httpbin.org")
let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]

service
    .GET("/get")
    .setParameters(parameters)
    .resume()
```

HTTP


```
GET /get?percentEncoded=this%20needs%20percent%20encoded&foo=bar HTTP/1.1

```


Send a `POST` request with body parameters.

```
let service = WebService(baseURLString: "http://httpbin.org")
let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
service
    .POST("/post")
    .setParameters(parameters)
    .resume()
```

HTTP

```
POST /post HTTP/1.1
Content-Length: 55

percentEncoded=this%20needs%20percent%20encoded&foo=bar
```

Send a `POST` request with JSON encoded parameters.

```
let service = WebService(baseURLString: "http://httpbin.org")

service
    .POST("/post") 
    .setParameters(["foo" : "bar", "number" : 42], encoding: .JSON)
    .resume()
```

HTTP

```
POST /post HTTP/1.1
Content-Type: application/json
Content-Length: 25

{"number":42,"foo":"bar"}
```

Alternatively you can specify the explicit JSON payload to send as the request body.

```
let service = WebService(baseURLString: "http://httpbin.org")

service
    .POST("/post") 
    .setJSON(["hmm": ["foo" : "bar", "number" : 42]])
    .resume()
```

HTTP

```
POST /post HTTP/1.1
Content-Type: application/json
Content-Length: 25

{"hmm":{"number":42,"foo":"bar"}}
```

### Error Handling


Error handlers are registered by providing a closure to run in the case the handler chain results in a failure.

```
let service = WebService(baseURLString: "https://somehapi.herokuapp.com")

service
    .GET("/foo")
    .responseError { error in
      // I am error
    }
    .resume()
```

Sometimes your code may fail during processing a response and you will want to handle that failure in an error handler. For example, if you were parsing a JSON payload as an array of model types but the payload failed to be parsed as expected you can return a `.Failure` result with an associated value that conforms to Swift's `ErrorType` protocol. When returning a `.Failure` result all subsequent response handlers in the chain will not run and instead any registered error handlers will be called.

```
let service = WebService(baseURLString: "https://somehapi.herokuapp.com")

service
    .GET("/brewers")
    .responseJSON { json in
        if let models: [Brewer] = JSONDecoder<Brewer>.decode(json)  {
            return .Value(models)
        } else {
          // any value conforming to ErrorType
          return .Failure(JSONDecoderError.FailedToDecodeBrewer) 
        }
    }
    .responseError { error in
      // handle errors
    }
    .resume()
```

### Protocols

##### SessionDataTaskDataSource

The `SessionDataTaskDataSource` protocol is provided to allow ELWebService to work with any NSURLSession-based API. Types conforming to the `SessionDataTaskDataSource` protocol are responsible for creating `NSURLSessionDataTask` objects based on a `NSURLRequest` value and invoking a completion handler after the response of a data task has been received.

By default ELWebService uses the shared session that is provided by `NSURLSession.sharedSession()`.


### Extensions

Add custom request methods by extending `WebService`.

```
public extension WebService {
    
    public func fetchBrewers(state state: String) -> ServiceTask {
        return GET("/brewers").setParameters(["state" : name])
    }
}
```

The chainable service task API makes it easy to create custom response handlers by extending `ServiceTask`.

```
extension ServiceTask {

    func responseAsBrewers(handler: ([Brewer]) -> Void) -> Self {
        return 
            responseJSON { json in
              if let models: [Brewer] = JSONDecoder<Brewer>.decode(json)  {
                  return .Value(models)
              } else {
                // any value conforming to ErrorType
                return .Failure(JSONDecoderError.FailedToDecodeBrewer) 
              }
            }
            .updateUI { value in
                if let brewers = value as? [Brewer] {
                  handler(value)
                }
            }
    }
}
```

Custom request methods and response handlers help make interactions with the web service more expressive.

```
let service = WebService(baseURLString: "https://somehapi.herokuapp.com")

service
    .fetchBrewers(state: "New York")
    .responseAsBrewers { (stores: [Brewer]) in
      // update UI with model data
    }
    .responseError { error in
      // handle error
    }
    .resume()
```

### Objective-C Interoperability

ELWebService supports Objective-C via specially-named response handler methods. See the [Objective-C Interoperability section](/docs/Programming-Guide.md#objective-c-interoperability) in the [ELWebService Programming Guide](/docs/Programming-Guide.md) for more information. 

```
extension ServiceTask {
    internal typealias ObjCResponseHandler = (NSData?, NSURLResponse?) -> ObjCHandlerResult?

    @objc public func responseObjC(handler: (NSData?, NSURLResponse?) -> ObjCHandlerResult?) -> Self

    @objc public func responseJSONObjC(handler: (AnyObject) -> ObjCHandlerResult?) -> Self

    @objc public func responseErrorObjC(handler: (NSError) -> Void) -> Self

    @objc public func updateUIObjC(handler: (AnyObject?) -> Void) -> Self

    @objc public func updateErrorUIObjC(handler: (NSError) -> Void) -> Self
}
```

## Example Project

An [example project](/ELWebServiceExample) is included that demonstrates how ELWebService can be used to interact with a web service. The project uses [brewhapi](https://github.com/angelodipaolo/brewhapi) as a mock API for fetching and inserting data. brewhapi is freely hosted at [https://brewhapi.herokuapp.com/brews](https://brewhapi.herokuapp.com/brews) for testing.

## Contributions

We appreciate your contributions to all of our projects and look forward to interacting with you via Pull Requests, the issue tracker, via Twitter, etc.  We're happy to help you, and to have you help us.  We'll strive to answer every PR and issue and be very transparent in what we do.

When contributing code, please refer to our style guide [Dennis](https://github.com/Electrode-iOS/Dennis).

## License

The MIT License (MIT)

Copyright (c) 2015 Walmart and other Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
