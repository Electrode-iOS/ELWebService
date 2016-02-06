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
