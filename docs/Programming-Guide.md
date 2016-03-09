# ELWebService Programming Guide

## About ELWebService

[ELWebService](https://github.com/Electrode-iOS/ELWebService) is a lightweight HTTP networking framework written in Swift. ELWebService simplifies interaction with HTTP web services by providing a concise API for encoding a `NSURLRequest` object and processing the resulting `NSURLResponse`. 

Unlike many other iOS networking libraries, ELWebService is not a wrapper around `NSURLSession` or `NSURLConnection`. Instead ELWebService is designed to be unobtrusive by acting as a convenience for working with request and response objects while leaving the crucial implementation details of the various session delegate methods up to the developer.

Apple has done a great job of providing the fundamentals that you would expect from a networking API via `NSURLSession`. It is a modern and flexible API that leaves little need for bulky abstractions. Although `NSURLRequest` and `NSURLResponse` are simple to use they offer little in terms of utilizing the expressiveness and safety you get with Swift's syntax.

ELWebService was built to offer simple but powerful constructs for enabling your code to easily take advantage of some of the modern features in Swift.

## How ELWebService Works with NSURLSession

By default ELWebService uses the shared session returned from `NSURLSession.sharedSession()` to create data tasks but can be customized to work with any session instance. This gives you the freedom to provide your own `NSURLSession` instance while giving you a lightweight API for dispatching and handling `NSURLSessionDataTask` objects.

By conforming to `Session`, your code has complete control over the `NSURLSession` configuration and simply provides a `NSURLSessionDataTask` for ELWebService to work with.

```
class MySession: Session {
    func dataTask(request request: URLRequestEncodable, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> DataTask {
        return NSURLSession.sharedSession().dataTaskWithRequest(request.urlRequestValue, completionHandler: completion) as DataTask
    }
}
```
Configure ELWebService to use your session.

```
var client = WebService(baseURLString: "http://myapi")
client.session = MySession() // use custom `NSURLSession` instance
```

To simplify usage further, `NSURLSession` already conforms to the `Session` protocol which allows you to set the `session` property directly with a `NSURLSession` instance.

```
client.session = NSURLSession(configuration: NSURLSessionConfiguration())
```

## Sending Requests

First we'll initialize a `WebService` value and provide it with a base URL. You can think of `WebService` as the HTTP client of the web service API we are consuming.

```
let brewClient = WebService(baseURLString: "http://brewhapi.herokuapp.com/")
```

Now that we have a client we can send a request by calling the `GET` method and passing it a relative path. The client's base URL is used to construct an absolute URL that is relative to the path passed to `GET`.

```
brewClient
    .GET("/brewers")
    .resume()
```

The code above sends a GET request with the URL "http://brewhapi.herokuapp.com/brewers". Along with GET, `WebService` also offers methods for POST, DELETE, and other common HTTP verbs.

## Handling Responses

A successful response is handled asynchronously by defining a closure to process the response and registering it as a response handler using the `response()` method.

```
brewClient
    .GET("/brewers")
    .response { data, response in
        // process response
    }
    .resume()
```

The response closure will only be called if the request does not result in an error. To handle the event of a failure provide a closure for error handling by calling the `responseError()` method.

```
brewClient
    .GET("/brewers")
    .response { data, response in
        // process response
    }
    .responseError { error in
        print("I AM ERROR \(error)")
    }
    .resume()
```

Request methods like `GET()` return a `ServiceTask` object that represents the lifetime of a given `NSURLSessionDataTask`. The handler methods return their `self` instance which enables you to chain handlers resulting in concise and expressive code.

After the response is received handlers are invoked in the order of which they are declared. By default all handlers are run on a background queue.

## Handling JSON

Use the `responseJSON()` method to add a closure for handling the response as serialized JSON. The `json` value is provided as a result of calling `NSJSONSerialization.JSONObjectWithData()`.

```
brewClient
    .GET("/brewers")
    .responseJSON { json: AnyObject? in
        // process JSON
    }
    .responseError { error in
        print("I AM ERROR \(error)")
    }
    .resume()
```

## Updating UI

All response and error handlers that are registered with the `response()`, `responseJSON()`, and `responseError()` methods will run on a background queue. If you're updating UI with a response or error you'll need to make sure your updates happen on the main thread. ELWebService provides `updateUI()` and `updateErrorUI()` methods to enable you to register handlers that will be dispatched to the main queue.

```
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
    .updateUI { value in
        // this closure will be dispatched to the main queue via `updateUI()`

        if let brewers = value as? [Brewer] {
            // update some UI with brewer models
        }
    }
    .resume()
```


## Request Parameters

Parameterized data that is structured as a dictinoary type of `[String: AnyObject]` can be sent in the request with the `setParameters()` method. Parameters are percent encoded and appended as a query string of the request URL for GET and HEAD requests. The code below sends a request with the URL "/brewers?state=new%20york".

```
brewClient
    .GET("/brewers")
    .setParameters(["state" : "new york"])
```

For all other HTTP methods, parameters are sent as the request body with the default parameter encoding of `.Percent`.

```
brewClient
    .POST("/brewers")
    .setParameters(["name": "Trashboat Brewing"])
```

The code above produces a request with the body contents set to `"name=Trashboat%20Brewing"`. 

JSON can be sent by specifying the parameter encoding to be `.JSON`.

```
brewClient
    .POST("/brewers")
    .setParameters(["name": "Trashboat Brewing"], encoding: .JSON)
```

Now the parameters are JSON encoded in the body of the request.

### Parameter Encodings

The `setParameters()` method accepts an optional second parameter named `encoding` that allows you to specify how the request parameters will be encoded in the HTTP request. A value of `.JSON` will serialize the `parameters` data as JSON in the HTTP body and set the Content-Type HTTP header to "application/json".

A `.Percent` option specifies that the parameters will be encoded as a percent-encoded string. `.Percent` is the default configuration for encoding request parameters.

## Request Encoding

`ServiceTask` provides several methods that allow you to have further control over encoding a request. Below a custom HTTP header is set and a cache policy is specified.

```
brewClient
    .GET("/brewers")
    .setHeaderValue("2", forName: "beer-client-version")
    .setCachePolicy(.ReloadIgnoringLocalCacheData)
```

Rather than providing a request-encoding API as an object that is directly mutated and passed around (ex: `NSURLRequest`), ELWebService offers a fixed set of methods to centralize and encapsulate the intended mutations that are made to the request value. 


#### `setHeaderValue`

The `setHeaderValue()` method adds an HTTP header value and name to the HTTP request.

```
brewClient
    .GET("/brews",
    .setHeaderValue("foo", forName: "custom-header-name")
```

#### `setCachePolicy`

The `setCachePolicy()` method sets the`NSURLRequestCachePolicy` value to use in the resulting `NSURLRequest`. See the [`NSURLRequestCachePolicy`](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSURLRequest_Class/index.html#//apple_ref/c/tdef/NSURLRequestCachePolicy) section of the `NSURLRequest` documentation for more information.

```
brewClient
    .GET("/brews")
    .setCachePolicy(.ReloadIgnoringLocalCacheData)
```

#### `setBody`

The `setBody(data: NSData)` method sets the `NSData` value to use as the raw body of the HTTP request.

```
let bodyData: NSData = modelData()

brewClient
    .PUT("/brewers")
    .setBody(bodyData)
```


#### `setJSON`

The `setJSON(json: AnyObject)` method sets the JSON object that will be serialized as the body of the HTTP request.

```
client
    .POST("/numbers")
    .setJSON(["one", "two", "three"])
```


## ServiceTaskResult

`ServiceTaskResult` values can be used to control how values flow through the handler chain. This allows response handlers to run on a background thread and pass processed data to the next response handler in the chain.

Response handlers must return one of the following `ServiceTaskResult` values:

- Return `.Empty` to provide no processed value to the next handler. All subsequent handlers in the chain will continue to run.
- Return `.Value(Any)` with an associated value of `Any` type to provide a resulting value to the next handler in the chain. All subsequent handlers in the chain will continue to run.
- Return `.Failure(ErrorType)` with an associated value of `ErrorType` to prevent any subsequent response handlers from running. All registered error handlers will run instead.

The example below uses `ServiceTaskResult` to first filter out any responses that do not have the status code of 200. The first handler simply checks for the 200 status code and returns a `.Failure` result if the status is anything but 200. If the status check passes a result of `.Empty` is returned to allow the subsequent response handlers in the chain to continue running.

The second response handler in the example serializes the response a JSON and attempts to decode the JSON as an array of model values. If the decoding succeeds the handler uses the `.Value` result to pass the model values to handler registered by `updateUI()`. In the case of a failure a `.Failure` result is returned with a decoding error.

Finally the `updateUI()` handler will be run if all previous response handlers did not return a `.Failure` result. The update UI handler is passed the value that was returned from the last response handler in the chain via a `.Value` result. 

```
service
    .GET("/foo")
    .response { data, response in
        // filter reseponses that do not respond with status 200

        if let httpResponse = response as? NSHTTPURLResponse 
            where httpResponse.statusCode != 200 {
            return .Failure(ResponseError.ExpectedStatus200)
        }

        return .Empty
    }
    .responseJSON { json in
        // decode JSON as an array of models

        if let models: [Brewer] = JSONDecoder<Brewer>.decode(json)  {
            // return valid model data to updateUI handler
            return .Value(models)
        } else {
            // any value conforming to ErrorType
            return .Failure(JSONDecoderError.FailedToDecodeBrewer) 
        }
    }
    .updateUI { (value: Any) in
        // configure the UI with the model on the main thread

        if let models = value as? [Brewer] {
          view.configureWithBrewerModels(models)
        }
    }
    .updateErrorUI { error in
        // handle errors and update UI accordingly
    }
    .resume()
```

## Building an API Client

ELWebService makes it really easy to build a client for consuming a web API. By utilizing extensions, endpoint-specific request and response methods can be added to `WebService` and `ServiceTask`.

Ideally we should abstract the details of a request for a given web service endpoint in a high-level method that is more friendly for our API client consumers to use. We can extend `WebService` and add a method for querying the API's search endpoint.

```
extension WebService {

    public func searchWithName(name: String, state: String) -> ServiceTask {
        return GET("/brewers").setParameters(["name": name, state": state])
    }
}
```

Consumers of the API client can now ignore the request details and use the friendly high-level method to query for search results.

```
brewClient
    .searchWithName("Great Lakes", state: "New York")
    .response { data, response in
        // process response
    }
    .updateErrorUI { error in
        print("I AM ERROR: \(error)")
    }
    .resume()
```

This pattern is great for maintainability because the underlying search method implementation is so clean that it practically serves as documentation for the HTTP endpoint.

Along with request methods it would be nice to have response handler methods that are specific to processing the expected response from a web service call. Custom response handlers can be added by extending the `ServiceTask` class.

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

The code above adds a new method to `ServiceTask` that accepts a closure for calling back with a valid model object. A call to `responseJSON()` is returned in order to access the response data as a JSON object. A model layer attempts to serialize the JSON as an array of model objects and if the parsing succeeds the model data is returned as a `.Value` result to be passed to the update UI handler. Finally, the update UI handler calls the callback handler with the requested model data.

With the custom request and response methods in place the code for querying search results using our API client can be boiled down to:

```
brewClient
    .searchWithName("Great Lakes", state: "New York")
    .responseAsBrewers { brewers in
        // update UI with the valid model data
    }
    .updateErrorUI { error in
        print("I AM ERROR: \(error)")
    }
    .resume()
```

## Objective-C Interoperability

Most of ELWebService's Swift API bridges over to Objective-C but there are a few cases where special Objective-C APIs are needed to wrap constructs that only exist in Swift.

### Objective-C `ServiceTask` Request API

ELWebService provides a special Objective-C request API for setting request parameters and the type of parameter encoding. Since `Request.ParameterEncoding` is defined as a nested type in the `Request` struct it cannot be represented in Objective-C and therefore methods like `setParameters(parameters: [String: AnyObject], encoding: Request.ParameterEncoding)` cannot be called from Objective-C.

To work around this limitation a special `ServiceTask` request API is provided for setting request parameters and their coresponding type of encoding. The designated Objective-C methods are named with an `ObjC` suffix to indicate that they are designed to be called only from Objective-C.

```
extension ServiceTask {
    /**
     Set request parameter values and configure them to be JSON-encoded.
     
     This method is designed to only be called from Obj-C. Please use
     `setParameters(parameters: [String: AnyObject], encoding: Request.ParameterEncoding)`
     when calling from Swift.
     
     - parameter parameters: Request parameter values.
    */
    @objc public func setJSONEncodedParametersObjC(parameters: [String : AnyObject]) -> Self

    /**
     Set request parameter values and configure them to be Percent-encoded.
     
     This method is designed to be called from Obj-C only. Please use
     `setParameters(parameters: [String: AnyObject], encoding: Request.ParameterEncoding)`
     when calling from Swift.
     
     - parameter parameters: Request parameter values.
    */
    @objc public func setPercentEncodedParametersObjC(parameters: [String : AnyObject]) -> Self

    /**
     Configure the request parameters to be JSON-encoded.
    
     This method is designed to be called from Obj-C only. Please use
     `setParameterEncoding(encoding: .JSON)` when calling
     from Swift.
    */
    @objc public func setJSONParameterEncodingObjC() -> Self

    /**
     Configure the request parameters to be Percent-encoded.
     
     This method is designed to be called from Obj-C only. Please use
     `setParameterEncoding(encoding: .Percent)` when calling
     from Swift.
    */
    @objc public func setPercentParameterEncodingObjC() -> Self
}
```

### Objective-C `ServiceTask` Response API

Response handlers use `ServiceTaskResult`, an enum type with associated values, which means Objective-C is unable to define response handlers since enums with associated values cannot be represented in Objective-C.

To work around this limitation a special `ServiceTask` response handler API is provided. The designated Objective-C methods are named with an `ObjC` suffix to indicate that they are designed to be called only from Objective-C.

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


The designated Objective-C API allows you to add response handlers and return handler result values just like you would with the Swift API.

The syntax when using the Swift API looks like:

```
var client = WebService(baseURLString: "https://somehapi.herokuapp.com")
let task = service.GET("/brewers")

task.responseJSON { json in
      if let models: [Brewer] = JSONDecoder<Brewer>.decode(json)  {
          // pass encoded value via ServiceTaskResult
          return .Value(models)
      } else {
        // any value conforming to ErrorType
        return .Failure(JSONDecoderError.FailedToDecodeBrewer) 
      }
    }
    .updateUI { value in
        if let brewers = value as? [Brewer] {
            // update some UI with brewer models
        }
    }
    .resume()
```


In Objective-C the above Swift example translates into this:

```
WebService *service = [[WebService alloc] initWithBaseURLString:@"https://somehapi.herokuapp.com"];
ServiceTask *task = [service GET:@"/brewers"];

[task responseJSON:^HandlerResult *(id json) {
    NSArray *models = [JSONDecoder decodeBrewersFromJSON:json];

    if (models != nil) {
        // return result values with `ObjCHandlerResult` instead of `ServiceTaskResult
        return [ObjCHandlerResult resultWithValue:models];
        
    } else {
        NSError *error
        return [ObjCHandlerResult resultWithError:error];
    }
}];

[task updateUI:^(id value) {
    if ([value isKindOfClass:[NSArray class]]) {
         // update UI with brewer models
    }
}];

[task resume];
```

### ObjCHandlerResult

`ServiceTaskResult` cannot be represented in Objective-C because it is defined as an enumeration with associated values. To work around this the `ObjCHandlerResult` class is provided to enable Objective-C response handlers to return a value/empty/error result. The table below shows how `ServiceTaskResult` cases map to `ObjCHandlerResult` values.

Swift                  | Objective-C                                        | Result  
-----------------------|----------------------------------------------------| ------------------
`return .Empty`        | `return nil`                                       | No value
`return .Value(foo)`   | `return [ObjCHandlerResult resultWithValue:value]` | Valid value
`return .Failure(foo)` | `return [ObjCHandlerResult resultWithError:error]` | Error occured

## Session protocol

TODO: add docs about `Session` protocol.

## Mocking

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

### MockableDataTaskResult

`MockableDataTaskResult` is a type that returns the data to be mocked as the result of a session's data task. When implementing this type, you are defining the data that will be passed to your session's completion handler.

```
public protocol MockableDataTaskResult {
    func dataTaskResult(request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?)
}
```

ELWebService provides `MockableDataTaskResult` implementations for several types:

- `NSURLResponse`/`NSHTTPURLResponse`
- `NSError`
- `MockResponse`

`MockableDataTaskResult` can be used to extend your own types so that they can be used as mocked responses and added as stubs to a mock session.

```
struct MyMockedResult: MockableDataTaskResult {
    func dataTaskResult(request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?) {
        guard let url = request.urlRequestValue.URL else { return (nil, nil, nil) }
        
        let response = NSHTTPURLResponse(URL: url, MIMEType: nil, expectedContentLength: 12345, textEncodingName: nil)
        return (nil, response, nil)
    }
}
```

### MockResponse

`MockResponse` stores the meta and body data of a response. It is provided as a convenient alternative to stubbing `NSHTTPURLResponse` and `NSData` objects directly and allows you to define both response data and meta data within a single type. 

In the simplest form, `MockResponse` can be initialized with only a status code.

```
let noConentResponse = MockResponse(statusCode: 204)
```

`MockResponse` has an initializer for mocking JSON data as the response body. Below a response is mocked with a status code of 200 and `["foo": "bar"]` JSON data to serialize as the response body data. 

```
let response = MockResponse(statusCode: 200, json: ["foo": "bar"])
```

A initializer is provided for defining a raw `NSData` value as the response body data. The example below mocks a response with a raw `NSData` value as the response body along with a HTTP header named "Content-Length" whose value is is "12345".

```
let responseData: NSData = mockResponseData()
var response = MockResponse(statusCode: 200, data: responseData)
response.headers = ["Content-Length": "12345"]
```

### MockSession

`MockSession` is a class that implements the `Session` protocol and provides an API for adding mocked responses as stubs.

Create a mock session and inject it as the session of your web service.

```
let mockSession = MockSession()
let service = WebService(baseURLString: "https://somehapi.herokuapp.com")
service.session = mockSession
```

Types that conform to `MockableDataTaskResult` can be added as stubs of a mock session.

```
/// add a stub that matches any request
let response = MockResponse(statusCode: 200, json: ["foo": "bar"])
mockSession.addStub(response)
```

A matcher can be defined that will determine if the mocked response is used as a response stub for a given request.

```
/// use matcher tp return `true` for the requests that the stub should response to 
let response = MockResponse(statusCode: 200, json: ["foo": "bar"])

// add a stub that matches only requests with "/brews" in the URL path
mockSession.stub(response) { (matchingRequest: URLEncodableRequest) in

    if let path = matchingRequest.urlRequestValue.URL?.path {
        // use this stub if the path contains /brews
        return path.containsString("/brews")
    }

    // do not use this stub for this request
    return false
}
```

Errors can also be used as stubs. When providing an error stub the data task result returned to your session will contain the error as well as nil values for both the `NSData` and `NSURLResponse` values. This enables you to test your response handler in the event the request fails and the session returns an error.

```
session.addStub(ResponseError.FailedToSendRequest as NSError)
```


## More Information

For more information check out ELWebService's documentation in the [source files](https://github.com/Electrode-iOS/ELWebService/tree/master/Source). Feel free to open [issues](https://github.com/Electrode-iOS/ELWebService/issues) and of course [pull requests](https://github.com/Electrode-iOS/ELWebService/pulls) are always welcomed!
