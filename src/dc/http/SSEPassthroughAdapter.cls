Class dc.http.SSEPassthroughAdapter Extends dc.http.SSEAdapter
{

/// write the item without any processing.
/// If it's CSP/REST context the resposne can be flushed immediately, but
/// you have to setup :
/// Set %response.AllowOutputFlush = 1
/// in you REST service before.
Method OnMessage(item As dc.http.SSEMessage) As %Status
{
    Write item.Raw
    If $IsObject($Get(%response)) {
        Do %response.Flush()
    }
    Return $$$OK
}

}
