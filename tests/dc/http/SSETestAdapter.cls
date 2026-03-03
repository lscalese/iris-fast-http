/// Basic Server Sent Event handler for unit testing.
Class tests.dc.http.SSETestAdapter Extends dc.http.SSEAdapter
{

Method OnMessage(message As dc.http.SSEMessage) As %Status
{
    Set index = $Increment(^||CallbackData)
    Set ^||CallbackData(index) = $lb(message.EventName, message.Data, message.Comment, message.Raw)
    Return $$$OK
}

}
