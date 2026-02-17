/// Stream used to handle stream mode response
Class dc.http.Stream Extends %Stream.GlobalBinary
{

Property ResourceId As %String;

Method Write(data As %String = "") As %Status
{
    Do:..ResourceId'="" $SYSTEM.Event.Signal(..ResourceId, data)
    Return ##super(data)
}

Method WriteLine(data As %String = "") As %Status
{
    Do:..ResourceId'="" $SYSTEM.Event.Signal(..ResourceId, data)
    Return ##super(data)
}

}
