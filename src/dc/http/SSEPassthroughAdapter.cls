Class dc.http.SSEPassthroughAdapter Extends dc.http.SSEAdapter
{

Method OnMessage(item As dc.http.SSEMessage) As %Status
{
    Write item.Raw
    If $IsObject($Get(%response)) {
        Do %response.Flush()
    }
    Return $$$OK
}

}
