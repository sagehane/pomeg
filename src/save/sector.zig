const std = @import("std");
const testing = std.testing;

pub const Sector = packed struct {
    // Sectors are 4KiB in size.
    comptime {
        std.debug.assert(@sizeOf(Sector) == 0x1000);
    }

    // The relevant size of this data depends on the id, and can range from 2000 to 3968 bytes. The rest
    // is just padding.
    data: [0xF80]u8,

    // Unused data for padding.
    //
    // Offset: 0xF80
    _: [0x074]u8,

    // Specifies the data and size.
    //
    // Offset: 0xFF4
    id: u16,

    // Stores the checksum value derived from the data, and is compared to see if the save is valid.
    //
    // Offset: 0xFF6
    checksum: u16,

    // Should be the magic number of 0x08012025. If not, the save isn't considered valid.
    //
    // Offset: 0xFF8
    security: u32,

    // Represents the number of times the game has been saved. Interestingly, this number doesn't
    // have to be the same for all sectors in a slot. If both slots are valid, the slot with the
    // higher counter is chosen.
    //
    // Offset: 0xFFC
    counter: u32,

    // Magic number. If all sectors in a slot don't match this, the slot is considered empty. If some
    // match but not all, it's considered invalid.
    pub const security_num: u32 = 0x08012025;

    // The size corresponds to the ID.
    const size = [14]u16{
        3884, 3968, 3968, 3968, 3848, 3968, 3968,
        3968, 3968, 3968, 3968, 3968, 3968, 2000,
    };

    pub fn getChecksum(self: Sector) u16 {
        std.debug.assert(self.id < 14);

        return calculateChecksum(self.data[0..size[self.id]]);
    }
};

/// Iterates over a slice as u32 values, get the sum, and returns the sum of the
/// first and last 16 bits as an u16.
fn calculateChecksum(slice: []const u8) u16 {
    std.debug.assert(slice.len % 4 == 0);
    var checksum: u32 = 0;

    var count: u16 = 0;
    while (count < slice.len) : (count += 4) {
        checksum +%= std.mem.readIntSliceLittle(u32, slice[count .. count + 4]);
    }

    return @truncate(u16, (checksum >> 16) +% checksum);
}

test "sample checksum" {
    const array = [_]u8{ 0x20, 0x30, 0x50, 0x10 } ** 0x10;

    const checksum = calculateChecksum(&array);

    try testing.expectEqual(checksum, 1795);
}
