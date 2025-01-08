"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[309],{84828:e=>{e.exports=JSON.parse('{"functions":[{"name":"OnClientEvent","desc":"Listens for a client event, and fires the callback with the arguments passed.","params":[{"name":"Callback","desc":"","lua_type":"(Player: Player, ...any) -> nil"}],"returns":[{"desc":"","lua_type":"{ Disconnect: () -> nil }"}],"function_type":"method","realm":["Client"],"source":{"line":60,"path":"src/Client.luau"}},{"name":"Write","desc":"Uses the WriteLib to write data changes, and then replicates the write call to the client along with any information needed to replicate the call.","params":[{"name":"Method","desc":"","lua_type":"string"},{"name":"...","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"any"}],"function_type":"method","realm":["Server"],"source":{"line":32,"path":"src/Server.luau"}},{"name":"GetChildren","desc":"Returns all children of the replica, if the replica is not a parent it will return an empty table.","params":[],"returns":[{"desc":"","lua_type":"{ [string]: Replica }"}],"function_type":"method","source":{"line":48,"path":"src/Server.luau"}},{"name":"OnServerEvent","desc":"Connects a function to the server event, which will be fired when the client sends a request.","params":[{"name":"Callback","desc":"","lua_type":"(Player: Player, ...any) -> nil"}],"returns":[{"desc":"","lua_type":"{ Disconnect: () -> nil }"}],"function_type":"method","realm":["Server"],"source":{"line":68,"path":"src/Server.luau"}},{"name":"Fire","desc":"Sends a request to the client, sending the arguments to the client.","params":[{"name":"...","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":80,"path":"src/Server.luau"}},{"name":"SetParent","desc":"Sets the parent of the replica, and then replicates the change to the client.","params":[{"name":"Parent","desc":"","lua_type":"ServerReplica"}],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","realm":["Server"],"source":{"line":94,"path":"src/Server.luau"}},{"name":"Destroy","desc":"Destroys the replica and cleans up any tasks that were added to the cleaner.\\n[Destroying] will be fired when the replica is destroyed.\\nThis should only ever be intentionally called from the Server.","params":[],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","realm":["Server"],"source":{"line":124,"path":"src/Server.luau"}},{"name":"ListenToWrite","desc":"Connects to the Write event and listens for a specific method to be called. When the method is called, the callback is fired with the arguments passed to the method.","params":[{"name":"Method","desc":"","lua_type":"string"},{"name":"Callback","desc":"","lua_type":"(...any) -> nil"}],"returns":[{"desc":"","lua_type":"RBXScriptConnection"}],"function_type":"method","source":{"line":21,"path":"src/SharedFunctions.luau"}},{"name":"ListenToKeyRemoved","desc":"Connects to the Change event and listens for a specific key to be removed. When the key is removed, the callback is fired with the key and the value of the key before it was removed.","params":[{"name":"Path","desc":"","lua_type":"{ string | number } | string"},{"name":"Callback","desc":"","lua_type":"(...any) -> nil"}],"returns":[{"desc":"","lua_type":"RBXScriptConnection"}],"function_type":"method","source":{"line":31,"path":"src/SharedFunctions.luau"}},{"name":"ListenToNewKey","desc":"Connects to the Change event and listens for a new key to be added. When the key is added, the callback is fired with the key and the value of the key.","params":[{"name":"Path","desc":"","lua_type":"{ string | number } | string"},{"name":"Callback","desc":"","lua_type":"(...any) -> nil"}],"returns":[{"desc":"","lua_type":"RBXScriptConnection"}],"function_type":"method","source":{"line":41,"path":"src/SharedFunctions.luau"}},{"name":"ListenToChange","desc":"Connects to the Change event and listens for a specific key to be changed. When the key is changed, the callback is fired with the new value and the old value.","params":[{"name":"Path","desc":"","lua_type":"{ string | number } | string"},{"name":"Callback","desc":"","lua_type":"(...any) -> nil"},{"name":"SuppressOld","desc":"","lua_type":"boolean?"}],"returns":[{"desc":"","lua_type":"RBXScriptConnection"}],"function_type":"method","source":{"line":52,"path":"src/SharedFunctions.luau"}},{"name":"ListenToRaw","desc":"Connects to the Change event and listens for any key to be changed. When a key is changed, the callback is fired with the path, the new value, and the old value.","params":[{"name":"Callback","desc":"","lua_type":"(...any) -> nil"}],"returns":[{"desc":"","lua_type":"RBXScriptConnection"}],"function_type":"method","source":{"line":61,"path":"src/SharedFunctions.luau"}},{"name":"ObserveChange","desc":"Observes a specific key and fires the callback with the value of the key. The callback is fired immediately and then whenever the key is changed.","params":[{"name":"Path","desc":"","lua_type":"{ string | number } | string"},{"name":"Callback","desc":"","lua_type":"(...any) -> nil"}],"returns":[{"desc":"","lua_type":"RBXScriptConnection"}],"function_type":"method","source":{"line":71,"path":"src/SharedFunctions.luau"}},{"name":"AddCleanupTask","desc":"Adds a task to be cleaned when the replica is destroyed. If a method is provided it\'ll use this method to clean, otherwise it\'ll assume that it is a function or thread (true).","params":[{"name":"Task","desc":"","lua_type":"() -> nil"},{"name":"CleanupMethod","desc":"","lua_type":"string | boolean?"}],"returns":[{"desc":"","lua_type":"nil"}],"function_type":"method","source":{"line":81,"path":"src/SharedFunctions.luau"}}],"properties":[],"types":[],"name":"Replica","desc":"","source":{"line":6,"path":"src/init.luau"}}')}}]);