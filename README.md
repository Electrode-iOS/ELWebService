# Swallow

Swallow simplifies interaction with HTTP web services by providing a concise API for encoding `NSURLRequest` objects and processing the resulting `NSURLResponse` object. Designed as a lightweight utility for communicating with web services, Swallow is not intended to be a fully-featured networking library. By default Swallow uses the shared `NSURLSession` instance to create data tasks but can be configured to work with any NSURLSession instance using a [protocol](#sessiondatataskdatasource).

## Requirements

Swallow version 0.1.x requires Swift 2 and Xcode 7. For Xcode 6 and Swift 1.2 compatability use the latest [v0.0.x](https://github.com/TheHolyGrail/Swallow/releases/tag/v0.0.3) release.

## Installation

### Carthage

Install with [Carthage](https://github.com/Carthage/Carthage) by adding the framework to your project's [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

```
github "TheHolyGrail/Swallow" ~> 0.0.1
```

### Manual

Install manually by adding THGWebService.xcodeproj to your project and configuring your target to link THGWebService.framework.

[THG](https://github.com/TheHolyGrail/) modules are designed to live side-by-side in the file system, like so:

* \MyProject
* \MyProject\Swallow

## Usage

At the highest level a request for a resource could look like the following:

```
// fetch list of stores based on zip code value
WebService(baseURLString: "https://storelocator/")
    .searchStores(zipCode: "15217")
    .responseAsStoresModels { (stores: [StoreModel]) in
      // update UI with model data
    }
    .responseError { error in
      // I am error
    }
```

The `WebService` structure and `ServiceTask` class provide the basic building blocks to make this short and simple syntax possible.

### Sending HTTP Requests

At the lowest level `WebService` supports an API for making a HTTP request and processing the raw response data.

```
WebService(baseURLString: "https://storelocator/")
  .GET("/stores", parameters: ["zip" : "15217"])
  .response { (response: NSURLResponse?, data: NSData?) in
    // process response data
  }
```

Add a `responseError()` handler to handle the possibility of a failed request.

```
WebService(baseURLString: "https://storelocator/")
  .GET("/stores", parameters: ["zip" : "15217"])
  .response { (response: NSURLResponse?, data: NSData?) in
    // process response data
  }
  .responseError { (error: ErrorType) in
    // I am error
  }
```

The `responseError()` handler will only be called when a request results in an error. If an error occurs all other response handlers will not be called. This pattern allows you to cleanly separate the logic for handling success and failure cases.

### Response Handlers

Response handlers can be chained to process the response of the request. After the response is received handlers are invoked in the order of which they are declared.

```
WebService(baseURLString: "https://storelocator/")
  .GET("/stores", parameters: ["zip" : "15217"])
  .response { (response: NSURLResponse?, data: NSData?) in
    // process raw response
  }
  .responseJSON { json in
    // process response as JSON
  }
```

### Extensions

The chainable response handler API makes it easy to create custom response handlers using extensions.

```
// MARK: - Store Locator Services

extension ServiceTask {
    
    public typealias StoreServiceSuccess = ([StoreModel]) -> Void
    
    func responseAsStoresModels(handler: StoreServiceSuccess) -> Self {
        
        return responseJSON { json in
            if let models: [StoreModel] = self.parseJSONAsStoreModels(json) {
                handler(models)
            } else {
              self.throwError(.ModelSerializationFailure)
            }
        }
    }
}
```

This allows you to wrap the details of how the response is processed in a high-level convenience method enabling you to simplify how consumers interact with your web service API.

```
WebService(baseURLString: "https://storelocator/")
  .GET("/stores", parameters: ["zip" : "15217"])
  .responseAsStoresModels { (stores: [StoreModel]) in
    // process resonse as model objects and update UI
  }
  .responseError { error in
    // I am error
  }
```

Extensions are also useful for wrapping the details of the web service requests. This is an ideal approach because all of the details of the HTTP request are declared inline with the service call method.

```
public extension WebService {
    
    public func searchStores(zipCode zipCode: String) -> ServiceTask {
        return GET("/stores", parameters: ["zip" : zipCode])
    }
}
```

Extension methods are powerful constructs for wrapping the HTTP details of a web service call and provide a mechanism for your code to be declaritive about how to interact with web services.

```
WebService(baseURLString: "https://somehapi.herokuapp.com")
    .fetchStores(zipCode: "15217")
    .responseStoreModels { models in
      // update UI
    }
    .responseError { response, error in
      // I am error
    }
```

### Request Parameters

Request parameters are percent encoded and appended as a query string of the request URL for `GET` and `HEAD` requests. For all other request methods, parameters are sent as the request body and are encoded based on the `parameterEncoding` endpoint option.

##### Parameter Encodings

- `.Percent` - Encode parameters as a percent encoded query string.
- `.JSON` - Encode parameters as a JSON object.

##### Sending Parameters

Send a `GET` request with query parameters.

```
let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
WebService(baseURLString: "http://httpbin.org")
    .GET("/get", parameters: parameters)
```

HTTP


```
GET /stores?percentEncoded=this%20needs%20percent%20encoded&foo=bar HTTP/1.1

```


Send a `POST` request with body parameters.

```
let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
WebService(baseURLString: "http://httpbin.org")
    .POST("/post", parameters: parameters)
```

HTTP

```
POST /stores HTTP/1.1
Content-Length: 55

percentEncoded=this%20needs%20percent%20encoded&foo=bar
```

Send a `POST` request with JSON encoded parameters.

```
WebService(baseURLString: "http://httpbin.org")
    .POST("/post", 
        parameters: ["foo" : "bar", "number" : 42], 
        options: [.ParameterEncoding(.JSON)])
```

HTTP

```
POST /post HTTP/1.1
Content-Type: application/json
Content-Length: 25

{"number":42,"foo":"bar"}
```

### Options

An array of Option enum values can be passed as additional information to encode in the request.

```
WebService(baseURLString: "http://httpbin.org")
    .POST("/post", 
        parameters: ["foo" : "bar", "number" : 42], 
        options: [.ParameterEncoding(.JSON),
                  .Header("custom-header", "12345"),
                  .Header(Request.Headers.userAgent, "my app ua")])
```

### Error Handling


To handle the event of a failure call the `responseError` method with a closure. The closure will be called in the event of a failure.

```
WebService(baseURLString: "https://storelocator/")
    .GET("/foo")
    .responseError { error in
      // I am error
    }
```

Sometimes your code may fail during processing a response and you will want to handle that failure in an error handler. For example, if you were parsing a JSON payload as an array of model types but the payload failed to be parsed as expected you can call `throwError()` to propogate an error to the error handler.


```
func responseAsStoreModels(handler: ([StoreModel]) -> Void) -> Self {
    return responseJSON { json in    
        if let models = self.parseJSONAsStoreModels(json) {
            handler(models)
        } else {
            self.throwError(self.modelParseError())
        }
    }
}
```

Now an error handler can be used to seperate the case of handling request failures as well as model parsing failures.


```
WebService(baseURLString: "https://storelocator/")
    .GET("/stores")
    .responseAsStoreModels { models
      // valid Foo models
    }
    .responseError { error in
      // error handler will be called if JSON 
      // payload fails to parse as model values
    }
```

### Protocols

##### SessionDataTaskDataSource

The `SessionDataTaskDataSource` protocol is provided to allow Swallow to work with any NSURLSession-based API. Types conforming to the `SessionDataTaskDataSource` protocol are responsible for creating `NSURLSessionDataTask` objects based on a `NSURLRequest` value and invoking a completion handler after the response of a data task has been received.

By default Swallow implements the `SessionDataTaskDataSource` protocol as a private structure using the shared session returned from `NSURLSession.sharedSession()`. 

### Dispatch Queues

The dispatch queue used to execute the response handler can be specified as the first parameter of a response handler. Unless specified all response handler are run on the main dispatch queue.

```
let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)

WebService(baseURLString: "https://somehapi.herokuapp.com")
  .GET("/stores", parameters: ["zip" : "15217"])
  .response(queue) { (response: NSURLResponse?, data: NSData?) in
    // process response data
  }
```

### KillerRabbit

Swallow includes an optional `ServiceTask` extension that makes it easy to use [KillerRabbit](https://github.com/TheHolyGrail/KillerRabbit) dispatch queue values to specify which queue response handlers run on. Add the file `Source/Extensions/Swallow+KillerRabbit.swift` to your project as well as the KillerRabbit module to use the extension.

```
WebService(baseURLString: "https://somehapi.herokuapp.com")
  .GET("/stores", parameters: ["zip" : "15217"])
  .responseOnDispatchQueue(.Background) { (response: NSURLResponse?, data: NSData?) in
    // process response data
  }
```


## Example

An example project is included that demonstrates how Swallow can be used to interact with a web service. A stubbed endpoint is available at [https://somehapi.herokuapp.com/stores](https://somehapi.herokuapp.com/stores) for testing.

## Contributions

We appreciate your contributions to all of our projects and look forward to interacting with you via Pull Requests, the issue tracker, via Twitter, etc.  We're happy to help you, and to have you help us.  We'll strive to answer every PR and issue and be very transparent in what we do.

When contributing code, please refer to our style guide [Dennis](https://github.com/TheHolyGrail/Dennis).

###### THG's Primary Contributors

Dr. Sneed ([@bsneed](https://github.com/bsneed))<br>
Steve Riggins ([@steveriggins](https://github.com/steveriggins))<br>
Sam Grover ([@samgrover](https://github.com/samgrover))<br>
Angelo Di Paolo ([@angelodipaolo](https://github.com/angelodipaolo))<br>
Cody Garvin ([@migs647](https://github.com/migs647))<br>
Wes Ostler ([@wesostler](https://github.com/wesostler))<br>

## License

The MIT License (MIT)

Copyright (c) 2015 Walmart, TheHolyGrail, and other Contributors

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
