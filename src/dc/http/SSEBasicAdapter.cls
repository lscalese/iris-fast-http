/// Basic implementation of the SSEAdapter, which simply writes the message to the current device
/// This is used for testing and demonstration purposes.
Class dc.http.SSEBasicAdapter Extends dc.http.SSEAdapter
{

Method OnMessage(message As dc.http.SSEMessage) As %Status
{
    Write "Event Name: ", message.EventName, !
    Write "Data: ", message.Data, !
    Write "Comment: ", message.Comment, !
    Write "Raw: ", message.Raw, !
    Return $$$OK
}

}
