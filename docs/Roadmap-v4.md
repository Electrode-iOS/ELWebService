# v4 Roadmap

[v4.0.0 milestone](https://github.com/Electrode-iOS/ELWebService/milestone/3)

# Goals

### More flexible and simplified request building API

- [Enable requests to be constructed independently from `ServiceTask`](https://github.com/Electrode-iOS/ELWebService/issues/45).
- [Expose request API as a struct with properties that can be mutated directly]().

### Reduce boilerplate needed for processing a response

- [Remove `ServiceTaskResult` API](https://github.com/Electrode-iOS/ELWebService/issues/33)
- [Enable response handlers to infer the type of handler result](https://github.com/Electrode-iOS/ELWebService/issues/36)

### Richer performance metrics API by utilizing `NSURLSessionTaskMetrics` API

- [Add metrics API that utilizes `NSURLSessionTaskMetrics`](https://github.com/Electrode-iOS/ELWebService/issues/51).

### Support for Swift 3.

- [Update APIs to follow Swift 3 naming guidelines](https://github.com/Electrode-iOS/ELWebService/issues/50)

# Breaking Changes

### Removing `ServiceTask` request API.

The following `ServiceTask` APIs will be removed as part of [#45](https://github.com/Electrode-iOS/ELWebService/issues/45).

```
extension ServiceTask {
    public func setParameters(parameters: [String : AnyObject], encoding: Request.ParameterEncoding? = default) -> Self
    public func setBody(data: NSData) -> Self
    public func setJSON(json: AnyObject) -> Self
    public func setHeaders(headers: [String : String]) -> Self
    public func setHeaderValue(value: String, forName name: String) -> Self
    public func setCachePolicy(cachePolicy: NSURLRequestCachePolicy) -> Self
    public func setParameterEncoding(encoding: Request.ParameterEncoding) -> Self
    public func setQueryParameters(parameters: [String : AnyObject]) -> Self
    public func setFormParameters(parameters: [String : AnyObject]) -> Self
}
```


### Removing `Request.ParameterEncoding`

`Request.ParameterEncoding` was deprecated in [v3.2.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v3.2.0) and will be removed in 4.0 in favor of using `queryParameters` and `formParamteres` API of the new `ServiceRequest` struct.

### Removing `ServiceTaskResult`

`ServiceTaskResult` will be removed in favor of enabling handlers to return a value, return `nil`, or throw an error to indicate the result of a handler.


# Additions

### New request API via `ServiceRequest` struct

```
public struct ServiceRequest : ServiceRequestProtocol, ParameterizedServiceRequest {
    /// Defines the supported HTTP methods.
    public enum Method : String {

        case get

        case head

        case post

        case put

        case delete
    }

    /// A group of static constants for referencing HTTP header field names.
    public enum Headers : String {

        case userAgent

        case contentType

        case contentLength

        case accept

        case cacheControl
    }

    /// A group of static constants for referencing supported HTTP
    /// `Content-Type` header values.
    public enum ContentType : String {

        case formEncoded

        case json
    }

    /// The HTTP method of the request.
    public let method: ServiceRequest.Method

    /// The URL string of the HTTP request.
    public let url: URL

    /// The body of the HTTP request.
    public var body: Data?

    /// The key/value pairs that will be encoded as the query in the URL.
    public var queryParameters: [String : Any]?

    /// The key/value pairs that are encoded as form data in the request body.
    public var formParameters: [String : Any]? { get set }

    /**
     The HTTP header fields of the request. Each key/value pair represents a 
     HTTP header field value using the key as the field name.
    */
    public var headers: [String : String]

    /// The HTTP `Content-Type` header field value of the request.
    public var contentType: String? { get set }

    /// The HTTP `User-Agent` header field value of the request.
    public var userAgent: String? { get set }

    /**
     Intialize a request value.
     
     - parameter method: The HTTP request method.
     - parameter url: The URL string of the HTTP request.
    */
    public init(_ method: ServiceRequest.Method, url: URL)

    public init?(_ method: ServiceRequest.Method, urlString: String)
}
```

Previously, `ServiceTask` conflated request building with response processing. Requests are now constructed independently from `ServiceTask`.

```
extension BrewClientAPI {
    /// Create the request for the endpoint
    func insertRequest(brew: Brew) -> ServiceRequest {
        var request = service.request(.post, "/brews")
        request.formParameters = brew.webServiceParameters
        return request
    }
    
    /// Create the ServiceTask for the endpoint
    func insert(brew: Brew) -> ServiceTask {
        return service.task(request: insertRequest(brew: brew))
    }
}
```

The `ServiceTask` API continues to support chaining for handling responses.

```
brewClient
    .insert(brew: brew)
    .updateUI { [weak self] value in
        self?.dismiss(animated: true, completion: nil)
    }
    .updateErrorUI { error in
        print("I AM ERROR = \(error)")
    }
    .resume()
```

### New performance metrics API

TODO: add details on new metrics API




