# [2.0.0](https://github.com/TheHolyGrail/Swallow/releases/tag/v2.0.0)

- Changed response handlers that are set with `response()`, `responseJSON`, and `responseError()` to run on a background queue. fixes #7.
- Added `updateErrorUI()` to set error handlers that run on the main queue. fixes #8
- Added `updateUI()` to set response handlers that run on the main queue.
- Added `ServiceTaskResult` to allow response handlers to control flow through the chain. 
- Added `SessionDataTaskDataSource` conformance to `NSURLSession`
- Removed [request option API](https://github.com/TheHolyGrail/Swallow/commit/61fff95fc3c6bf340a8f25c75568b4a426b2bbe2) in favor of `ServiceTask` methods for setting request details.
- Added [`ServiceTask` methods](https://github.com/TheHolyGrail/Swallow/commit/61fff95fc3c6bf340a8f25c75568b4a426b2bbe2#diff-0dbabe1bcb21e58eed224610cdb2bb40R85) for configuring the request details.

## Migrating to 2.0

Swallow 2.0 contains a few breaking changes but migrating from previous versions is fairly straightforward. Below is an overview of how to adapt your existing Swallow code to the changes.

### New API for Request Configuration

The request option API was removed in favor of adding chainable methods to `ServiceTask` for configuring the HTTP request.


The old syntax:

```
service
    .POST("/post", 
        parameters: ["foo" : "this needs percent encoded"],
        options: [
            .Header("Custom-Header", forName: "bar")
        ])
      .response { data, res in
            // process response
        }
```

The new syntax:

```
service
    .POST("/post")
        .setHeaderValue("bar", forName: "Custom-Header")
        .setParameters(["foo" : "this needs percent encoded"])
    .response { data, res in
        // process response
    }
    .resume()
```

See the [Request Encoding](https://github.com/TheHolyGrail/Swallow/blob/master/docs/Swallow-Programming-Guide.md#request-encoding) section of programming guide for more information.

### Response Handlers Now Run on a Background Queue

Previously handlers set with `response()`, `responseJSON`, and `responseError()` were run on the main queue. This means you need to move any of your logic that updates UI into a handler set with `updateUI()`.

For more information about how the new `updateUI` and `updateErrorUI` methods work, see the [Updating UI](https://github.com/TheHolyGrail/Swallow/blob/master/docs/Swallow-Programming-Guide.md#updating-ui) section of the programming guide.

### `ServiceTask` instances no longer resume immediately

Prior to 2.0 `ServiceTask` instances were being resumed immediately after being initialized as a result of `WebService`'s `startTasksImmediately` property being set to true by default. Now that `ServiceTask` is also being used to chain request configuration details it is better to be explicit about when the `NSURLSessionDataTask` is being resumed.

To work with this change you must simply add a call to `resume()` at the end of your service task chain. If you fail to call `resume()` your request will not be sent.

```
service
    .POST("/post")
        .setHeaderValue("bar", forName: "Custom-Header")
        .setParameters(["foo" : "this needs percent encoded"])
    .response { data, res in
        // process response
    }
    .resume()
```

### Response Handlers Must Now Return a `ServiceTaskResult`

Swallow 2.0 introduces the `ServiceTaskResult` enum to control how values flow through the handler chain. This allows response handlers to run on the bg thread and pass processed data to the next response handler in the chain.

Response handlers written for pre-2.0 Swallow can be easily upgraded by having the handlers return `.Empty`.

For more information about using `ServiceTaskResult` values in response handlers see the [ServiceTaskResult](https://github.com/TheHolyGrail/Swallow/blob/master/docs/Swallow-Programming-Guide.md#servicetaskresult) section of the programming guide.


# [1.1.0](https://github.com/TheHolyGrail/Swallow/releases/tag/v1.1.0)

- Added `body` parameter to `Request` for storing HTTP body data
- Added `.Body` and `.BodyJSON` request options to allow raw HTTP body contents to be defined
- Updated example project to provide a better example of Swallow usage

# [1.0.0](https://github.com/TheHolyGrail/Swallow/releases/tag/v1.0.0)

- Change `WebService` to a final class

# [0.1.0](https://github.com/TheHolyGrail/Swallow/releases/tag/v0.1.0)

- Various updates for Swift 2 support based on Xcode 7 migration tool
- Enable testability for debug builds only
- Add `percentEncodeURLQueryCharacters` to encode params now that `stringByAddingPercentEscapesUsingEncoding` is deprecated in iOS 9
- Clean up unit tests to fix Xcode 7 warnings
- Audit access control and update tests based on new `@testability` Xcode 7 support 
- Use Swift 2's new `ErrorType` as the error parameter type for error handlers

# [0.0.3](https://github.com/TheHolyGrail/Swallow/releases/tag/v0.0.3)

- Update example web service project to use `throwError()`
- Refactor error handling to utilize `Result` enum

# [0.0.2](https://github.com/TheHolyGrail/Swallow/releases/tag/v0.0.2)

- Added Travis CI support
