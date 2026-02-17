# FastHTTP : Simplifiez vos requêtes HTTP en ObjectScript

## Introduction

La bibliothèque standard `%Net.HttpRequest` d'InterSystems IRIS est puissante et complète, mais elle peut s'avérer verbeuse pour des opérations simples. Écrire une requête HTTP nécessite souvent plusieurs lignes de code pour instancier la classe, configurer le serveur, le port, le HTTPS, ajouter des en-têtes, et enfin envoyer la requête.  

Lors de tests en terminal, cette configuration devient vite trop lourde, et se termine généralement par la création de méthodes temporaires...

**FastHTTP** a été conçue pour répondre à ce besoin. Cette classe utilitaire propose une interface fluide et concise permettant d’effectuer des appels HTTP en une seule ligne, tout en gérant automatiquement la complexité sous-jacente (SSL/TLS, parsing d’URL, encodage JSON, headers, etc.).  

Bien sûr, elle est moins complète que `%Net.HttpRequest`, son objectif est de simplifier les cas d’usage courants.  

## Architecture et Conception

La classe `dc.http.FastHTTP` est une surcouche (wrapper) autour de `%Net.HttpRequest`. Ses principes clés sont :

1. **Configuration par chaîne de caractères** : Au lieu de définir chaque propriété individuellement, vous passez une seule chaîne de configuration (ex: `"url=https://api.com,header_Auth=xyz"`).
2. **ClassMethod "Direct"** : Des méthodes de classe (`DirectGet`, `DirectPost`, etc.) permettent d'instancier, configurer et exécuter la requête en une seule ligne commande.
3. **Gestion automatique du SSL** : FastHTTP détecte le protocole HTTPS et crée/applique automatiquement une configuration SSL par défaut si nécessaire.
4. **Support JSON natif** : Les corps de requête sont automatiquement traités "Content-Type=application/json" s'ils sont de type `%DynamicObject`.

## Exemples Concrets

Voici comment utiliser FastHTTP pour les opérations les plus courantes.

### 1. Requête GET simple

Pour récupérer des données depuis une API REST :

```objectscript
// Appel GET simple vers une URL
Set response = ##class(dc.http.FastHTTP).DirectGet("url=https://jsonplaceholder.typicode.com/posts/1")

// La réponse est automatiquement un %DynamicObject
Write "Titre : ", response.title, !
```

### 2. Requête POST avec JSON

Pour envoyer des données JSON :

```objectscript
Set payload = {"title": "foo", "body": "bar", "userId": 1}

// Envoi du POST
// Notez l'ajout rapide de Headers via "header_NomeHeader=Valeur"
Set response = ##class(dc.http.FastHTTP).DirectPost("url=https://jsonplaceholder.typicode.com/posts,header_Authorization=Bearer TOKEN123", payload)

Write "ID créé : ", response.id, !
```

### 3. Requêtes PUT et DELETE

La syntaxe reste identique pour les autres verbes HTTP :

```objectscript
// PUT : Mise à jour
Set updateData = {"id": 1, "title": "Updated Title"}
Set respPut = ##class(dc.http.FastHTTP).DirectPut("url=https://jsonplaceholder.typicode.com/posts/1", updateData)

// DELETE : Suppression
Set respDel = ##class(dc.http.FastHTTP).DirectDelete("url=https://jsonplaceholder.typicode.com/posts/1")
```

### 4. Récupérer l'instance client

Si vous avez besoin d’accéder aux détails techniques (code de statut, headers de réponse), vous pouvez récupérer l’instance `FastHTTP` en passant une variable par référence en dernier paramètre:  

```objectscript
Set response = ##class(dc.http.FastHTTP).DirectGet("url=https://httpbin.org/get",,.client)

// client.HttpRequest est l'objet %Net.HttpRequest sous-jacent
Write "Status Code: ", client.HttpRequest.HttpResponse.StatusCode, !
```

Cela fonctionne pour toutes les méthodes `Direct<VERB>`.  

## Comparaison avec %Net.HttpRequest

### Avec %Net.HttpRequest

```objectscript
Set req = ##class(%Net.HttpRequest).%New()
Set req.Server = "api.example.com"
Set req.Https = 1
Set req.SSLConfiguration = "DefaultSSL" // Doit exister ou être créée manuellement
Do req.SetHeader("Authorization", "Bearer mytoken")
Do req.SetHeader("Content-Type", "application/json")

Set body = {"name": "Test"}
Do body.%ToJSON(req.EntityBody)

Set sc = req.Post("/v1/resource")
If $$$ISERR(sc) { /* Gestion erreur */ }

// Parsing de la réponse
Set jsonResponse = {}.%FromJSON(req.HttpResponse.Data)
```

### Avec FastHTTP

```objectscript
Set body = {"name": "Test"}
Set response = ##class(dc.http.FastHTTP).DirectPost("url=https://api.example.com/v1/resource,header_Authorization=Bearer mytoken", body)
```

FastHTTP:  
 1. Ajoute automatiquement le header `Content-Type=application/json` si le corps est un `%DynamicObject`.  
 2. utilise `SSLConfiguration=DefaultSSL` et crée la configuration si elle n’existe pas.  

La chaîne de configuration permet de définir automatiquement toute propriété de `%Net.HttpRequest` sous la forme `"Property=value"` ou request header avec le prefix `header_`, ex:  

```
"SSLConfiguration=MySSLConfig,header_Content-Type=application/json"
```

## La macro `$$$f`

Pour rendre la construction des chaînes de configuration encore plus dynamique, le projet introduit une macro utilitaire `$$$f`.

### Rôle et Fonctionnement

La macro `$$$f` (pour "format" ou "f-string") permet l'interpolation de variables directement dans une chaîne de caractères.  Pour les deveveloppeur Python vous l'aurez remarqué, elle s'inspire des f-strings.

Elle transforme une chaîne comme `"url={monUrl}"` en une expression ObjectScript valide `"url="_monUrl`.

**Définition technique :**
```objectscript
#define f(%x)  ##function($replace($replace(##quote(%x),"{","""_"),"}","_"""))
```

### Exemple d'utilisation

Sans `$$$f`, la concaténation de variables dans la configuration donne :

```objectscript
Set baseUrl = "https://api.example.com"
Set token = "xyz123"
Set config = "url=" _ baseUrl _ "/users,header_Authorization=Bearer " _ token
Set resp = ##class(dc.http.FastHTTP).DirectGet(config)
```

Avec `$$$f`, le code devient beaucoup plus lisible :

```objectscript
// Assurez-vous que la macro est définie ou incluse
Set resp = ##class(dc.http.FastHTTP).DirectGet($$$f("url={baseUrl}/users,header_Authorization=Bearer {token}"))
```

### Pourquoi cette macro ?

Elle a été introduite pour maintenir la philosophie de "configuration en une ligne" de FastHTTP, même lorsque les valeurs (URLs, tokens) proviennent de variables, propriété objet ou même de méthode. Elle évite une multitude de guillemets typique de la concaténation.  En tant que macro, elle n’est pas directement utilisable en terminal, mais elle reste très pratique en développement.  N'hésitez pas à la copier dans votre ".inc" personnel.  Une version équivalente fournie nativement par IRIS serait d’ailleurs très appréciable.  

## Sources

Tout est disponible sur le GitHub [iris-fast-http](https://github.com/lscalese/iris-fast-http) ou via `zpm "fast-http"`.  

## Conclusion

FastHTTP est une abstraction légère qui modernise l'expérience développeur pour les interactions HTTP dans IRIS. En combinant une API fluide, une configuration textuelle et des aides syntaxiques avec la macro `$$$f`, elle permet de se concentrer sur la logique métier plutôt que sur la "plomberie réseau".  Destinés aux développeurs ObjectScript cherchant à intégrer rapidement des API REST.  

