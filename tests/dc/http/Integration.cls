Include FastHTTP

Class tests.dc.http.Integration Extends %UnitTest.TestCase
{

/// Set this parameter to 1 to run integration tests
Parameter RUNINTEGRATION = {$Get(^dc.http("RUNINTEGRATION"),0)};

Method TestIntegrationGET()
{
    If '..#RUNINTEGRATION = 0 {
       Return
    }

    Set client = ##class(dc.http.FastHTTP).%New()
    
    // Test a real GET to httpbin (inside docker network)
    // Server: httpbin, Port: 80
    Set config = "url=http://httpbin/get?test=123,timeout=5"
    Set sc = client.ApplyConfig(config)
    Do $$$AssertStatusOK(sc, "ApplyConfig for integration test")
    
    Set sc = client.SendRequest("GET", "")
    Do $$$AssertStatusOK(sc, "Execute GET")
    Do $$$AssertEquals(client.HttpRequest.HttpResponse.StatusCode, 200, "Status code should be 200")
    
    // Read response
    Do client.HttpRequest.HttpResponse.Data.Rewind()
    Set response = client.HttpRequest.HttpResponse.Data.Read()
    Do $$$AssertTrue(response [ """test"": ""123""", "Response should contain our query parameter")
}

Method TestIntegrationPOST()
{
    If '..#RUNINTEGRATION = 0 {
       Return
    }
    Set client = ##class(dc.http.FastHTTP).%New()
    
    // Test a real POST to httpbin
    Set config = "url=http://httpbin/post,timeout=5,Header_Content-Type=application/json"
    Set sc = client.ApplyConfig(config)
    
    Set body = "{""hello"": ""world""}"
    Set sc = client.SendRequest("POST","",body)
    Do $$$AssertStatusOK(sc, "Execute POST")
    Do $$$AssertEquals(client.HttpRequest.HttpResponse.StatusCode, 200, "Status code should be 200")
    
    // httpbin returns the JSON body in the "json" field of its response
    Do client.HttpRequest.HttpResponse.Data.Rewind()
    Set response = client.HttpRequest.HttpResponse.Data.Read()
    Do $$$AssertTrue(response [ """hello"": ""world""", "Response should contain our JSON body")
}

}
