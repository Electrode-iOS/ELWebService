# ELWebService 

[![Version](https://img.shields.io/badge/version-v4.0.3-blue.svg)](https://github.com/Electrode-iOS/ELWebService/releases/latest)
[![Build Status](https://travis-ci.org/Electrode-iOS/ELWebService.svg?branch=master)](https://travis-ci.org/Electrode-iOS/ELWebService) 
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

ELWebService is an HTTP framework for Swift built on Foundation's `URLSession`. Designed to integrate cleanly with `URLSession`, ELWebService avoids using the session delegate events and does not mutate the session's configuration.

## Requirements

ELWebService requires Swift 3 and Xcode 8.

## Installation

### Carthage

Install with [Carthage](https://github.com/Carthage/Carthage) by adding the framework to your project's [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

```
github "Electrode-iOS/ELWebService" ~> 4.0.3
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
  .setQueryParameters(["state" : "New York"])
  .response { (response: URLResponse?, data: Data?) in
    // process response data
  }
  .resume()
```

To handle the event of a failure provide a closure for error handling by calling the `responseError()` method.

```
let service = WebService(baseURLString: "https://brewhapi.herokuapp.com/")

service
  .GET("/brewers")
  .setQueryParameters(["state" : "New York"])
  .response { (response: URLResponse?, data: Data?) in
    // process response data
  }
  .responseError { (error: ErrorType) in
    // handle error
  }
  .resume()
```

The error handler will only be called after a request results in an error. If an error occurs all other response handlers will not be called. This pattern allows you to cleanly separate the logic for handling success and failure cases.

### Handling JSON responses

Use the `responseJSON()` method to serialize a successful response as a JSON value of type `Any`.

```
let service = WebService(baseURLString: "https://brewhapi.herokuapp.com/")

service
  .GET("/brewers")
  .setQueryParameters(["state" : "New York"])
  .responseJSON { (json: Any, response: URLResponse?) in
    // process response as JSON
  }
  .resume()
```


### Sending URL Query Parameters

Send a `GET` request with URL query parameters.

```
let service = WebService(baseURLString: "http://httpbin.org")
let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]

service
    .GET("/get")
    .setQueryParameters(parameters)
    .resume()
```

HTTP

```
GET /get?percentEncoded=this%20needs%20percent%20encoded&foo=bar HTTP/1.1

```

### Sending Form Data

Send a `POST` request with form parameter data in the request body.

```
let service = WebService(baseURLString: "http://httpbin.org")
let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]

service
    .POST("/post")
    .setFormParameters(parameters)
    .resume()
```

HTTP

```
POST /post HTTP/1.1
Content-Type: application/x-www-form-urlencoded
Content-Length: 55

percentEncoded=this%20needs%20percent%20encoded&foo=bar
```

### Sending JSON

Send a `POST` request with JSON encoded parameters.

```
let service = WebService(baseURLString: "http://httpbin.org")

service
    .POST("/post")
    .setJSON(["foo" : "bar", "number" : 42])
    .resume()
```

HTTP

```
POST /post HTTP/1.1
Content-Type: application/json
Content-Length: 25

{"number":42,"foo":"bar"}
```

### Error Handling

Error handlers are registered by providing a closure to run in the case the handler chain results in a failure.

```
service
    .GET("/brewers")
    .responseError { error in
      // I am error
    }
    .resume()
```

Sometimes your code may fail during processing a response and you will want to handle that failure in an error handler. For example, if you were parsing a JSON payload as an array of model types but the payload failed to be parsed as expected you can use `throw` to propogate an error of type `ErrorType` to indicate the parsing failure. When throwing an error from a response handler, all subsequent response handlers in the chain will not run and instead any registered error handlers will be called. 

```
service
    .GET("/brewers")
    .responseJSON { json, response in
        guard let models: [Brewer] = JSONDecoder<Brewer>.decode(json)  {
            throw JSONDecoderError.FailedToDecodeBrewer
        } 

        return .Value(models)
    }
    .responseError { error in
      // handle errors
    }
    .resume()
```

### Objective-C Interoperability

ELWebService supports Objective-C via specially-named response handler methods. See the [Objective-C Interoperability section](/docs/Programming-Guide.md#objective-c-interoperability) in the [ELWebService Programming Guide](/docs/Programming-Guide.md) for more information.

```
extension ServiceTask {
    internal typealias ObjCResponseHandler = (Data?, URLResponse?) -> ObjCHandlerResult?

    @objc public func responseObjC(handler: (Data?, URLResponse?) -> ObjCHandlerResult?) -> Self

    @objc public func responseJSONObjC(handler: (Any, URLResponse?) -> ObjCHandlerResult?) -> Self

    @objc public func responseErrorObjC(handler: (Error) -> Void) -> Self

    @objc public func updateUIObjC(handler: (Any?) -> Void) -> Self

    @objc public func updateErrorUIObjC(handler: (Error) -> Void) -> Self
}
```

### Mocking

ELWebService provides a simple but flexible mocking API that allows you to mock your web service's underlying session, data tasks, and data task result, the data passed to the data task's completion handler.

```
let expectation = expectationWithDescription("responseAsBrews handler called when JSON is valid")

// create a mock session
let session = MockSession()

// add a response stub to the session
let brewerJSON = ["name": "Long Trail Brewing Company", "location": "Vermont"]
let mockedResponse = MockResponse(statusCode: 200, json: ["brewers": [brewerJSON]])
session.addStub(mockedResponse)

// inject mock session as your web service's session
let service = WebService(baseURLString: "http://brewhapi.herokuapp.com/")
service.session = session

// make a request that will be fulfilled by the mocked response
service
    .fetchBrewWithBrewID("12345")
    .responseAsBrews { brews in
        XCTAssertEqual(brews.count, 1)
        expectation.fulfill()
    }.updateErrorUI { error in
        XCTFail("updateErrorUI handler should not be called when JSON is valid")
    }
    .resume()


waitForExpectationsWithTimeout(2.0, handler: nil)
```

For more information on the Mocking API see the [mocking section](/docs/Programming-Guide.md#mocking) of the ELWebService Programming Guide.

## Example Project

An [example project](/ELWebServiceExample) is included that demonstrates how ELWebService can be used to interact with a web service. The project uses [brewhapi](https://github.com/angelodipaolo/brewhapi) as a mock API for fetching and inserting data. brewhapi is freely hosted at [https://brewhapi.herokuapp.com/brews](https://brewhapi.herokuapp.com/brews) for testing.
