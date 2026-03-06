Class dc.http.SSEChatConsoleAdapter Extends dc.http.SSEAdapter
{

/// used to append incoming content to the response
Property ContentResponse As %String;

/// contains the last received event chat.completion.chunk message as a dynamic object, which can be useful for accessing additional metadata.
Property LastChunk As %DynamicObject;

Property NewLineAsCRLF As %Boolean [ InitialExpression = 1 ];

Method OnMessage(message As dc.http.SSEMessage) As %Status
{
    For i = 1 : 1 : message.Data.Count() {
        If 'message.IsValidJSONData(message.Data.GetAt(i), .jsonData) || (jsonData.object '= "chat.completion.chunk") {
            Continue
        }
        Set content = jsonData.choices.%Get(0).delta.content
        Set ..ContentResponse = ..ContentResponse _ content
        Set ..LastChunk = jsonData
        If ..NewLineAsCRLF {
            Write $Replace(content, $Char(10), $Char(13, 10))
        } Else {
            Write content
        }
    }
    Return $$$OK
}

/// Return the accumulated content response as a structured message with role and content, to be used in subsequent interactions or for final output.
/// Useful in chat session scenarios where the assistant's response needs to be included in the conversation history for context in future messages.
/// The returned object has the format:
/// {   "role": "assistant", "content": "full accumulated content response" }
Method GetAssistantMessage() As %DynamicObject
{
    Return {
        "role": "assistant",
        "content": (..ContentResponse)
    }
}

Method Reset()
{
    Set ..ContentResponse = ""
    Set ..LastChunk = ""
}

}
