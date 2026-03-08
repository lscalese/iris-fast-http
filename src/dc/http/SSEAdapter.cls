Class dc.http.SSEAdapter Extends %RegisteredObject [ Abstract ]
{

Method OnMessage(item As dc.http.SSEMessage) As %Status [ Abstract ]
{
    Return $$$OK
}

Method Reset()
{
}

ClassMethod GetStream() As dc.http.Stream
{
    Set stream = ##class(dc.http.Stream).%New()
    Set adapter = ..%New()
    Set handler = ##class(dc.http.SSEHandler).%New(adapter)
    Set stream.SSEHandler = handler
    Return stream
}

}
