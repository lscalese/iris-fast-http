ROUTINE FastHTTP [Type=INC]
#; 
#define f(%x)       ##function($replace($replace(##quote(%x),"{","""_"),"}","_"""))
#define fe(%x)      ##function($replace($replace(##quote(%x),"{","""_$replace($replace("),"}",",""\"",""\\""),"","",""\,"")_"""))

#Def1Arg post(%x)   ##class(dc.http.FastHTTP).DirectPost(%x)
#Def1Arg get(%x)    ##class(dc.http.FastHTTP).DirectGet(%x)
#Def1Arg put(%x)    ##class(dc.http.FastHTTP).DirectPut(%x)
#Def1Arg delete(%x) ##class(dc.http.FastHTTP).DirectDelete(%x)