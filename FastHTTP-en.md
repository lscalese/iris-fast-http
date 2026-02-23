# FastHTTP: Simplify Your HTTP Requests in ObjectScript

## Introduction

The standard `%Net.HttpRequest` library in InterSystems IRIS is powerful and comprehensive, but it can be verbose for simple operations. Writing an HTTP request often requires several lines of code to instantiate the class, configure the server, the port, HTTPS, add headers, and finally send the request.  

When testing in the terminal, this configuration quickly becomes too
heavy, and usually ends up with the creation of temporary methods...

**FastHTTP** was designed to address this need.  This utility class provides a fluent and concise interface to perform HTTP calls in a single line, while automatically handling the underlying complexity (SSL/TLS, URL parsing, JSON encoding, headers, etc.).

Of course, it is less feature-complete than `%Net.HttpRequest`; its goal is to simplify common use cases.

## Architecture and Design

The `dc.http.FastHTTP` class is a wrapper around `%Net.HttpRequest`. Its
key principles are:

1.  **String-based configuration**: Instead of defining each property
    individually, you pass a single configuration string (e.g.,
    `"url=https://api.com,header_Auth=xyz"`).
2.  **"Direct" ClassMethods**: Class methods (`DirectGet`, `DirectPost`,
    etc.) instantiate, configure, and execute the request in a single
    command line.
3.  **Automatic SSL handling**: FastHTTP detects the HTTPS protocol and
    automatically creates/applies a default SSL configuration if needed.
4.  **Native JSON support**: Request bodies are automatically processed
    as `"Content-Type=application/json"` if they are of type
    `%DynamicObject`.

## Practical Examples

### 1. Simple GET request

``` objectscript
// Simple GET call to a URL
Set response = ##class(dc.http.FastHTTP).DirectGet("url=https://jsonplaceholder.typicode.com/posts/1")

// The response is automatically a %DynamicObject
Write "Title: ", response.title, !
```

### 2. POST request with JSON

``` objectscript
Set payload = {"title": "foo", "body": "bar", "userId": 1}

// Send the POST
Set response = ##class(dc.http.FastHTTP).DirectPost("url=https://jsonplaceholder.typicode.com/posts,header_Authorization=Bearer TOKEN123", payload)

Write "Created ID: ", response.id, !
```

### 3. PUT and DELETE requests

``` objectscript
// PUT: Update
Set updateData = {"id": 1, "title": "Updated Title"}
Set respPut = ##class(dc.http.FastHTTP).DirectPut("url=https://jsonplaceholder.typicode.com/posts/1", updateData)

// DELETE: Deletion
Set respDel = ##class(dc.http.FastHTTP).DirectDelete("url=https://jsonplaceholder.typicode.com/posts/1")
```

### 4. Retrieve the client instance

If you need to access technical details (status codes, response headers), you can retrieve the `FastHTTP` instance by passing a variable by reference as the last parameter:

``` objectscript
Set response = ##class(dc.http.FastHTTP).DirectGet("url=https://httpbin.org/get",,.client)

// client.HttpRequest is the underlying %Net.HttpRequest object
Write "Status Code: ", client.HttpRequest.HttpResponse.StatusCode, !
```

## Comparison with %Net.HttpRequest

### With %Net.HttpRequest

``` objectscript
Set req = ##class(%Net.HttpRequest).%New()
Set req.Server = "api.example.com"
Set req.Https = 1
Set req.SSLConfiguration = "DefaultSSL" // must be created before
Do req.SetHeader("Authorization", "Bearer mytoken")
Do req.SetHeader("Content-Type", "application/json")

Set body = {"name": "Test"}
Do body.%ToJSON(req.EntityBody)

Set sc = req.Post("/v1/resource")
If $$$ISERR(sc) { /* Error handling */ }

Set jsonResponse = {}.%FromJSON(req.HttpResponse.Data)
```

### With FastHTTP

``` objectscript
Set body = {"name": "Test"}
Set response = ##class(dc.http.FastHTTP).DirectPost("url=https://api.example.com/v1/resource,header_Authorization=Bearer mytoken", body, .client)
```

FastHTTP:  
 1. Automatically adds the `Content-Type=application/json` header if the body is a `%DynamicObject`.  
 2. Uses `SSLConfiguration=DefaultSSL` and creates the configuration if it does not exist.  

The configuration string allows any `%Net.HttpRequest` property to be defined automatically using the form `"Property=value"` or a request header with the `header_` prefix, e.g.:  

## The `$$$f` macro

To make configuration string construction even more dynamic, the project introduces a utility macro ```$$$f```.

### Role and Function  

The `$$$f` macro (for “format” or “f-string”) allows variables to be interpolated directly into a character string. Python developers will have noticed that it is inspired by f-strings.

It transforms a string such as `"url={myUrl}"` into a valid ObjectScript expression `"url="_myUrl` at compile time.

### Technical definition

``` objectscript
#define f(%x)  ##function($replace($replace(##quote(%x),"{","""_"),"}","_"""))
```

### Usage example

Without `$$$f`, concatenating variables in the configuration gives:

```objectscript
Set baseUrl = "https://api.example.com"
Set token = "xyz123"
Set config = "url=" _ baseUrl _ "/users,header_Authorization=Bearer " _ token
Set resp = ##class(dc.http.FastHTTP).DirectGet(config)
```

With `$$$f`, the code becomes much readable:

```objectscript
// Assurez-vous que la macro est définie ou incluse
Set resp = ##class(dc.http.FastHTTP).DirectGet($$$f("url={baseUrl}/users,header_Authorization=Bearer {token}"))
```

### Why this macro?

It was introduced to maintain FastHTTP's "single-line configuration" philosophy, even when values (URLs, tokens) come from variables, object properties, or even methods. It avoids the multitude of quotation marks typically required for concatenation. As a macro, it cannot be used directly in the terminal, but it remains very useful in development.  Feel free to copy it into your personal `.inc` file.  An equivalent version provided natively by IRIS would also be very welcome.  

### The `$$$fe` variant

Through the examples in this document, you will have understood that the comma serves as a separator for “key=value” pairs in configuration strings, e.g., “key1=value1,key2=value,key3=value3”.  If a value itself contains a comma, it must be escaped: `\,`. The macro `$$$fe` combines the interpolation capabilities of `$$$f` with automatic escaping of reserved characters contained in variables: 

``` objectscript
Set value = "1,2,3"
Set string = $$$fe("key1={value},key2=test") ; --> "key1=1\,2\,3,key2=test"
```

## Sources

Everything is available on GitHub [iris-fast-http](https://github.com/lscalese/iris-fast-http) or with `zpm "fast-http"`.

## Additional notes

For developers who want to contribute to this project or simply work with it locally, unit tests are available and can be executed with:

zpm "test fast-http"

Integration tests are also provided in the `tests.dc.http.Integration` class. Their purpose is to validate the overall behavior by sending real HTTP requests to a test server.

If you are using Docker, the `docker-compose` file included in the project automatically starts an httpbin container:

```
httpbin:
  image: kennethreitz/httpbin
  ports:
    - "9292:80"
```
This service provides a ready-to-use test server for the `tests.dc.http.Integration` class.  

Integration tests can be enabled or disabled using the following parameter:

```
Set ^dc.http("RUNINTEGRATION") = 1  ; 1: enabled, 0: disabled
```

This parameter is automatically enabled when the repository is used with Docker.
If you are not developing with Docker, integration tests will be disabled by default and you will need to configure and adapt them to point to your own httpbin instance.  

## Conclusion

FastHTTP is a lightweight abstraction that modernizes the ObjectScript developer experience for HTTP interactions in IRIS. Thanks to a fluent API, text-based configuration, and syntactic shortcuts provided by the `$$$f` and `$$$fe` macros, it reduces complexity to leave room for business logic.  Ideal for rapid REST API integration, it targets is simple use cases based
on query parameters and JSON exchanges.
