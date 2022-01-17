const std = @import("std");
const testing = std.testing;

const Sector = @import("save/sector.zig").Sector;
const Slot = @import("save/slot.zig").Slot;

pub const Save = packed struct {
    // A save must be 128 KiB in size.
    comptime {
        std.debug.assert(@sizeOf(Save) == 0x20000);
    }

    // Offset: 0x00000
    slot_a: Slot,

    // Offset: 0x0E000
    slot_b: Slot,

    // TODO: Find a better way to represent this data later.
    // This entire field can be 0, and the save is considered valid.
    //
    // Offset: 0x1C000
    other: [4]Sector,

    pub fn makeSimplest() Save {
        const array: [0x20000]u8 = std.mem.toBytes(Slot.makeSimplest()) ++
            ([1]u8{0} ** (@sizeOf(Save) - @sizeOf(Slot)));

        return @bitCast(Save, array);
    }
};
