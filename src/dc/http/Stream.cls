/// Stream used to handle stream mode response
Class dc.http.Stream Extends %Stream.GlobalBinary
{

Method Write(data As %String = "") As %Status
{
    Do ##class(dc.http.SSEHandler).Notify($ZConvert(data, "I", "UTF8"))
    Return ##super(data)
}

Method WriteLine(data As %String = "") As %Status
{
    Do ##class(dc.http.SSEHandler).Notify($ZConvert(data, "I", "UTF8"))
    Return ##super(data)
}

}
