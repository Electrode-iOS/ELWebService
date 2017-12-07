# ELWebService Programming Guide

- [About ELWebService](#about-elwebservice)
- [How ELWebService Works with URLSession](#how-elwebservice-works-with-urlsession)
- [Quick Start](#quickstart)
    - [Sending Requests](#sending-requests)
    - [Handling Responses](handling-responses)
- [Requests](#requests)
    - [Sending JSON](#sending-json)
    - [Query Parameters](#query-parameters)
    - [Form Parameters](#form-parameters)
    - [Request Headers](#request-headers)
    - [Request Body](#request-body)
- [Responses](#responses)
    - [Handling JSON](#handling-json)
    - [Composing Response Handlers](#composing-response-handlers)
    - [Updating UI](#updating-ui)
    - [ServiceTaskResult](#servicetaskresult)
- [Building an API Client](#building-an-api-client)
- [Objective-C Interoperability](#objective-c-interoperability)
- [Mocking](#mocking)
- [Logging](#logging)

## About ELWebService

[ELWebService](https://github.com/Electrode-iOS/ELWebService) is a lightweight HTTP networking framework written in Swift. ELWebService simplifies interaction with HTTP web services by providing an API for encoding a `URLRequest` and processing the resulting `URLResponse` and `Data` response objects.  Designed to integrate cleanly with `URLSession`, ELWebService avoids using the session delegate events and does not mutate the session's configuration.

## How ELWebService Works with URLSession

ELWebService uses the shared session returned from `URLSession.shared` to create data tasks but can be customized to work with any session. By conforming to `Session`, your code has complete control over the `URLSession` instance that creates `URLSessionDataTask` objects for ELWebService to work with.

```
class CustomSession: Session {
    public func dataTask(request: URLRequestEncodable, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> DataTask {        
        return dataTask(with: request.urlRequestValue, completionHandler: completion) as DataTask
    }
}
```

Configure a service to use a custom session.

```
var service = WebService(baseURLString: "http://myapi")
service.session = CustomSession()
```

To simplify usage further, ELWebService extends `URLSession` with an implementation of the `Session` protocol. 

```
service.session = URLSession(configuration: URLSessionConfiguration())
```

## Quick Start

Initialize a `WebService` instance with a base URL.

```
let service = WebService(baseURLString: "http://brewhapi.herokuapp.com/")
```

### Sending Requests

Create a request by calling the `request(_ method:path:)` method with the HTTP method and a relative path. The service's base URL is used to construct an absolute URL that is relative to the path.

```
let request: Request = service.request(.GET, path: "/brewers")
```

To send a request, create a session task and call `resume()`

```
let task: SessionTask = service.sessionTask(request: request)
task.resume()
```

The code above sends a GET request with the URL "http://brewhapi.herokuapp.com/brewers".


### Handling Responses

A successful response is handled asynchronously by defining a closure to process the response and registering it as a response handler using the `response()` method.

```
let request: Request = service.request(.GET, path: "/brewers")

service
    .sessionTask(request: request)
    .response { data, response in
        // process response
    }
    .resume()
```

The response closure will only be called if the request does not result in an error. To handle the event of a failure provide a closure for error handling by calling the `responseError()` method.

```
let request: Request = service.request(.GET, path: "/brewers")

service
    .sessionTask(request: request)
    .response { data, response in
        // process response
    }
    .responseError { error in
        print("I AM ERROR \(error)")
    }
    .resume()
```

The `sessionTask(request:)` method returns a `SessionTask` object that represents the lifetime of a `URLSessionDataTask`. The handler methods return their `self` instance which enables you to chain handlers resulting in concise and expressive code.

After the response is received handlers are invoked in the order of which they are registered. All response and error handlers that are registered with the `response()`, `responseJSON()`, and `responseError()` are run on a background queue.


## Requests

### Sending JSON

Call the `serialize(json:)` method to serialize a JSON object as the body data of the request. The Content-Type header will be set to `"application/json"` and an error may be thrown if the JSON serialization fails.

```
let request: Request = service.request(.POST, path: "/brewers")
try request.serialize(json: ["name": "Trashboat Brewing"])
```

### Query Parameters

Query parameters are percent-encoded and appended as a query string of the request URL. The code below sends a request with the URL "/brewers?state=new%20york".

```
var request = service.request(.GET, path: "/brewers")
request.queryParameters = ["state" : "new york"]
```

#### Custom Encoding

Custom encoding behavior can be defined for query parameters. Provide a `QueryParameterEncoder` closure that returns an encoded URL.

```
var request = service.request(.GET, path: "/brewers")
request.queryParameterEncoder = { (url, parameters) -> URL? in
    // manually encode query parameters
    var path = ""
    
    for (key, value) in parameters {
        path += "\(key)/\(value)"
    }
    
    // return the encoded URL
    let encodedURL = url?.appendingPathComponent(path)
    return encodedURL
}
request.queryParameters = ["brew" : "12345"]
```

To reuse custom encoding behavior, define a `QueryParameterEncoder` constant.

```
// Define a custom encoding
let customEncoder: QueryParameterEncoder = { (url, parameters) -> URL? in
    var path = ""
    
    for (key, value) in parameters {
        path += "\(key)/\(value)"
    }
    
    let encodedURL = url?.appendingPathComponent(path)
    return encodedURL
}

// Use custom encoding
var request = service.request(.GET, path: "/brewers")
request.queryParameterEncoder = customEncoder
request.queryParameters = ["brew" : "12345"]
```

### Form Parameters

Form parameters are sent as percent-encoded data in the request body. Setting form parameters will automatically set the Content-Type header to `"application/x-www-form-urlencoded"`.

```
var request = service.request(.POST, path: "/brewers")
request.formParameters = ["name": "Trashboat Brewing"]
```

### Request Headers

```
request.headers["custom-header-name"] = "foo"
```

### Request Body

Set the `Data` value to use as the body of the HTTP request.

```
request.body: Data = modelData()
```

## Responses

### Handling JSON

Use the `responseJSON()` method to add a closure for handling the response as serialized JSON. The `json` value is provided as a result of calling `NSJSONSerialization.JSONObjectWithData()`.

```
service
    .sessionTask(request: request)
    .responseJSON { json: Any, response: URLResponse? in
        // process JSON
    }
    .responseError { error in
        print("I AM ERROR \(error)")
    }
    .resume()
```

## Composing Response Handlers

At times, it can be useful to process the response using multiple handlers. Additional processing handlers are added using the `transform()` method.

```
service
    .sessionTask(request: request)
    .response { data, response in
        let intermediateValue: (Int, Int)

        // process response to create intermediate value

        return .Value(intermediateValue)
    }
    .transform { _intermediateValue in
        let intermediateValue = _intermediateValue as! (Int, Int)
        let finalValue: Int

        // process intermediate value to create final value

        return .Value(finalValue)
    }
    .resume()
```

Processing handlers are only called when there is a value to process, not when there is an error. If an earlier handler returns a `.Failure` result, then the handlers that follow are not invoked.

```
let request = service.request(.GET, path: "/brewers")

service
    .sessionTask(request: request)
    .response { data, response in
        return .Failure(Error.Nope)
    }
    .transform { value in
        // closure is **not** called
    }
    .resume()
```

Closures that _are_ called when there is an error can be added using the `recover()` method.

A recovery handler can return a value (`.Empty` or `.Value`) to indicate that it succeeded in recovering. Or, it can return an error (`.Failure`) to indicate that it could not recover.

```
service
    .sessionTask(request: request)
    .response { data, response in
        return .Failure(MyError.Nope)
    }
    .recover { error in
        if recoverGracefully(error) {
            // recovery succeeds:
            return .Value("It's all good")
        }

        // recovery fails:
        return .Failure(error)
    }
    .transform { value in
        // closure **is** called _if_ recovery succeeds
    }
    .resume()
```

Any number of processing closures can be added. Closures are called in the order that they are added, with the result of one closure becoming the input to the next. Control switches between transform and recovery closures as values and errors are returned.

## Updating UI

All response and error handlers that are registered with the `response()`, `responseJSON()`, `responseError()`, `transform()` and `recover()` methods will run on a background queue. If you're updating UI with a response or error you'll need to make sure your updates happen on the main thread. ELWebService provides `updateUI()` and `updateErrorUI()` methods for registering handlers that will be dispatched to the main queue.

```
service
    .sessionTask(request: request)
    .responseJSON { json, response in
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

### ServiceTaskResult

`ServiceTaskResult` values can be used to control how values flow through the handler chain. This allows response handlers to run on a background queue and pass processed data to the next response handler in the chain.

Response handlers must return one of the following `ServiceTaskResult` values:

- Return `.empty` to provide no processed value to the next handler. All subsequent handlers in the chain will continue to run.
- Return `.value(Any)` with an associated value of `Any` type to provide a resulting value to the next handler in the chain. All subsequent handlers in the chain will continue to run.
- Return `.failure(Error)` with an associated value of `Error` to prevent any subsequent response handlers from running. All registered error handlers will run instead.

The example below uses `ServiceTaskResult` to first filter out any responses that do not have the status code of 200. The first handler simply checks for the 200 status code and returns a `.failure` result if the status is anything but 200. If the status check passes a result of `.empty` is returned to allow the subsequent response handlers in the chain to continue running.

The second response handler in the example serializes the response a JSON and attempts to decode the JSON as an array of model values. If the decoding succeeds the handler uses the `.value` result to pass the model values to handler registered by `updateUI()`. In the case of a failure a `.failure` result is returned with a decoding error.

Finally the `updateUI()` handler will be run if all previous response handlers did not return a `.failure` result. The update UI handler is passed the value that was returned from the last response handler in the chain via a `.value` result.

```
service
    .sessionTask(request: request)
    .response { data, response in
        // filter responses that do not have status 200

        if let httpResponse = response as? NSHTTPURLResponse
            where httpResponse.statusCode != 200 {
            return .Failure(ResponseError.ExpectedStatus200)
        }

        return .empty
    }
    .responseJSON { json, response in
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

Protocols are great for defining the interface of an API client.

```
/// Describes the brew client API
protocol BrewClientAPI {
    var webService: WebService { get }
    
    func fetchAllBrewers() -> ServiceTask
    func insertBrew(brew: Brew) -> ServiceTask
}
```

Request methods can be implemented in a protocol extension.

```
/// Implements the web services for the HTTP client methods
extension BrewClientAPI {    
    func fetchAllBrewers() -> ServiceTask {
        return webService.GET("/brews")
    }
    
    func insertBrew(brew: Brew) -> ServiceTask {
        return webService.POST("/brews").setParameters(brew.webServiceParameters)
    }
}
```

Define a concrete class for the API client that adopts the API client protocol.

```
/// Brew API client class  
final class BrewClient: BrewClientAPI {
    static let baseURL = "http://brewhapi.herokuapp.com/"
    let webService = WebService(baseURLString: baseURL)
}
```

Use the API client to send a request.

```
let brewClient = BrewClient()

brewClient
    .fetchAllBrewers()
    .response { data, response in
        // process response
    }
    .updateErrorUI { error in
        
    }
    .resume()
```

Define response handlers by extending the `ServiceTask` class.

```
extension ServiceTask {
    func responseAsBrewers(handler: ([Brewer]) -> Void) -> Self {
        return
            responseJSON { json, response in
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

The request and response methods can be chained together resulting in concise syntax for requesting data and serializing the response as a model object:

```
brewClient
    .fetchAllBrewers()
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

ELWebService provides a special Objective-C request API for setting request parameters and the type of parameter encoding. Since `Request.ParameterEncoding` is defined as a nested type in the `Request` struct it cannot be represented in Objective-C and therefore methods like `setParameters(parameters: [String: Any], encoding: Request.ParameterEncoding)` cannot be called from Objective-C.

To work around this limitation a special `ServiceTask` request API is provided for setting request parameters and their coresponding type of encoding. The designated Objective-C methods are named with an `ObjC` suffix to indicate that they are designed to be called only from Objective-C.

```
extension ServiceTask {
    /**
     Set request parameter values and configure them to be JSON-encoded.

     This method is designed to only be called from Obj-C. Please use
     `setParameters(parameters: [String: Any], encoding: Request.ParameterEncoding)`
     when calling from Swift.

     - parameter parameters: Request parameter values.
    */
    @objc public func setJSONEncodedParametersObjC(parameters: [String : Any]) -> Self

    /**
     Set request parameter values and configure them to be Percent-encoded.

     This method is designed to be called from Obj-C only. Please use
     `setParameters(parameters: [String: Any], encoding: Request.ParameterEncoding)`
     when calling from Swift.

     - parameter parameters: Request parameter values.
    */
    @objc public func setPercentEncodedParametersObjC(parameters: [String : Any]) -> Self

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
    internal typealias ObjCResponseHandler = (Data?, URLResponse?) -> ObjCHandlerResult?

    @objc public func responseObjC(handler: (Data?, URLResponse?) -> ObjCHandlerResult?) -> Self

    @objc public func responseJSONObjC(handler: (Any, URLResponse?) -> ObjCHandlerResult?) -> Self

    @objc public func responseErrorObjC(handler: (Error) -> Void) -> Self

    @objc public func updateUIObjC(handler: (Any?) -> Void) -> Self

    @objc public func updateErrorUIObjC(handler: (Error) -> Void) -> Self
}
```


The designated Objective-C API allows you to add response handlers and return handler result values just like you would with the Swift API.

The syntax when using the Swift API looks like:

```
var client = WebService(baseURLString: "https://somehapi.herokuapp.com")
let task = service.GET("/brewers")

task.responseJSON { json, response in
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

[task responseJSON:^HandlerResult *(id json, NSURLResponse *response) {
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

// send a request that will be fulfilled by the mocked response
service
    .fetchAllBrewers("12345")
    .responseAsBrewers { brews in
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
    func dataTaskResult(request: URLRequestEncodable) -> (Data?, URLResponse?, Error?)
}
```

ELWebService provides `MockableDataTaskResult` implementations for several types:

- `URLResponse`/`HTTPURLResponse`
- `NSError`
- `MockResponse`

`MockableDataTaskResult` can be used to extend your own types so that they can be used as mocked responses and added as stubs to a mock session.

```
struct MyMockedResult: MockableDataTaskResult {
    func dataTaskResult(request: URLRequestEncodable) -> (Data?, URLResponse?, Error?) {
        guard let url = request.urlRequestValue.URL else { return (nil, nil, nil) }
        
        let response = HTTPURLResponse(URL: url, MIMEType: nil, expectedContentLength: 12345, textEncodingName: nil)
        return (nil, response, nil)
    }
}
```

### MockResponse

`MockResponse` stores the meta and body data of a response. It is provided as a convenient alternative to stubbing `HTTPURLResponse` and `Data` objects directly and allows you to define both response data and meta data within a single type. 

In the simplest form, `MockResponse` can be initialized with only a status code.

```
let noConentResponse = MockResponse(statusCode: 204)
```

`MockResponse` has an initializer for mocking JSON data as the response body. Below a response is mocked with a status code of 200 and `["foo": "bar"]` JSON data to serialize as the response body data. 

```
let response = MockResponse(statusCode: 200, json: ["foo": "bar"])
```

A initializer is provided for defining a raw `Data` value as the response body data. The example below mocks a response with a raw `Data` value as the response body along with a HTTP header named "Content-Length" whose value is is "12345".

```
let responseData: Data = mockResponseData()
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

Errors can also be used as stubs. When providing an error stub the data task result returned to your session will contain the error as well as nil values for both the `Data` and `URLResponse` values. This enables you to test your response handler in the event the request fails and the session returns an error.

```
session.addStub(ResponseError.FailedToSendRequest as NSError)
```

## Logging

There is no built-in support for logging network requests or responses. However, it is fairly easy to implement your own logger by leveraging `WebService`'s passthrough delegate support.

There are two ways to "inject" a delegate:

1. Provide a delegate to the web service as an initializer parameter:
  ```swift
  class RequestLogger: ServicePassthroughDelegate {
      // delegate implementation…
  }

  let logger = RequestLogger()

  let service = WebService(baseURLString: baseURLString, passthroughDelegate: logger)
  ```
  _Note: You **must** keep a strong reference to the delegate instance; the web service only maintains a weak reference._
2. Extend `WebService` to act as a delegate data source:
  ```swift
  class RequestLogger: ServicePassthroughDelegate {
      // delegate implementation…
  }

  let logger = RequestLogger()

  extension WebService: ServicePassthroughDataSource {
      public var servicePassthroughDelegate: ServicePassthroughDelegate { return logger }
  }
  ```
  _Note: `WebService` will automatically use the `ServicePassthroughDataSource` protocol API if it has been extended to conform it._

A delegate implementation that logs requests and responses might look like:

```swift
class RequestLogger: ServicePassthroughDelegate {
    func requestSent(request: URLRequest) {
        print("Sending request: \(request)")
    }

    func responseReceived(response: URLResponse?, data: Data?, request: URLRequest?, error: Error?) {
        if let response = response {
            print("Received response: \(response)")

            if let data = data, let body = NSString(data: data, encoding: NSUTF8StringEncoding) {
                print("... body: \(body)")
            }
        } else if let error = error {
            print("Received error: \(error)")
        }
    }

    // other protocol methods…
}
```

## More Information

For more information check out ELWebService's documentation in the [source files](https://github.com/Electrode-iOS/ELWebService/tree/master/Source). Feel free to open [issues](https://github.com/Electrode-iOS/ELWebService/issues) and of course [pull requests](https://github.com/Electrode-iOS/ELWebService/pulls) are always welcomed!
