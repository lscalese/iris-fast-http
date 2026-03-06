/// Basic implementation of the SSEAdapter, which simply writes the message to the current device
/// This is used for testing and demonstration purposes.
Class dc.http.SSEBasicAdapter Extends dc.http.SSEAdapter
{

Method OnMessage(message As dc.http.SSEMessage) As %Status
{
    Write "Raw message: ", message.Raw, !
    Write "Event: ", message.Event, !
    Write "ID: ", message.Id, !
    Write "Retry: ", message.Retry, !
    For i = 1 : 1 : message.Data.Count() {
        Write "Data line ", i, ": ", message.Data.GetAt(i), !
    }
    Return $$$OK
}

}
