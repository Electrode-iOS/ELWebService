# Swallow Programming Guide

## About Swallow

[Swallow](https://github.com/TheHolyGrail/Swallow) is a lightweight HTTP networking framework written in Swift. Swallow simplifies interaction with HTTP web services by providing a concise API for encoding a `NSURLRequest` object and processing the resulting `NSURLResponse`. 

Unlike many other iOS networking libraries, Swallow is not a wrapper around `NSURLSession` or `NSURLConnection`. Instead Swallow is designed to be unobtrusive by acting as a convenience for working with request and response objects while leaving the crucial implementation details of the various session delegate methods up to the developer.

Apple has done a great job of providing the fundamentals that you would expect from a networking API via `NSURLSession`. It is a modern and flexible API that leaves little need for bulky abstractions. Although `NSURLRequest` and `NSURLResponse` are simple to use they offer little in terms of utilizing the expressiveness and safety you get with Swift's syntax.

Swallow was built to offer simple but powerful constructs for enabling your code to easily take advantage of some of the modern features in Swift.

## How Swallow Works with NSURLSession

By default Swallow uses the shared session returned from `NSURLSession.sharedSession()` to create data tasks but can be customized to work with any session instance with a single protocol method. This gives you the freedom to provide your own `NSURLSession` implementation while giving you a lightweight API for dispatching and handling `NSURLSessionDataTask` objects.

By conforming to `SessionDataTaskDataSource`, your code has complete control over the `NSURLSession` configuration and simply provides a `NSURLSessionDataTask` for Swallow to work with.

```
struct MyDataTaskDataSource: SessionDataTaskDataSource {
    func dataTaskWithRequest(request: NSURLRequest, 
                          completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
        return NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: completion);
    }
}
```
Configure Swallow to use your data task source with a single line of code.

```
var client = WebService(baseURLString: "http://myapi")
client.dataTaskSource = MyDataTaskDataSource() // use custom `NSURLSession` instance
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
```

The code above sends a GET request with the URL "http://brewhapi.herokuapp.com/brewers". Along with GET, `WebService` also offers methods for POST, DELETE, and other common HTTP verbs.

Our code is already more expressive than it would be with `NSURLRequest` because we're calling a rigid method to specify that we want to make a `GET` request instead of simply setting a string value. An enum could have solved the stringly-typed problem but I would argue that the use of a method here is cleaner code.

## Handling Responses

A successful response is handled asynchronously by defining a closure to process the response and registering it as a response handler using the `response()` method.

```
brewClient
    .GET("/brewers")
    .response { data, response in
        // process response
    }
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
```

Request methods like `GET()` return a `ServiceTask` object that represents the lifetime of a given `NSURLSessionDataTask`. The handler methods return their `self` instance which enables you to chain handlers resulting in concise and expressive code.

After the response is received handlers are invoked in the order of which they are declared. By default all handlers are run on the main thread but you can also specify a dispatch queue for running elsewhere.

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
```

## Request Parameters

`GET` and the various other request methods have an optional parameter named `parameters` for sending parameterized data along with the request. Parameters are percent encoded and appended as a query string of the request URL for GET and HEAD requests. The code below sends a request with the URL "/brewers?state=new%20york".

```
brewClient
    .GET("/brewers", parameters: ["state" : "new york"])
```

For all other HTTP methods, parameters are sent as the request body and are encoded based on the `ParameterEncoding(Request.ParameterEncoding)` option. The default encoding is ParameterEncoding.Percent.

```
brewClient
    .POST("/brewers", parameters: ["name" : "Trashboat Brewing"])
```

The code     above produces a request with the body contents set to `"name=Trashboat%20Brewing"`. To send JSON instead simply pass `ParameterEncoding(.JSON)` as a request option.

```
brewClient
    .POST("/brewers",
        parameters: ["name" : "Trashboat Brewing"],
        options: [.ParameterEncoding(.JSON)])
```

Now the parameters are JSON encoded in the body of the request.


## Request Options

Options give you further control over encoding a request. Options can be thought of as a collection of rules that describe how to encode a request value. Below, options are used to set a custom header value as well as to specify that the request parameters are to be JSON encoded.

```
brewClient
    .GET("/brewers",
        parameters: nil,
        options: [.ParameterEncoding(.JSON),
                  .Header("beer-client", "iOS")])
    .response { data, response in
        // process response
    }
    .responseError { error in
        print("I AM ERROR \(error)")
    }
```

Rather than providing a request-encoding API as an object that is directly mutated and passed arround, Swallow offers a fixed set of rules to centralize and encapsulate the intended mutations that are made to the request value. 

Requests values are no longer being mutated externally, they are encoded by definition of a set of rules.

#### `.ParameterEncoding`

The `.ParameterEncoding` option is used to specify how the request parameters will be encoded in the HTTP request. A value of `.JSON` will serialize the `parameters` data as JSON in the HTTP body and set the Content-Type HTTP header to "application/json". 

A `.Percent` option specifies that the parameters will be encoded as a percent-encoded string. `.Percent` is the default configuration for encoding request parameters.

#### `.Header`

The `.Header` option declares an HTTP header to set in the request.

```
brewClient
    .GET("/brews",
        parameters: nil,
        options: [
            // declare an HTTP header of "Custom-Header: foo"
            .Header("Custom-Header", "foo")
        ])
```

#### `.CachePolicy`

The `.CachePolicy` option declares the`NSURLRequestCachePolicy` value to use in the resulting `NSURLRequest`. See the [`NSURLRequestCachePolicy`](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSURLRequest_Class/index.html#//apple_ref/c/tdef/NSURLRequestCachePolicy) section of the `NSURLRequest` documentation for more information.

```
brewClient
    .GET("/brews",
        parameters: nil,
        options: [
            .CachePolicy(.ReloadIgnoringLocalCacheData)
        ])
```

#### `.Body`

The `.Body` option declares the `NSData` value to use as the raw body of the HTTP request.

```
let bodyData: NSData = modelData()

brewClient
    .PUT("/brewers",
        parameters: nil,
        options: [
            // use bodyData as the HTTP request body
            .Body(bodyData)
        ])
```


### `.BodyJSON`

The `.BodyJSON` option declares the JSON object that will be serialized as the body of the HTTP request.

```
client
    .POST("/numbers",
        parameters: nil,
        options: [
            // declare an HTTP header of "Content-Type: application/json"
            .Header(Request.Headers.contentType, Request.ContentType.json),

            // serialize an array of strings as JSON and set as the HTTP body
            .BodyJSON(["one", "two", "three"])
        ])
```


## Building an API Client

Swallow makes it really easy to build a client for consuming a web API. By utilizing extensions, endpoint-specific request and response methods can be added to `WebService` and `ServiceTask`.

Ideally we should abstract the details of a request for a given web service endpoint in a high-level method that is more friendly for our API client consumers to use. We can extend `WebService` and add a method for querying the API's search endpoint.

```
extension WebService {

    public func searchWithName(name: String, state: String) -> ServiceTask {
        return GET("/brewers", parameters: ["name": name, state": state])
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
    .responseError { error in
        print("I AM ERROR \(error)")
    }
```

This pattern is great for maintainability because the underlying search method implementation is so clean that it practically serves as documentation for the HTTP endpoint.

Along with request methods it would be nice to have response handler methods that are specific to processing the expected response from a web service call. Custom response handlers can be added by extending the `ServiceTask` class.

```
extension ServiceTask {
    
    func responseAsBrewers(handler: ([Brewers]) -> Void) -> Self {
        return responseJSON { json in
            if let brewers = Model<Brewer>.modelsFromJSON(json) {
                handler(brewers)
            } else {
                // throw any value that conforms to Swift's ErrorType
                self.throwError(.ModelSerializationFailure)
            }
        }
    }
}
```
The code above adds a new method to `ServiceTask` that accepts a closure for calling back with a valid model object. A call to `responseJSON()` is returned in order to access the response data as a JSON payload. A model layer attempts to serialize the JSON as an array of model objects and if the parsing succeeds the callback is called with the valid model data. In the event the model fails to serialize as expected an `ErrorType` value can be "thrown" to short circuit response handlers and can be handled in the `responseError()` callback. (Note: This is different than Swift's native `throw` because the handlers execute asynchronously).

With the custom request and response methods in place the code for querying search results using our API client can be boiled down to:

```
brewClient
    .searchWithName("Great Lakes", state: "New York")
    .responseAsBrewers { brewers in
        // update UI with the valid model data
    }
    .responseError { error in
        print("I AM ERROR: \(error)")
    }
```



## More Information

For more information check out Swallow's [Readme](https://github.com/TheHolyGrail/Swallow#swallow) as well as the documentation in the [source files](https://github.com/TheHolyGrail/Swallow/tree/master/Source). Feel free to open [issues](https://github.com/TheHolyGrail/Swallow/issues) and of course [pull requests](https://github.com/TheHolyGrail/Swallow/pulls) are always welcomed!

