# Les Server-Sent Events avec ObjectScript : résoudre le problème de buffer du Web Gateway

[#InterSystems IRIS](https://community.intersystems.com/tags/intersystems-iris)

## Introduction

Dans l'article précédent, nous avons vu comment consommer des Server-Sent Events (SSE) lorsqu'ObjectScript joue le rôle de client.

Suite à une discussion avec Jochen, une question naturelle s'est posée : comment envoyer des Server-Sent Events depuis une page web lorsqu'ObjectScript joue le rôle de serveur ?

Dans cet article, je vais vous montrer comment mettre en place un service REST capable d'envoyer des événements SSE et de contrôler précisément quand les données sont transmises au client, en contournant le buffer du Web Gateway.

---

## Le format SSE

Avant d'entrer dans le code, un petit rappel de ce à quoi ressemble un flux SSE au niveau du protocole. Un événement SSE est simplement du texte brut structuré en champs, séparés par un double saut de ligne :

```
data: {"id":"...","choices":[{"delta":{"content":"Hel"}}]}

data: {"id":"...","choices":[{"delta":{"content":"lo"}}]}

event: done
data: [DONE]

```

Le protocole définit quatre champs :

- `data:` — le contenu de l'événement (peut être du texte brut, du JSON, etc.)
- `event:` — le type d'événement (optionnel, `message` par défaut)
- `id:` — un identifiant unique (optionnel, utilisé pour la reprise de connexion)
- `retry:` — le délai en millisecondes avant reconnexion automatique du client (optionnel)

Un événement peut s'étendre sur plusieurs lignes `data:`, elles seront concaténées par le client. Le double saut de ligne `\n\n` marque la fin d'un événement — c'est pourquoi vous retrouvez `$Char(10,10)` dans les exemples ObjectScript.

---

## Le problème

Dans un service REST, lorsque vous écrivez des données, par exemple :

```objectscript
Write "data: ", {"id":"...","choices":[{"delta":{"content":"Hel"}}]}.%ToJSON(), $Char(10,10)
```

Les données ne sont pas envoyées immédiatement au client. Elles sont placées dans un buffer, et le Web Gateway ne les transmettra que lorsque ce buffer aura atteint une certaine taille.

C'est un problème majeur pour le SSE, car nous avons besoin d'envoyer les données au client dès qu'un événement est prêt, et non lorsque le buffer est plein.

---

## La solution

La solution est simple : configurer correctement l'objet `%response` (voir la documentation [%CSP.Response](https://docs.intersystems.com/irislatest/csp/documatic/%25CSP.Documatic.cls?LIBRARY=%25SYS&PRIVATE=1&CLASSNAME=%25CSP.Response#PROPERTY_AllowOutputFlush)).

Au début de votre service, commencez par activer le contrôle manuel du flush :

```objectscript
Set %response.AllowOutputFlush = 1
```

Sans cette propriété, les données écrites sont placées dans un buffer et ne sont envoyées au client que lorsque ce buffer atteint une certaine taille — ce qui rend le streaming impossible.

Définissez ensuite le `Content-Type` approprié pour le SSE :

```objectscript
Set %response.ContentType = "text/event-stream"
```

Enfin, deux headers supplémentaires sont recommandés pour garantir le bon fonctionnement du stream dans tous les environnements :

```objectscript
Do %response.SetHeader("Cache-Control", "no-cache")
Do %response.SetHeader("Connection", "keep-alive")
```

- **`Cache-Control: no-cache`** — empêche les proxies intermédiaires de mettre en cache le stream. Sans ce header, certains proxies peuvent bufferiser les événements avant de les transmettre, annulant l'effet du `Flush()`.
- **`Connection: keep-alive`** — maintient la connexion HTTP ouverte le temps du stream.

> **Note nginx** : si votre instance IRIS est derrière nginx, ajoutez également ce header pour désactiver son buffering interne :
> ```objectscript
> Do %response.SetHeader("X-Accel-Buffering", "no")
> ```

> **Note CSP Gateway** : le CSP Gateway lui-même dispose d'un buffer interne (~4 Ko) et ne transmet les données au navigateur que lorsque ce buffer est plein — même si `Flush()` est appelé. Cela n'affecte pas `curl` (qui lit directement le flux TCP), mais empêche le streaming dans un navigateur pour les événements de petite taille. Pour contourner ce comportement, envoyez un commentaire SSE de remplissage dès le début du stream, avant le premier événement utile :
> ```objectscript
> Write ": ", $Justify("", 4096), $Char(10)
> Do %response.Flush()
> ```
> Un commentaire SSE commence par `:` et est ignoré par le client. Ces 4 Ko saturent le buffer du Gateway, ce qui permet aux `Flush()` suivants d'être transmis immédiatement.

Une fois `%response` configuré, vous contrôlez l'envoi des données en appelant `Flush()` après chaque `Write` :

```objectscript
Write "data: ", {"id":"...","choices":[{"delta":{"content":"Hel"}}]}.%ToJSON(), $Char(10,10)
Do %response.Flush()
```

Chaque appel à `Flush()` force l'envoi immédiat des données au client.

> **Note CSP** : cette approche fonctionne également pour les pages CSP. Dans ce cas, définissez `AllowOutputFlush` dans la méthode `OnPreHTTP()`.

---

## Tester avec curl

La façon la plus rapide de vérifier que votre endpoint SSE fonctionne correctement est d'utiliser `curl` avec le flag `-N` (alias `--no-buffer`), qui désactive le buffering côté curl et affiche les événements au fur et à mesure qu'ils arrivent :

```bash
curl -N http://localhost:42600/csp/demo/sse/test
```

```powershell
curl.exe -N http://localhost:42600/csp/demo/sse/test
```

Si tout est correctement configuré, vous devriez voir les événements s'afficher progressivement dans votre terminal :

```
data: {"id":"...","choices":[{"delta":{"content":"Hel"}}]}

data: {"id":"...","choices":[{"delta":{"content":"lo"}}]}

data: {"id":"...","choices":[{"delta":{"content":" world"}}]}

data: [DONE]
```

Si tous les événements apparaissent d'un seul coup à la fin, c'est le signe que le buffering n'est pas désactivé côté serveur — vérifiez que `AllowOutputFlush = 1` est bien positionné et que `Flush()` est bien appelé après chaque `Write`.

---

## Consommer le SSE depuis JavaScript

### EventSource — requêtes GET

L'API `EventSource` est la façon native de consommer du SSE depuis un navigateur. Elle gère automatiquement la connexion et la reconnexion en cas de coupure :

```javascript
const source = new EventSource("http://localhost:42600/csp/demo/test");

source.onmessage = (event) => {
    if (event.data === "[DONE]") {
        source.close();
        return;
    }
    const data = JSON.parse(event.data);
    console.log(data.choices[0].delta.content);
};

source.onerror = (error) => {
    console.error("Erreur SSE :", error);
    source.close();
};
```

`EventSource` est simple et efficace, mais présente une limitation importante : **il ne supporte que les requêtes GET**. Pour les APIs d'IA qui nécessitent d'envoyer un body (modèle, messages, paramètres), il faut utiliser une autre approche.

---

### fetch + ReadableStream — requêtes POST

Pour les requêtes POST, comme un appel à une API de complétion de texte, on utilise `fetch` combiné à l'API `ReadableStream` :

```javascript
const response = await fetch("http://localhost:42600/api/v1/chat/completions", {
    method: "POST",
    headers: {
        "Content-Type": "application/json"
    },
    body: JSON.stringify({
        model: "gpt-4o-mini",
        stream: true,
        messages: [{ role: "user", content: "Bonjour !" }]
    })
});

const reader = response.body.getReader();
const decoder = new TextDecoder();

while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value, { stream: true });
    for (const line of chunk.split("\n")) {
        if (!line.startsWith("data: ")) continue;
        const data = line.slice(6).trim();
        if (data === "[DONE]") break;
        const parsed = JSON.parse(data);
        console.log(parsed.choices[0].delta.content);
    }
}
```

Cette approche est plus verbeuse qu'`EventSource`, mais elle offre un contrôle total sur la requête et supporte les POST — ce qui en fait la solution privilégiée pour les AI APIs.

---

### Événements nommés

Le protocole SSE permet de distinguer plusieurs types d'événements grâce au champ `event:`. Côté ObjectScript, vous pouvez envoyer des événements nommés comme suit :

```objectscript
// Un token de texte
Write "event: token", $Char(10)
Write "data: ", {"content": "Bonjour"}.%ToJSON(), $Char(10,10)
Do %response.Flush()

// Signal de fin de stream
Write "event: done", $Char(10)
Write "data: [DONE]", $Char(10,10)
Do %response.Flush()
```

Côté JavaScript, `EventSource` permet d'écouter chaque type d'événement séparément via `addEventListener` :

```javascript
const source = new EventSource("http://localhost:42600/api/sse/test");

source.addEventListener("token", (event) => {
    const data = JSON.parse(event.data);
    console.log("Token reçu :", data.content);
});

source.addEventListener("done", () => {
    console.log("Stream terminé");
    source.close();
});
```

> **Note** : `addEventListener` ne fonctionne qu'avec `EventSource`. Avec `fetch` + `ReadableStream`, il faut parser le champ `event:` manuellement depuis les lignes du chunk.

---

## Passthrough avec fast-http

Depuis la version 1.2.4, [fast-http](https://openexchange.intersystems.com/package/fast-http) inclut un adaptateur passthrough.
Cela permet de retransmettre les événements entrants sans aucune transformation.
Dans cet exemple, nous appelons simplement l'API OpenAI et redirigeons le flux tel quel à travers le Web Gateway :

```objectscript
Include FastHTTP

Class dc.http.DemoREST Extends %CSP.REST
{

Parameter CHARSET = "utf-8";

Parameter CONVERTINPUTSTREAM = 1;

Parameter IgnoreWrites = 0;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/test" Method="GET" Call="Test"/>
    <Route Url="/v1/chat/completions" Method="POST" Call="ChatCompletions"/>
</Routes>
}

ClassMethod Test()
{
    Write $ZVersion
    Return $$$OK
}

ClassMethod ChatCompletions() As %Status
{
    Set %response.AllowOutputFlush = 1
    Set %response.ContentType = "text/event-stream"

    Set message = {}.%FromJSON(%request.Content)
    Set apiKey = $Get(^APIKey) ; votre clé API ici

    Set url = "https://api.openai.com/v1/chat/completions"
    Set config = $$$f("url={url},header_Authorization=Bearer {apiKey}")

    Set responseStream = ##class(dc.http.SSEPassthroughAdapter).GetStream()
    Set handler = responseStream.SSEHandler
    Set handler.SwitchIOOnMessage = 1
    Set handler.IO = $IO

    Set response = ##class(dc.http.FastHTTP).DirectPost(config, message, .client, responseStream)
    If response.statusCode '= 200 {
        Throw ##class(%Exception.General).%New("Chat completion request failed",,,response.%ToJSON())
    }
    Return $$$OK
}

}
```

Un exemple complet, incluant une page de chat de démonstration, est disponible dans la branche `csp-test-1` du dépôt fast-http.
Pour l'essayer :

```bash
git clone -b csp-test-1 https://github.com/lscalese/iris-fast-http.git
cd iris-fast-http
docker compose build --no-cache
docker compose up -d
```

Pour utiliser l'API OpenAI, configurez votre clé API dans l'instance IRIS :

```objectscript
Set ^APIKey = "sk-..." ; votre clé API OpenAI
```

Vous pouvez ensuite accéder à l'interface de chat de démonstration à l'adresse :
http://localhost:42600/csp/ui/demo/chat.html

---

## Que se passe-t-il quand le client se déconnecte ?

C'est une question légitime : si le navigateur ferme la connexion en cours de stream, que se passe-t-il côté IRIS ?

La réponse courte est qu'**IRIS ne reçoit pas de signal immédiat**. Le process ObjectScript continue à exécuter son code — les `Write` et `Flush()` s'enchaînent normalement — jusqu'à ce que le Web Gateway détecte la coupure et propage l'erreur. À ce moment-là, le `Flush()` lèvera une exception `<WRITE>` que vous pouvez intercepter :

```objectscript
ClassMethod Stream() As %Status
{
    Set %response.AllowOutputFlush = 1
    Set %response.ContentType = "text/event-stream"
    Do %response.SetHeader("Cache-Control", "no-cache")
    Do %response.SetHeader("Connection", "keep-alive")

    For i = 1:1:100 {
        Try {
            Write "data: ", {"token": i}.%ToJSON(), $Char(10,10)
            Do %response.Flush()
            Hang 1
        } Catch ex {
            // Le client s'est déconnecté
            Quit
        }
    }
    Return $$$OK
}
```

En pratique, le délai entre la déconnexion réelle du client et la détection côté IRIS dépend de la configuration du Web Gateway et du système d'exploitation. Le délai peut donc varier.

> **Bonne pratique** : encapsulez toujours votre boucle de streaming dans un `Try/Catch` pour libérer proprement les ressources (connexions, locks, globals temporaires) en cas de déconnexion inattendue.

---

## Conclusion

En combinant `AllowOutputFlush`, `Content-Type: text/event-stream` et `%response.Flush()`, ObjectScript dispose de tout ce qu'il faut pour implémenter un serveur SSE fonctionnel.

Pour résumer les points clés :

- Activez `AllowOutputFlush = 1` et appelez `Flush()` après chaque événement
- Ajoutez les headers `Cache-Control: no-cache` et `Connection: keep-alive` — et `X-Accel-Buffering: no` si vous êtes derrière nginx
- Utilisez `EventSource` pour les GET simples, `fetch` + `ReadableStream` pour les POST
- Encapsulez votre boucle dans un `Try/Catch` pour gérer proprement la déconnexion client
- Pour un passthrough vers une AI API, l'adaptateur `SSEPassthroughAdapter` de fast-http fait le travail en quelques lignes

Un exemple complet avec une page de chat est disponible sur le dépôt GitHub fast-http, branche `csp-test-1`.

Merci à Jochen pour sa question pertinente — elle a conduit à approfondir ce sujet.