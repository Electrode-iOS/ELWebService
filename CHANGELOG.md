# [3.2.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v3.2.0)

### Deprecations

- Deprecated `ServiceTaskResult.Failure`. [Use `throw` to propagate errors instead](#throwing-errors).
- Deprecated `setParameters(parameters:encoding:)` and `setParameterEncoding(encoding:)` methods of `ServiceTask`. [Use `setQueryParameters(parameters:)` and `setFormParameters(parameters:)` instead](#request-parameters).

### New Features
 
- Added `setQueryParameters(parameters:)` method to `ServiceTask` for setting key/value pairs in the URL query string. [Fixes #40](https://github.com/Electrode-iOS/ELWebService/issues/40).
- Added `setFormParameters(parameters:)` method to `ServiceTask` for setting key/value pairs in the request body as form encoded data. [Fixes #40](https://github.com/Electrode-iOS/ELWebService/issues/40).
- Response handler closures can throw errors to propagate errors instead of return `.Failure(error)`.

### Fixes

- Make `updateUI()` and `updateErrorUI` handlers block handler chain execution. [Fixes #38](https://github.com/Electrode-iOS/ELWebService/issues/38).

##### Throwing Errors

Previously, response handlers returned  a`.Failure(error)` value to indiciate that a handler failed.

```
.responseJSON { json, response in
    if let models: [Brewer] = JSONDecoder<Brewer>.decode(json)  {
        return .Value(models)
    } else {
      // any value conforming to ErrorType
      return .Failure(JSONDecoderError.FailedToDecodeBrewer)
    }
}
```

Response handlers should now use Swift's `throw` keyword to propagate errors.

```
.responseJSON { json, response in
    guard let models: [Brewer] = JSONDecoder<Brewer>.decode(json)  {
        throw JSONDecoderError.FailedToDecodeBrewer
    } 

    return .Value(models)
}
```

##### Request Parameters

GET, DELETE, or HEAD request that use `setParameters(parameters:encoding:)` to encode parameter data in the URL query string should move to using `setQueryParameters(parameters:)` to set parameter data instead.

POST and PUT requests that use `setParameters(parameters:encoding:)` to send form data, _not JSON_, in the request body should instead use `setFormParameters(parameters:)`.


# [3.1.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v3.1.0)

- Force-downcast `updateUIObjC` handler's value to avoid silent failure. Fixes [#34](https://github.com/Electrode-iOS/ELWebService/issues/34).
- Introduced `transform()` and `recover()` response handler API. See the [Composing Response Handlers](https://github.com/Electrode-iOS/ELWebService/blob/master/docs/Programming-Guide.md#composing-response-handlers) section of programming guide for more info on how to use the new API.

# [3.0.2](https://github.com/Electrode-iOS/ELWebService/releases/tag/v3.0.2)

- Removed the `SessionDataTaskDataSource` deprecation warnings that were declared with the `@available` attribute. The `@available` attribute was causing warnings to surface in Xcode projects that contained the ELWebService Xcode project as a subproject even when the deprecated API was not being called from the parent project. Due to Walmart's internal workflow being dependant on including ELWebService as a subproject, a decision was made to remove the `@avaiable` deprecation warnings in a patch release.

# [3.0.1](https://github.com/Electrode-iOS/ELWebService/releases/tag/v3.0.1)

- Resolved Swift 3 deprecation warnings.

# [3.0.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v3.0.0)

- Updated the Objective-C request API to return `self` instance for API consistency
- Simplified query parameter encoding with `NSURLQueryItem` Previously, query parameters were encoded manually by piecing together string values with `stringByAddingPercentEncodingWithAllowedCharacters`. This change allows `NSURLQueryItem` to handle the percent encoding and uses `NSURLComponents` to produce the encoded query string.
- Updated ELWebService unit tests to use mock sessions instead of sending requests over the network.
- Added more unit tests, **increasing code coverage to 99%**
- Added unit tests to example project to demonstrate session and response mocking

### Breaking Changes

- Added `NSURLResponse` parameter to `JSONHandler` closure to enable JSON response handler to access response meta data. ([24d7d5a](https://github.com/Electrode-iOS/ELWebService/commit/24d7d5a2dc4832a6555547f03f487cb65a3ac450))
- Deployment target turned down to 8.0. ([c4b9b6e](https://github.com/Electrode-iOS/ELWebService/commit/c4b9b6e7f420538d4dd42653df62c75178907407))

### Deprecations

- Deprecated `SessionDataTaskDataSource` protocol in favor of `Session`.
- Deprecated WebService's `dataTaskSource` property. Use `Session` protocol and set the `session` property instead.
- Deprecated WebService's `dataTaskWithRequest(request:completionHandler)` method. Use `dataTask(request:completion:)` instead.

### New Features

- Added `Session` and `DataTask` protocols to decouple `NSURLSession` and `NSURLSessionDataTask` from `ServiceTask` and `WebService`. These new protocols enable code to mock the session and data task objects so that unit tests can be performed without sending requests over the network. The framework provides implementations that make `NSURLSession` conform to `Session` and `NSURLSessionDataTask` conform to `DataTask`
- Added Mocking API. See the [mocking API documentation](https://github.com/Electrode-iOS/ELWebService/blob/58293ce86f268adcf2cf2a68b64a72caab7fb76a/docs/Programming-Guide.md#mocking) for usage information.
  - Added `MockSession` and `MockDataTask` protocols as a mocking interface for `Session` and `DataTask` types.
  - Added `MockResponse` for easier response mocking

# [2.5.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v2.5.0)

- Changed deployment target to 8.0
- Replaced ServiceTask's GCD queue with NSOperationQueue so queued blocks can be cancelled in deinit
- Added `ServicePassthroughDelegate` protocol for handling raw request and response events

# [2.4.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v2.4.0)

- Added `dataTaskWithRequest` method [low-level WebService API](https://github.com/Electrode-iOS/ELWebService/blob/a52b8e8e852353c7e3a2979f68add7f662fb3593/Source/Core/WebService.swift#L148-L150) for creating `NSURLSessionDataTask` from `NSURLRequest` objects

# [2.3.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v2.3.0)

- Added better support for Objective-C interoperability by introducing a special request API for Obj-C. See [Objective-C ServiceTask Request API](https://github.com/Electrode-iOS/ELWebService/blob/master/docs/Programming-Guide.md#objective-c-servicetask-request-api) section in the programming guide for more information.

# [2.2.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v2.2.0)

- Added support for Objective-C interoperability. Fixes [#21](https://github.com/Electrode-iOS/ELWebService/issues/21). For information on usage from Obj-C see the [Objective-C Interoperability section](/docs/Programming-Guide.md#objective-c-interoperability) in the [ELWebService Programming Guide](/docs/Programming-Guide.md). Several changes were made to support Obj-C interop:
  - Made `WebService` inherit from NSObject
  - Made `ServiceTask` inherit from NSObject
  - Added `ObjCHandlerResult` class to encapsulate result data from Obj-C handlers
  - Added `ObjCResponseHandler` closure type to support adding response handlers that work with Obj-C
  - Extended `ServiceTask` to add specially-named response handler methods to support adding handlers from Obj-C
  - Added a `ServiceTaskResult` initializer so that a service task result value can be initialized from an `ObjCHandlerResult` value

# [2.1.2](https://github.com/Electrode-iOS/ELWebService/releases/tag/v2.1.2)

- Enabled testability for release builds. Fixes [#19](https://github.com/Electrode-iOS/ELWebService/issues/19).

# [2.1.1](https://github.com/Electrode-iOS/ELWebService/releases/tag/v2.1.1)

- Encode request parameters only when parameters are non empty. Fixes an issue where request URLs would end with a `?` character when sending GET requests with empty parameters.

# [2.1.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v2.1.0)

- Changed `ServiceTaskResult.Value` to use `Any` instead of `AnyObject` in order to support value types. fixes [#15](https://github.com/Electrode-iOS/ELWebService/issues/15).

# [2.0.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v2.0.0)

- Changed response handlers that are set with `response()`, `responseJSON`, and `responseError()` to run on a background queue. fixes #7.
- Added `updateErrorUI()` to set error handlers that run on the main queue. fixes #8
- Added `updateUI()` to set response handlers that run on the main queue.
- Added `ServiceTaskResult` to allow response handlers to control flow through the chain. 
- Added `SessionDataTaskDataSource` conformance to `NSURLSession`
- Removed [request option API](https://github.com/Electrode-iOS/ELWebService/commit/61fff95fc3c6bf340a8f25c75568b4a426b2bbe2) in favor of `ServiceTask` methods for setting request details.
- Added [`ServiceTask` methods](https://github.com/Electrode-iOS/ELWebService/commit/61fff95fc3c6bf340a8f25c75568b4a426b2bbe2#diff-0dbabe1bcb21e58eed224610cdb2bb40R85) for configuring the request details.

# [1.1.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v1.1.0)

- Added `body` parameter to `Request` for storing HTTP body data
- Added `.Body` and `.BodyJSON` request options to allow raw HTTP body contents to be defined
- Updated example project to provide a better example of ELWebService usage

# [1.0.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v1.0.0)

- Change `WebService` to a final class

# [0.1.0](https://github.com/Electrode-iOS/ELWebService/releases/tag/v0.1.0)

- Various updates for Swift 2 support based on Xcode 7 migration tool
- Enable testability for debug builds only
- Add `percentEncodeURLQueryCharacters` to encode params now that `stringByAddingPercentEscapesUsingEncoding` is deprecated in iOS 9
- Clean up unit tests to fix Xcode 7 warnings
- Audit access control and update tests based on new `@testability` Xcode 7 support 
- Use Swift 2's new `ErrorType` as the error parameter type for error handlers

# [0.0.3](https://github.com/Electrode-iOS/ELWebService/releases/tag/v0.0.3)

- Update example web service project to use `throwError()`
- Refactor error handling to utilize `Result` enum

# [0.0.2](https://github.com/Electrode-iOS/ELWebService/releases/tag/v0.0.2)

- Added Travis CI support
