/// Stream used to handle stream mode response
Class dc.http.Stream Extends %Stream.GlobalBinary
{

Property SSEHandler As dc.http.SSEHandler;

Method Write(data As %String = "") As %Status
{
    Do ..Notify(data)
    Return ##super(data)
}

Method WriteLine(data As %String = "") As %Status
{
    Do ..Notify(data _ ..LineTerminator)
    Return ##super(data)
}

Method Notify(data As %String) As %Status
{
    Return:'$IsObject(..SSEHandler) $$$OK
    Return ..SSEHandler.BufferProcessing($ZConvert(data, "I", "UTF8"))

}
}