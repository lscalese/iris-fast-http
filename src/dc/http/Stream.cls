/// Stream used to handle stream mode response
Class dc.http.Stream Extends %Stream.GlobalBinary
{

Property ResourceId As %String;

Property CallBackClass As %String;

Property CallBackMethod As %String;

Method Write(data As %String = "") As %Status
{
    Do ..NotifyObserver(data)
    Return ##super(data)
}

Method WriteLine(data As %String = "") As %Status
{
    Do ..NotifyObserver(data)
    Return ##super(data)
}

Method NotifyObserver(data As %String = "") As %Status
{
    Do:..ResourceId'="" $SYSTEM.Event.Signal(..ResourceId, $ZConvert(data, "I", "UTF8"))
    If ..CallBackClass'="", ..CallBackMethod'="" {
        Do $CLASSMETHOD(..CallBackClass, ..CallBackMethod, $ZConvert(data, "I", "UTF8"))
    }
    Return $$$OK
}

}
