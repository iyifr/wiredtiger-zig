const std = @import("std");
const c = @cImport({
    @cInclude("wiredtiger.h");
});

const DB_CURSOR = struct {
    cursor: ?*c.WT_CURSOR = null,
    table: [*c]const u8,

    fn open(self: *DB_CURSOR, session: ?*c.WT_SESSION, config: [*c]const u8) c_int {
        const ret = (session.?.open_cursor).?(session.?, self.table, null, config orelse null, &self.cursor);
        return ret;
    }

    fn close(self: *DB_CURSOR) void {
        _ = (self.cursor.?.close).?(self.cursor);
    }

    fn setKey(self: *DB_CURSOR, key: [*c]const u8) void {
        _ = (self.cursor.?.set_key).?(self.cursor.?, key);
    }

    fn setValue(self: *DB_CURSOR, value: [*c]const u8) void {
        _ = (self.cursor.?.set_value).?(self.cursor.?, value);
    }

    fn insert(self: *DB_CURSOR) c_int {
        return (self.cursor.?.insert).?(self.cursor.?);
    }

    fn reset(self: *DB_CURSOR) c_int {
        return (self.cursor.?.reset).?(self.cursor.?);
    }

    fn forward_scan(self: *DB_CURSOR, key_ptr: *[*:0]const u8, value_ptr: *[*:0]const u8) bool {
        const ret = (self.cursor.?.next).?(self.cursor);
        if (ret == 0) {
            _ = (self.cursor.?.get_key).?(self.cursor.?, key_ptr);
            _ = (self.cursor.?.get_value).?(self.cursor.?, value_ptr);
            return true;
        }
        return false;
    }

    fn backward_scan(self: *DB_CURSOR, key_ptr: *[*:0]const u8, value_ptr: *[*:0]const u8) bool {
        const ret = (self.cursor.?.prev).?(self.cursor);
        if (ret == 0) {
            _ = (self.cursor.?.get_key).?(self.cursor.?, key_ptr);
            _ = (self.cursor.?.get_value).?(self.cursor.?, value_ptr);
            return true;
        }
        return false;
    }
};

pub fn main() !void {
    var conn: ?*c.WT_CONNECTION = null;
    var session: ?*c.WT_SESSION = null;
    // var cursor: ?*c.WT_CURSOR = null;
    const db_dir = "WT_HOME";

    // Create the database directory if it doesn't exist
    try std.fs.cwd().makePath(db_dir);

    // Open connection
    const ret = c.wiredtiger_open(db_dir, null, "create,statistics=(all)", &conn);
    if (ret != 0) {
        const err = c.wiredtiger_strerror(ret);
        std.debug.print("Connection error: {s}\n", .{err});
        return error.OpenFailed;
    }

    defer {
        _ = (conn.?.close).?(conn.?, null);
    }

    // Open session
    const session_ret = (conn.?.open_session).?(conn.?, null, null, &session);
    if (session_ret != 0) {
        const err = c.wiredtiger_strerror(session_ret);
        std.debug.print("Session error: {s}\n", .{err});
        return error.SessionFailed;
    }

    std.debug.print("Successfully connected to WiredTiger!\n", .{});

    _ = (session.?.create).?(session.?, "table:test_table", "key_format=S,value_format=S");

    var myCursor = DB_CURSOR{
        .table = "table:test_table",
    };

    const cursor_open_ret = myCursor.open(session, null);
    if (cursor_open_ret != 0) {
        const err = c.wiredtiger_strerror(cursor_open_ret);
        std.debug.print("Cursor error: {s}\n", .{err});
        return error.CursorOpenFailed;
    }
    defer myCursor.close();

    myCursor.setKey("keyyyyys");
    myCursor.setValue("value");

    myCursor.setKey("key3");
    myCursor.setValue("value3");
    _ = myCursor.insert();

    const cursor_reset_ret = myCursor.reset();

    if (cursor_reset_ret != 0) {
        const err = c.wiredtiger_strerror(cursor_reset_ret);
        std.debug.print("Cursor error: {s}\n", .{err});
        return error.CursorResetFailed;
    }

    var key: [*:0]const u8 = undefined;
    var value: [*:0]const u8 = undefined;

    while (myCursor.forward_scan(&key, &value)) {
        std.debug.print("Key: {s} | Value: {s}\n", .{ key, value });
        // Process key/value here while they're still valid
    }
}
