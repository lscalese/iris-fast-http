/// Basic Server Sent Event handler for unit testing.
Class tests.dc.http.SSEHandler Extends dc.http.ServerSentEventHandler
{

ClassMethod OnMessage(item As dc.http.ServerSentEventMessage) As %Status
{
    Set index = $Increment(^||CallbackData)
    Set ^||CallbackData(index) = $lb(item.EventName, item.Data, item.Comment, item.Raw)
    Return $$$OK
}

}
