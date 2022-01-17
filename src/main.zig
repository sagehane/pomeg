const std = @import("std");

const Save = @import("save.zig").Save;

comptime {
    _ = Save;
}

pub fn main() !void {
    const cwd = std.fs.cwd();

    if (cwd.openFile("gen3.sav", .{})) |save_file| {
        const file_size = (save_file.stat() catch unreachable).size;

        if (file_size != 0x20000) {
            std.debug.print(
                \\The save file must be 128 KiB in size
                \\Found: {} KiB
                \\
            , .{file_size / 0x400});

            return;
        }

        var save_buffer: [0x20000]u8 = undefined;
        _ = try save_file.read(&save_buffer);

        const save = @bitCast(Save, save_buffer);
        switch (save.slot_a.getStatus()) {
            .valid => |count| std.debug.print("Slot A's save count is {}\n", .{count}),
            .invalid => std.debug.print("Slot A was invalid\n", .{}),
            .empty => std.debug.print("Slot A was empty\n", .{}),
        }

        switch (save.slot_b.getStatus()) {
            .valid => |count| std.debug.print("Slot B's save count is {}\n", .{count}),
            .invalid => std.debug.print("Slot B was invalid\n", .{}),
            .empty => std.debug.print("Slot B was empty\n", .{}),
        }
    } else |_| {}

    try cwd.writeFile("simple.sav", &std.mem.toBytes(Save.makeSimple()));
}
