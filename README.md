## Wiredtiger-Zig

An experimental KV store written in Zig using the WiredTiger storage engine.

(Experimental, in progress)

### Usage

Disclaimer: This is not the current state of the code, just a potential API design.

```zig
const wtdb = @import("wtdb");

const db = wtdb.open("test.wt", .{
    .overwrite = true,
});

const cursor = db.openCursor("test", .{});  

cursor.insert("key", "value");

const value = cursor.search("key");

cursor.close();

db.close();
``` 
