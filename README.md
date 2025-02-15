## Wiredtiger-Zig

An experimental Zig wrapper for the WiredTiger database library.

### Usage

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