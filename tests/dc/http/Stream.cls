Class tests.dc.http.Stream Extends %UnitTest.TestCase
{

/// Nous devons nous assurer que le Handler (Singleton) est propre et configuré
/// car dc.http.Stream va probablement utiliser GetInstance() en interne.
Method OnBeforeOneTest() As %Status
{
    Kill %zSSEHandler
    Set handler = ##class(dc.http.SSEHandler).SetAndGetNewInstance()
    Set mock = ##class(tests.dc.http.MockAdapter).%New()
    Set handler.Adapter = mock
    // On désactive le changement d'IO pour ne pas perturber le test runner
    Set handler.SwitchIOOnMessage = 0 
    Return $$$OK
}

Method OnAfterOneTest() As %Status
{
    Kill %zSSEHandler
    Return $$$OK
}

/// Test de base : Un message coupé en deux Write successifs
Method TestWritePartialMessage()
{
    Set stream = ##class(dc.http.Stream).%New()
    Set handler = ##class(dc.http.SSEHandler).GetInstance()
    Set mock = handler.Adapter

    // 1. Premier Write : Début du message (pas de fin de ligne)
    Do stream.Write("data: Hello")
    
    // Le mock ne doit pas encore avoir été déclenché
    Do $$$AssertEquals(mock.CallCount, 0, "Aucun message ne doit être traité tant que le bloc n'est pas fini")
    
    // 2. Second Write : Fin du message avec double saut de ligne standard
    Do stream.Write(" World" _ $Char(10,10))
    
    // Maintenant le message doit être passé
    Do $$$AssertEquals(mock.CallCount, 1, "L'adapter doit être déclenché après le double saut de ligne")
    Do $$$AssertEquals(mock.LastMessage.Data.GetAt(1), "Hello World", "Le message doit être correctement reconstitué")
}

/// Test : Coupure vicieuse "au milieu" du séparateur de fin
/// Cas critique pour les buffers : "data: ... \n" puis "\n"
Method TestWriteSplitInternalSeparator()
{
    Set stream = ##class(dc.http.Stream).%New()
    Set mock = ##class(dc.http.SSEHandler).GetInstance().Adapter

    // Envoi de la donnée et du PREMIER saut de ligne
    Do stream.Write("data: split case" _ $Char(10))
    
    Do $$$AssertEquals(mock.CallCount, 0, "Ne pas déclencher sur un seul saut de ligne")
    
    // Envoi du SECOND saut de ligne seul
    Do stream.Write($Char(10))
    
    Do $$$AssertEquals(mock.CallCount, 1, "Doit déclencher quand le 2ème saut de ligne arrive")
    Do $$$AssertEquals(mock.LastMessage.Data.GetAt(1), "split case")
}

/// Test : Gestion des fin de lignes Windows (\r\n) fragmentées
Method TestWriteWindowsCRLF()
{
    Set stream = ##class(dc.http.Stream).%New()
    Set mock = ##class(dc.http.SSEHandler).GetInstance().Adapter
    
    // Simulation : "data: win\r\n\r\n" coupé n'importe comment
    
    // 1. "data: wi"
    Do stream.Write("data: wi")
    
    // 2. "n\r" (On s'arrête juste avant le \n)
    Do stream.Write("n" _ $Char(13))
    
    // 3. "\n\r" (On complète le premier CRLF, on entame le 2ème)
    Do stream.Write($Char(10) _ $Char(13))
    
    Do $$$AssertEquals(mock.CallCount, 0, "Toujours pas fini (manque le dernier \n)")
    
    // 4. "\n" (Le caractère final)
    Do stream.Write($Char(10))
    
    Do $$$AssertEquals(mock.CallCount, 1, "Message Windows détecté et reconstitué")
    
    // Vérification du contenu (en supposant que votre Stream ou Handler nettoie les \r)
    // Si votre code garde les \r dans la data, il faudrait adapter l'assertion : "win"_$c(13)
    Set data = mock.LastMessage.Data.GetAt(1)
    Set cleanData = $Replace(data, $Char(13), "") // Juste pour être sûr que le texte est bon
    Do $$$AssertEquals(cleanData, "win")
}

/// Test : Flux continu (Streaming) avec plusieurs messages dans plein de petits Writes
Method TestContinuousStream()
{
    Set stream = ##class(dc.http.Stream).%New()
    Set mock = ##class(dc.http.SSEHandler).GetInstance().Adapter
    
    // On simule un flux type ChatGPT reçu octet par octet ou presque
    // Message 1: "data: A"
    // Message 2: "data: B"
    
    Do stream.Write("data: ")
    Do stream.Write("A")
    Do stream.Write($Char(10))
    Do stream.Write($Char(10)) // Fin msg 1
    
    Do $$$AssertEquals(mock.CallCount, 1, "Premier message reçu")
    Do $$$AssertEquals(mock.LastMessage.Data.GetAt(1), "A")
    
    Do stream.Write("da")
    Do stream.Write("ta: B")
    Do stream.Write($Char(10))
    Do stream.Write($Char(10)) // Fin msg 2
    
    Do $$$AssertEquals(mock.CallCount, 2, "Deuxième message reçu")
    Do $$$AssertEquals(mock.LastMessage.Data.GetAt(1), "B")
}

}
