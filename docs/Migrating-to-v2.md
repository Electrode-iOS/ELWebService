# Migrating to v2

ELWebService v2 contains a few breaking changes but migrating from previous versions is fairly straightforward. Below is an overview of how to adapt your existing ELWebService code to the changes.

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

See the [Request Encoding](https://github.com/Electrode-iOS/ELWebService/blob/master/docs/ELWebService-Programming-Guide.md#request-encoding) section of programming guide for more information.

### Response Handlers Now Run on a Background Queue

Previously handlers set with `response()`, `responseJSON`, and `responseError()` were run on the main queue. This means you need to move any of your logic that updates UI into a handler set with `updateUI()`.

For more information about how the new `updateUI` and `updateErrorUI` methods work, see the [Updating UI](https://github.com/Electrode-iOS/ELWebService/blob/master/docs/ELWebService-Programming-Guide.md#updating-ui) section of the programming guide.

### `ServiceTask` instances no longer resume immediately

Prior to v2 `ServiceTask` instances were being resumed immediately after being initialized as a result of `WebService`'s `startTasksImmediately` property being set to true by default. Now that `ServiceTask` is also being used to chain request configuration details it is better to be explicit about when the `NSURLSessionDataTask` is being resumed.

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

ELWebService v2 introduces the `ServiceTaskResult` enum to control how values flow through the handler chain. This allows response handlers to run on the bg thread and pass processed data to the next response handler in the chain.

Response handlers written for pre-v2 ELWebService can be easily upgraded by having the handlers return `.Empty`.

For more information about using `ServiceTaskResult` values in response handlers see the [ServiceTaskResult](https://github.com/Electrode-iOS/ELWebService/blob/master/docs/ELWebService-Programming-Guide.md#servicetaskresult) section of the programming guide.
