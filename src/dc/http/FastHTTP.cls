Include FastHTTP

Class dc.http.FastHTTP Extends %RegisteredObject
{

Parameter STRINGSEPARATOR = ",";

Parameter ESCAPECHAR = "\";

Parameter DEFAULTSSL = "DefaultSSL";

Property HttpRequest As %Net.HttpRequest [ InitialExpression = {##class(%Net.HttpRequest).%New()} ];

/// Ex: Set client = ##class(dc.http.FastHTTP).%New("url=http://example.com/api,Header_Authorization=Bearer <yourkey>")
Method %OnNew(config As %String = "") As %Status
{
    Return ..ApplyConfig(config)
}

ClassMethod DirectGet(config As %String, body = "", Output client As dc.http.FastHTTP) As %DynamicObject
{
    Return ..DirectSend("GET", config, body, .client)
}

ClassMethod DirectDelete(config As %String, body = "", Output client As dc.http.FastHTTP) As %DynamicObject
{
    Return ..DirectSend("DELETE", config, body, .client)
}

ClassMethod DirectPost(config As %String, body = "", Output client As dc.http.FastHTTP) As %DynamicObject
{
    Return ..DirectSend("POST", config, body, .client)
}

ClassMethod DirectPut(config As %String, body = "", Output client As dc.http.FastHTTP) As %DynamicObject
{
    Return ..DirectSend("PUT", config, body, .client)
}

ClassMethod DirectSend(method As %String, config As %String, body = "", Output client As dc.http.FastHTTP) As %DynamicObject
{
    Set client = ..%New(config)
    Return client.SendRequest($$$UPPER(method), "", body)
}

Method ApplyConfig(configString As %String = "") As %Status
{
    If configString = "" {
        Return $$$OK
    }
    Set config = ..ParseConfigString(configString)

    Do ..initMapLowerProperties(.mapLowerProperties)

    If config.url '= "" {
        Do ..Seturl(config.url)
    }

    Set iterator = config.%GetIterator()
    While iterator.%GetNext(.key, .value) {
        Set lowerKey = $ZConvert(key, "L")

        Set httpRequestProperty = $Get(mapLowerProperties(lowerKey))
        Continue:httpRequestProperty=""
        
        Set $Property(..HttpRequest, httpRequestProperty) = value
    }

    If ..HttpRequest.Https, ..HttpRequest.SSLConfiguration = "" {
        Set ..HttpRequest.SSLConfiguration = ..#DEFAULTSSL
    }

    If ..HttpRequest.Https, '$Get(%zSSLConfigExists(..HttpRequest.SSLConfiguration), $$$NO) {
        Do ..CreateSSLConfiguration(..HttpRequest.SSLConfiguration)
    }

    If config.%Get("stream_mode") '= "" {
        Set responseStream = ##class(dc.http.Stream).%New()
        Set responseStream.ResourceId = config.%Get("stream_mode")
        Set ..HttpRequest.ResponseStream = responseStream
    }
    
    Return:'$IsObject(config.headers) $$$OK
    
    Set iter = config.headers.%GetIterator()
    While iter.%GetNext(.key, .value) {
        Do ..HttpRequest.SetHeader(key, value)
    }
    
    Return $$$OK
}

ClassMethod ParseConfigString(pConfigStr As %String) As %DynamicObject
{
    If pConfigStr = "" {
        Return {}
    }

    Set separator = ..#STRINGSEPARATOR

    Set config = {}, headers = {}
    Do ..initMapLowerProperties(.mapLowerProperties)

    ;Set len = $Length(pConfigStr, separator)
    ;For i=1:1:len {
    ;    Set pair = $Piece(pConfigStr, separator, i)
    ;    Continue:pair=""
    Set atEnd = 0
    While 'atEnd {
        Set pair = ..NextPair(pConfigStr, .position, .atEnd)
        Continue:pair=""

        Set key = $ZStrip($Piece(pair, "=", 1), "<>W") // Trim whitespace
        Set val = $Piece(pair, "=", 2, *) // Le reste est la valeur
        
        Continue:key=""
        Set lowerKey = $ZConvert(key, "L")
        
        If $Extract(lowerKey, 1, 7) = "header_" {
            Set headerName = $Extract(key, 8, *) // Ex: Header_Authorization -> Authorization
            Do headers.%Set(headerName, val)
            Continue
        }
        
        If lowerKey = "url" {
            Do config.%Set("url", val)
            Continue
        }

        If lowerKey = "stream_mode" {
            Do config.%Set("stream_mode", val)
            Continue
        }

        Set httpRequestProperty = $Get(mapLowerProperties(lowerKey))
        If httpRequestProperty = "" {
            Write:$Get(%zDebug) !,"Warning: Unrecognized config key '" _ key _ "' with value '" _ val _ "'"
            Continue
        }
        
        Do config.%Set(httpRequestProperty, val)
    }
    
    If headers.%Size() > 0 {
        Set config.headers = headers
    }
    
    Return config
}

ClassMethod NextPair(configString As %String, ByRef position As %Integer = 1, Output atEnd As %Boolean = 0) As %String
{
    If position > $Length(configString) {
        Set atEnd = 1
        Return ""
    }
    
    Set pair = "",  separator = ..#STRINGSEPARATOR, escapeChar = ..#ESCAPECHAR

    #define isEscapedSeparator (char = escapeChar && (nextChar = separator))
    #define isDoubleEscaping (char = escapeChar && (nextChar = escapeChar))
    
    For i=position:1:$Length(configString) {
        Set char = $Extract(configString, i)
        Set nextChar = $Extract(configString, i+1)
        If $$$isEscapedSeparator || $$$isDoubleEscaping {
            Set pair = pair _ nextChar
            Set i = i + 1
            Continue
        }
        If char = separator {
            Set i = i + 1
            Quit
        }
        Set pair = pair _ char
    }

    Set position = i
    Set atEnd = (position >= $Length(configString))

    Return pair
}

/// Configure l'URL de base et prépare la requête (serveur, port, https)
Method Seturl(pUrl As %String) As %Status
{
    Do ##class(%Net.URLParser).Decompose(pUrl, .components)
    
    Set ..HttpRequest.Server = $Get(components("host"))
    Set ..HttpRequest.Port = $Get(components("port"))
    
    Set scheme = $ZConvert($Get(components("scheme")),"L")
    Set ..HttpRequest.Https = (scheme = "https")
    
    If ..HttpRequest.Port = "" {
        Set ..HttpRequest.Port = $Select(..HttpRequest.Https:443, 1:80)
    }

    If $Get(components("path")) '= "" {
        Set ..HttpRequest.Location = components("path")    
    }
    
    Return $$$OK
}

/// Ajoute un header à la requête
Method SetHeader(pName As %String, pValue As %String)
{
    Do ..HttpRequest.SetHeader(pName, pValue)
}

/// Méthode générique d'envoi
Method SendRequest(pMethod As %String, pPath As %String, pBody As %DynamicObject = "") As %DynamicObject
{
    Do ..HandleEntityBody(pBody)

    Set sc = $$$OK
    If pMethod = "GET" {
        Set sc = ..HttpRequest.Get(pPath)
    } ElseIf pMethod = "POST" {
        Set sc = ..HttpRequest.Post(pPath)
    } ElseIf pMethod = "PUT" {
        Set sc = ..HttpRequest.Put(pPath)
    } ElseIf pMethod = "DELETE" {
        Set sc = ..HttpRequest.Delete(pPath)
    }
    
    If $$$ISERR(sc) Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    
    // Vérification basique du code HTTP (peut être affiné)
    If (..HttpRequest.HttpResponse.StatusCode >= 400) {
        Throw ##class(%Exception.General).%New("HTTP Error: " _ ..HttpRequest.HttpResponse.StatusCode _ " - " _ ..HttpRequest.HttpResponse.ReasonPhrase)
    }
    
    // Lecture de la réponse
    Set responseData = ..HttpRequest.HttpResponse.Data
    If $IsObject(responseData) && responseData.Size > 0 {
        // Tente de retourner un DynamicObject s'il s'agit de JSON
        Try {
            Return {}.%FromJSON(responseData)
        } Catch {
            // Sinon retourne le stream brut ou une chaîne (selon besoin)
            Do responseData.Rewind()
            Return {"raw": (responseData.Read())}
        }
    }
    
    Return {}
}

Method HandleEntityBody(pBody = "") As %Status [ Internal ]
{
    If pBody = "" {
        Return $$$OK
    }
    
    If '$IsObject(pBody)  {
        Do ..HttpRequest.EntityBody.Write(pBody)
        Return $$$OK
    }

    If pBody.%IsA("%DynamicObject") {
        If ..HttpRequest.GetHeader("Content-Type") = "" {
            Do ..HttpRequest.SetHeader("Content-Type", "application/json")
        }
        Do pBody.%ToJSON(..HttpRequest.EntityBody)
    }
    
    If pBody.%IsA("%Stream.Object") {
        Do ..HttpRequest.EntityBody.CopyFrom(pBody)
    }

    Return $$$OK
}

ClassMethod CreateSSLConfiguration(Name As %String = "DefaultSSL") As %Status
{
    New $namespace
    Set $namespace="%SYS", sc = $$$OK
    If '##class(Security.SSLConfigs).Exists(Name) {
        Set sc = ##class(Security.SSLConfigs).Create(Name)
    }
    Set:$$$ISOK(sc) %zSSLConfigExists(Name) = $$$YES
    Return sc
}

ClassMethod initMapLowerProperties(ByRef mapLowerProperties) As %Status [ Internal ]
{
    Set mapLowerProperties("followredirect") = "FollowRedirect"
    Set mapLowerProperties("forcereusedevice") = "ForceReuseDevice"
    Set mapLowerProperties("localinterface") = "LocalInterface"
    Set mapLowerProperties("location") = "Location"
    Set mapLowerProperties("nodefaultcontentcharset") = "NoDefaultContentCharset "
    Set mapLowerProperties("opentimeout") = "OpenTimeout"
    Set mapLowerProperties("postgzip") = "PostGzip"
    Set mapLowerProperties("proxyhttps") = "ProxyHTTPS"
    Set mapLowerProperties("proxyport") = "ProxyPort"
    Set mapLowerProperties("proxyserver") = "ProxyServer"
    Set mapLowerProperties("readrawmode") = "ReadRawMode"
    Set mapLowerProperties("readtimeout") = "ReadTimeout"
    Set mapLowerProperties("requestheadercharset") = "RequestHeaderCharset"
    Set mapLowerProperties("returngzipresponse") = "ReturnGzipResponse"
    Set mapLowerProperties("sslcheckserveridentity") = "SSLCheckServerIdentity"
    Set mapLowerProperties("sslconfiguration") = "SSLConfiguration"
    Set mapLowerProperties("sockettimeout") = "SocketTimeout"
    Set mapLowerProperties("timeout") = "Timeout"
    Set mapLowerProperties("writerawmode") = "WriteRawMode"
    Set mapLowerProperties("writetimeout") = "WriteTimeout"
    Return $$$OK
}

ClassMethod t()
{
    
    S a = "abc,def\ghi"
    S b = "application/json"
    w $$$fe("url={a},Header_Test={b}")
}

}
