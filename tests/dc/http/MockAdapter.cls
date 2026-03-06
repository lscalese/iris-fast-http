Class tests.dc.http.MockAdapter Extends dc.http.SSEAdapter
{

Property CallCount As %Integer [ InitialExpression = 0 ];

Property LastMessage As dc.http.SSEMessage;

Method OnMessage(pMessage As dc.http.SSEMessage) As %Status
{
    Set ..CallCount = ..CallCount + 1
    Set ..LastMessage = pMessage
    Return $$$OK
}

}
