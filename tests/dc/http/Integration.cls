Include FastHTTP

Class tests.dc.http.Integration Extends %UnitTest.TestCase
{

/// Set this parameter to 1 to run integration tests
Parameter RUNINTEGRATION = {$Get(^dc.http("RUNINTEGRATION"),0)};

Method TestDirectGet()
{
    // Skip if integration tests are not enabled (to avoid failure if httpbin is not reachable)
    If ..#RUNINTEGRATION = 0 {
        Do $$$LogMessage("Skipping TestDirectGet because integration tests are disabled (^dc.http(""RUNINTEGRATION"") = 0)")
        Return
    }

    Set config = "url=http://httpbin/get?test=directget,timeout=5"
    Try {
        Set response = ##class(dc.http.FastHTTP).DirectGet(config, , .client)
        
        Do $$$AssertStatusOK($$$OK, "DirectGet should execute without throwing")
        Do $$$AssertEquals(client.HttpRequest.HttpResponse.StatusCode, 200, "Status code should be 200")
        
        // httpbin returns query params in 'args' field
        Do $$$AssertEquals(response.data.args.test, "directget", "Response should contain our query parameter")
    } Catch ex {
        Do $$$AssertStatusOK(ex.AsStatus(), "DirectGet should not throw an exception: " _ ex.DisplayString())
    }
}

Method TestIntegrationGET()
{
    // Skip if integration tests are not enabled (to avoid failure if httpbin is not reachable)
    If ..#RUNINTEGRATION = 0 {
        Do $$$LogMessage("Skipping TestIntegrationGET because integration tests are disabled (^dc.http(""RUNINTEGRATION"") = 0)")
        Return
    }

    Set client = ##class(dc.http.FastHTTP).%New()
    
    // Test a real GET to httpbin (inside docker network)
    // Server: httpbin, Port: 80
    Set config = "url=http://httpbin/get?test=123,timeout=5"
    Set sc = client.ApplyConfig(config)
    Do $$$AssertStatusOK(sc, "ApplyConfig for integration test")
    
    Set response = client.SendRequest("GET", "")
    Do $$$AssertTrue($IsObject(response), "Execute GET should return an object")
    Do $$$AssertEquals(client.HttpRequest.HttpResponse.StatusCode, 200, "Status code should be 200")
    
    // Read response
    Do client.HttpRequest.HttpResponse.Data.Rewind()
    Set rawResponse = client.HttpRequest.HttpResponse.Data.Read()
    Do $$$AssertTrue(rawResponse [ """test"": ""123""", "Response should contain our query parameter")
}

Method TestIntegrationPOST()
{
    // Skip if integration tests are not enabled (to avoid failure if httpbin is not reachable)
    If ..#RUNINTEGRATION = 0 {
        Do $$$LogMessage("Skipping TestIntegrationPOST because integration tests are disabled (^dc.http(""RUNINTEGRATION"") = 0)")
        Return
    }
    Set client = ##class(dc.http.FastHTTP).%New()
    
    // Test a real POST to httpbin
    Set config = "url=http://httpbin/post,timeout=5,Header_Content-Type=application/json"
    Set sc = client.ApplyConfig(config)
    
    Set body = "{""hello"": ""world""}"
    Set response = client.SendRequest("POST","",body)
    Do $$$AssertTrue($IsObject(response), "Execute POST should return an object")
    Do $$$AssertEquals(client.HttpRequest.HttpResponse.StatusCode, 200, "Status code should be 200")
    
    // httpbin returns the JSON body in the "json" field of its response
    Do client.HttpRequest.HttpResponse.Data.Rewind()
    Set rawResponse = client.HttpRequest.HttpResponse.Data.Read()
    Do $$$AssertTrue(rawResponse [ """hello"": ""world""", "Response should contain our JSON body")
}

Method TestDirectPost()
{
    If ..#RUNINTEGRATION = 0 {
        Do $$$LogMessage("Skipping TestDirectPost because integration tests are disabled (^dc.http(""RUNINTEGRATION"") = 0)")
        Return
    }
    
    Set config = "url=http://httpbin/post,timeout=5"
    Set body = {"test":"directpost"}
    Try {
        Set response = ##class(dc.http.FastHTTP).DirectPost(config, body, .client)
        Do $$$AssertEquals(client.HttpRequest.HttpResponse.StatusCode, 200, "DirectPost status code 200")
        Do $$$AssertEquals(response.data.json.test, "directpost", "DirectPost body check")
    } Catch ex {
        Do $$$AssertStatusOK(ex.AsStatus(), "DirectPost should not throw")
    }
}

Method TestDirectPut()
{
    If ..#RUNINTEGRATION = 0 {
        Do $$$LogMessage("Skipping TestDirectPut because integration tests are disabled (^dc.http(""RUNINTEGRATION"") = 0)")
        Return
    }
    
    Set config = "url=http://httpbin/put,timeout=5"
    Set body = {"test":"directput"}
    Try {
        Set response = ##class(dc.http.FastHTTP).DirectPut(config, body, .client)
        Do $$$AssertEquals(client.HttpRequest.HttpResponse.StatusCode, 200, "DirectPut status code 200")
        Do $$$AssertEquals(response.data.json.test, "directput", "DirectPut body check")
    } Catch ex {
        Do $$$AssertStatusOK(ex.AsStatus(), "DirectPut should not throw")
    }
}

Method TestDirectDelete()
{
    If ..#RUNINTEGRATION = 0 {
        Do $$$LogMessage("Skipping TestDirectDelete because integration tests are disabled (^dc.http(""RUNINTEGRATION"") = 0)")
        Return
    }
    
    Set config = "url=http://httpbin/delete,timeout=5"
    Try {
        Set response = ##class(dc.http.FastHTTP).DirectDelete(config, , .client)
        Do $$$AssertEquals(client.HttpRequest.HttpResponse.StatusCode, 200, "DirectDelete status code 200")
    } Catch ex {
        Do $$$AssertStatusOK(ex.AsStatus(), "DirectDelete should not throw")
    }
}

}
