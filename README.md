

# Swallow

A simple and concise API for interacting with HTTP web services in Swift.

## Features

- Simple and concise API for declaring HTTP web service interactions
- Chainable response handlers allow for better readability
- Constructs URLs using a base URL and relative path of service endpoint
- Flexible to work with any NSURLSession-based API.
  + Dependant on a single protocol method to dispatch and handle NSURLSessionDataTask objects
  + Built-in HTTP networking support using a simple NSURLSession wrapper but is extendable to work with any NSURLSession-based API

## Example

An example project is included that demonstrates how Swallow can be used to interact with a web service. A stubbed endpoint is available at [https://somehapi.herokuapp.com/stores](https://somehapi.herokuapp.com/stores) for testing.

## Usage

At the highest level a request to a service endpoint for a resource could look like the following:

```
// fetch list of stores based on zip code value
let webService = WebService(baseURLString: "https://somehapi.herokuapp.com")
webService.fetchStores(zipCode: "15217")
          .responseStoreModels { models in
            // models is an array of StoreModel values
          }
          .responseError { response, error in
            // I am error
          }
```

The `WebService` structure and `ServiceTask` class provide the basic building blocks to make this short and simple syntax possible.

### Making HTTP Requests

At the lowest level `WebService` supports an API for making a HTTP request and processing the raw response data.

```
WebService(baseURLString: "https://somehapi.herokuapp.com")
  .GET("/stores", parameters: ["zip" : "15217"])
  .response { (response: NSURLResponse?, data: NSData?) in
    // process response data
  }
```

Add a `responseError()` handler to handle the possibility of a failed request.

```
WebService(baseURLString: "https://somehapi.herokuapp.com")
  .GET("/stores", parameters: ["zip" : "15217"])
  .response { (response: NSURLResponse?, data: NSData?) in
    // process response data
  }
  .responseError { (error: NSError?) in
    // I am error
  }
```

The `responseError()` handler will only be called when a request results in an error. If an error occurs all other response handlers will not be called. This pattern allows you to cleanly separate the logic for handling success and failure cases.

### Response Handlers

Response handlers can be chained to process the response of the request. After the response is received handlers are invoked in the order of which they are declared.

```
WebService(baseURLString: "https://somehapi.herokuapp.com")
  .GET("/stores", parameters: ["zip" : "15217"])
  .response { (response: NSURLResponse?, data: NSData?) in
    // process raw response
  }
  .responseJSON { json in
    // process response as JSON
  }
```

> **NOTE:**
> Currently all response handlers are run on the main thread. The goal is to support [KillerRabbit](https://github.com/TheHolyGrail/KillerRabbit) as a means for controlling how response handlers are dispatched.

### Extensions

The chainable response handler API makes it easy to create custom response handlers using extensions.

```
// MARK: - Store Locator Services

extension ServiceTask {
    
    public typealias StoreServiceSuccess = ([StoreModel]?) -> Void
    
    func responseStoreModels(handler: StoreServiceSuccess) -> Self {
        
        return responseJSON { json in
            if let models: [StoreModel]? = self.parseJSONAsStoreModels(json) {
                handler(models)
            }
        }
    }
}
```

This allows you to wrap the details of how the response is processed in a high-level convenience method enabling you to simplify how consumers interact with your web service API.

```
WebService(baseURLString: "https://somehapi.herokuapp.com")
  .GET("/stores", parameters: ["zip" : "15217"])
  .responseStoreModels { (models: [StoreModel]?) in
    // process resonse as model objects and update UI
  }
  .responseError { error in
    // I am error
  }
```

Extensions are also useful for wrapping the details of the web service requests. This is an ideal approach because all of the details of the HTTP request are declared inline with the service call method.

```
public extension WebService {
    
    public func fetchStores(zipCode aZipCode: String) -> ServiceTask {
        
        return GET("/stores", parameters: ["zip" : aZipCode])
    }
}
```

Extensions are powerful constructs for wrapping the HTTP details of a web service call and provide a mechanism for your code to be declaritive about how to interact with web services.

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

### Protocols

**`DataTaskConstructible`**

Swallow can be customized to work with any NSURLSession-based API by providing the `DataTaskConstructible` protocol. Objects conforming to the `DataTaskConstructible` protocol are responsible for creating `NSURLSessionDataTask` objects based on a `NSURLRequest` object and invoking a completion handler after the response of a data task has been received.

By default Swallow implements the `DataTaskConstructible` protocol as a private structure using the shared session returned from `NSURLSession.sharedSession()`. 


### Dispatch Queues

The dispatch queue used to execute the response handler can be specified using a DispatchQueue value from [`KillerRabbit`](https://github.com/TheHolyGrail/KillerRabbit).

```
WebService(baseURLString: "https://somehapi.herokuapp.com")
  .GET("/stores", parameters: ["zip" : "15217"])
  .response(.Background) { (response: NSURLResponse?, data: NSData?) in
    // process response data
  }
```


Calls can be chained together to run on different queues.

WebService(baseURLString: "https://somehapi.herokuapp.com")
  .GET("/stores", parameters: ["zip" : "15217"])
  .response(.Background) { (response: NSURLResponse?, data: NSData?) in
    // process raw response on background
  }
  .responseJSON(.Main) { json in
    // use json on main thread
  }
```
