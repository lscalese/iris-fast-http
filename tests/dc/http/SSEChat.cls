Class tests.dc.http.SSEChat Extends %UnitTest.TestCase
{

Method TestChatCompletionChunk()
{
    Set splitMessage = $lb("Hi,","How","can","I","help","you","today?")
    // The loop adds a space after each chunk, so we expect this result:
    Set expectedText = "Hi, How can I help you today? " 

    Set handler = ##class(dc.http.SSEHandler).SetAndGetNewInstance()
    Set adapter = ##class(dc.http.SSEChatConsoleAdapter).%New()
    
    Set handler.Adapter = adapter
    Set handler.SwitchIOOnMessage = 0 // Don't switch IO automatically, we control it

    Set ptr = 0, io = $IO, tempFile = ##class(%File).TempFilename("log")
    
    // Open temp file to capture Write output from adapter
    Open tempFile:("NWS")
    Use tempFile
    Try {
        While $ListNext(splitMessage, ptr, toChunk) {
            Set chunkMessage = {
                "choices": [
                    {
                        "delta": {
                            "content": (toChunk_" ")
                        }
                    }
                ],
                "object": "chat.completion.chunk"
            }
            // Construct a proper SSE message string
            Set rawSSE = "data: "_chunkMessage.%ToJSON()_$Char(10,10)
            
            // Process the SSE stream chunk via the handler
            Do handler.Process(rawSSE)
        }
    }
    Catch ex {
        Use io
        Close tempFile
        Do ##class(%File).Delete(tempFile)
        Throw ex
    }
    Use io
    Close tempFile
    

    // Read the File content to verify what was printed
    Set file = ##class(%Stream.FileCharacter).%New()
    Do file.LinkToFile(tempFile)
    Set fileContent = file.Read()
    Kill file
    Do ##class(%File).Delete(tempFile)

    Do $$$AssertEquals(fileContent, expectedText, "Captured console output mismatch")

    // Verify adapter internal state
    Do $$$AssertEquals(adapter.ContentResponse, expectedText, "Adapter ContentResponse property mismatch")
    
    // Verify Assistant Message helper
    Set assistantMsg = adapter.GetAssistantMessage()
    Do $$$AssertEquals(assistantMsg.role, "assistant", "Assistant message role should be 'assistant'")
    Do $$$AssertEquals(assistantMsg.content, expectedText, "Assistant message content match")

    // Verify Reset works
    Do adapter.Reset()
    Do $$$AssertEquals(adapter.ContentResponse, "", "Adapter ContentResponse should be empty after reset")
    Do $$$AssertEquals(adapter.LastChunk.%ToJSON(), "{}", "Adapter LastChunk should be empty after reset")
}

}
