Include FastHTTP

Class tests.dc.http.FastHTTP Extends %UnitTest.TestCase
{

Method TestNextPair()
{
    Set config = "url=http://test.com,Header_Auth=Bearer 123"
    Set pos = 1
    Set atEnd = 0
    
    Set pair1 = ##class(dc.http.FastHTTP).NextPair(config, .pos, .atEnd)
    Do $$$AssertEquals(pair1, "url=http://test.com", "First pair should be url")
    Do $$$AssertEquals(atEnd, 0, "atEnd should be 0 after first pair if more elements remain")
    
    Set pair2 = ##class(dc.http.FastHTTP).NextPair(config, .pos, .atEnd)
    Do $$$AssertEquals(pair2, "Header_Auth=Bearer 123", "Second pair should be header")
    Do $$$AssertEquals(atEnd, 1, "atEnd should be 1 after last pair")
}

Method TestNextPairEscaping()
{
    Set config = "key1=val\,with\,commas,key2=val\\with\\backslashes"
    Set pos = 1
    Set atEnd = 0
    
    Set pair1 = ##class(dc.http.FastHTTP).NextPair(config, .pos, .atEnd)
    Do $$$AssertEquals(pair1, "key1=val,with,commas", "Escaped commas should be unescaped")
    Do $$$AssertEquals(atEnd, 0, "atEnd should be 0 after first pair")

    Set pair2 = ##class(dc.http.FastHTTP).NextPair(config, .pos, .atEnd)
    Do $$$AssertEquals(pair2, "key2=val\with\backslashes", "Escaped backslashes should be unescaped")
    Do $$$AssertEquals(atEnd, 1, "atEnd should be 1 after last pair")
}

Method TestNextPairSingle()
{
    Set config = "url=http://test.com"
    Set pos = 1
    Set atEnd = 0
    
    Set pair = ##class(dc.http.FastHTTP).NextPair(config, .pos, .atEnd)
    Do $$$AssertEquals(pair, "url=http://test.com", "Should parse single pair")
    Do $$$AssertEquals(atEnd, 1, "atEnd should be 1 for single pair")
}

Method TestMacroF()
{
    Set host = "localhost"
    Set port = 8080
    Set result = $$$f("url=http://{host}:{port}/api")
    Do $$$AssertEquals(result, "url=http://localhost:8080/api", "Macro $$$f should interpolate variables")
    
    Set key = "Authorization"
    Set val = "Bearer TOKEN"
    Set result2 = $$$f("header_{key}={val}")
    Do $$$AssertEquals(result2, "header_Authorization=Bearer TOKEN", "Macro $$$f should work with multiple variables")
}

Method TestMacroFE()
{
    Set valWithComma = "value,with,comma"
    // $$$fe is designed to escape values to be safe for config strings
    Set result = $$$fe("key={valWithComma}")
    Do $$$AssertEquals(result, "key=value\,with\,comma", "Macro $$$fe should escape commas in interpolated values")
    
    Set valWithBackslash = "value\with\backslash"
    Set result2 = $$$fe("key={valWithBackslash}")
    // The macro fe definition for backslash escaping: $replace(...,"","",""\\"") - wait, the .inc file had a weird replace
    // #define fe(%x)      ##function($replace($replace(##quote(%x),"{","""_$replace($replace("),"}",",""\"",""\\""),"","",""\,"")_"""))
    // Let's re-examine that INC file.
    Do $$$AssertEquals(result2, "key=value\\with\\backslash", "Macro $$$fe should escape backslashes in interpolated values")
}

Method TestCache()
{
    // Clear cache before starting
    Do ##class(dc.http.FastHTTP).ClearCache()
    
    Set key = "testKey"
    Set value = "testValue"
    
    // Test Set and Get
    Do ##class(dc.http.FastHTTP).SetCacheData(key, value)
    Do $$$AssertEquals(##class(dc.http.FastHTTP).GetCacheData(key), value, "Cache should return the value previously set")
    
    // Test update
    Set newValue = "updatedValue"
    Do ##class(dc.http.FastHTTP).SetCacheData(key, newValue)
    Do $$$AssertEquals(##class(dc.http.FastHTTP).GetCacheData(key), newValue, "Cache should return the updated value")
    
    // Test Clear
    Do ##class(dc.http.FastHTTP).ClearCache()
    Do $$$AssertEquals(##class(dc.http.FastHTTP).GetCacheData(key), "", "Cache should be empty after ClearCache")
}

Method TestInitMapLowerProperties()
{
    Do ##class(dc.http.FastHTTP).initMapLowerProperties(.map)
    
    Set key = ""
    For {
        Set key = $Order(map(key), 1, propName)
        Quit:key=""
        
        Set exists = ##class(%Dictionary.CompiledProperty).%ExistsId("%Net.HttpRequest||"_propName)
        Do $$$AssertTrue(exists, "Property '"_propName_"' should exist in %Net.HttpRequest")
    }
}

Method TestParseConfigString()
{
    // Test empty
    Set config = ##class(dc.http.FastHTTP).ParseConfigString("")
    Do $$$AssertEquals(config.%ToJSON(), "{}", "Empty string should return empty object")

    // Test URL and headers
    Set str = "url=http://test.com/api,Header_Authorization=Bearer 123,Header_X-Test=Value"
    Set config = ##class(dc.http.FastHTTP).ParseConfigString(str)
    Do $$$AssertEquals(config.url, "http://test.com/api", "URL should be correctly parsed")
    Do $$$AssertTrue($IsObject(config.headers), "Headers should be an object")
    Do $$$AssertEquals(config.headers."Authorization", "Bearer 123", "Authorization header should be present")
    Do $$$AssertEquals(config.headers."X-Test", "Value", "X-Test header should be present")

    // Test HttpRequest properties (mapped)
    Set str = "timeout=30,sslconfiguration=MyConfig,callback=myclass.mymethod,resource_id=stream123"
    Set config = ##class(dc.http.FastHTTP).ParseConfigString(str)
    Do $$$AssertEquals(config.Timeout, 30, "Timeout should be mapped to TitleCase")
    Do $$$AssertEquals(config.SSLConfiguration, "MyConfig", "SSLConfiguration should be mapped to TitleCase")
    Do $$$AssertEquals(config.%Get("callback"), "myclass.mymethod", "Callback should be preserved")
    Do $$$AssertEquals(config.%Get("resource_id"), "stream123", "Resource ID should be preserved")
    
    // Test escaping in values
    Set str = "url=http://site.com?q=a\,b,Header_Custom=Val\,with\,comma"
    Set config = ##class(dc.http.FastHTTP).ParseConfigString(str)
    Do $$$AssertEquals(config.url, "http://site.com?q=a,b", "Escaped comma in URL should be unescaped")
    Do $$$AssertEquals(config.headers.Custom, "Val,with,comma", "Escaped comma in header should be unescaped")
}

Method TestSetUrl()
{
    Set client = ##class(dc.http.FastHTTP).%New()
    
    // Test HTTP
    Do client.Seturl("http://example.com:8080/api/v1")
    Do $$$AssertEquals(client.HttpRequest.Server, "example.com", "Server should be example.com")
    Do $$$AssertEquals(client.HttpRequest.Port, 8080, "Port should be 8080")
    Do $$$AssertEquals(client.HttpRequest.Https, 0, "Https should be 0 for http scheme")
    Do $$$AssertEquals(client.HttpRequest.Location, "/api/v1", "Location should be /api/v1")

    // Test HTTPS with default port
    Do client.Seturl("https://secure.com/login")
    Do $$$AssertEquals(client.HttpRequest.Server, "secure.com")
    Do $$$AssertEquals(client.HttpRequest.Port, 443, "Default port for https should be 443")
    Do $$$AssertEquals(client.HttpRequest.Https, 1, "Https should be 1 for https scheme")
    Do $$$AssertEquals(client.HttpRequest.Location, "/login")

    // Test HTTP with default port
    Do client.Seturl("http://basic.com")
    Do $$$AssertEquals(client.HttpRequest.Port, 80, "Default port for http should be 80")

    // Test URL with query parameters
    Set client = ##class(dc.http.FastHTTP).%New()
    Do client.Seturl("http://search.com/find?q=iris&lang=fr&multi=1&multi=2")
    Do $$$AssertEquals(client.HttpRequest.Server, "search.com")
    Do $$$AssertEquals(client.HttpRequest.Location, "/find")
    Do $$$AssertEquals(client.HttpRequest.GetParam("q"), "iris", "Query parameter 'q' should be 'iris'")
    Do $$$AssertEquals(client.HttpRequest.GetParam("lang"), "fr", "Query parameter 'lang' should be 'fr'")
    Do $$$AssertEquals(client.HttpRequest.GetParam("multi", ,1), "1", "First 'multi' parameter should be 1")
    Do $$$AssertEquals(client.HttpRequest.GetParam("multi", ,2), "2", "Second 'multi' parameter should be 2")

    // Test URL with complex query parameter (containing =)
    Set client = ##class(dc.http.FastHTTP).%New()
    Do client.Seturl("http://search.com/find?token=abc=def")
    Do $$$AssertEquals(client.HttpRequest.GetParam("token"), "abc=def", "Query parameter 'token' should be 'abc=def'")
}

Method TestApplyConfig()
{
    Set client = ##class(dc.http.FastHTTP).%New()
    
    // Mixed config: URL, mapped property, Header and callback
    Set configStr = "url=https://api.test.com/v1,timeout=45,Header_Authorization=Bearer XYZ,callback=MyClass.MyMethod,resource_id=stream123"
    Set sc = client.ApplyConfig(configStr)
    Do $$$AssertStatusOK(sc, "ApplyConfig should return OK")
    
    // Assertions
    Do $$$AssertEquals(client.HttpRequest.Server, "api.test.com", "Server should be extracted from URL")
    Do $$$AssertEquals(client.HttpRequest.Timeout, 45, "Timeout property should be set")
    Do $$$AssertEquals(client.HttpRequest.GetHeader("Authorization"), "Bearer XYZ", "Header should be set")
    
    // SSL Defaults
    Do $$$AssertEquals(client.HttpRequest.Https, 1, "Https should be enabled")
    Do $$$AssertEquals(client.HttpRequest.SSLConfiguration, "DefaultSSL", "SSLConfiguration should default to DefaultSSL for Https")
    
    // Stream mode
    Do $$$AssertTrue($IsObject(client.HttpRequest.ResponseStream), "ResponseStream should be initialized")
    Do $$$AssertTrue(client.HttpRequest.ResponseStream.%IsA("dc.http.Stream"), "ResponseStream should be a dc.http.Stream")
}

}
