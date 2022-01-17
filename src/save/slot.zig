const std = @import("std");
const Sector = @import("sector.zig").Sector;

pub const Slot = packed struct {
    // A save slot is comprised of 14 sectors, each 4 KiB, meaning the slot itself is 56 KiB.
    comptime {
        std.debug.assert(@sizeOf(Slot) == 0xE000);
    }

    sectors: [14]Sector,

    /// The game seems to treat the slot as valid even if the counter differs between sectors.
    pub fn getStatus(self: Slot) SlotStatus {
        // Keeps track of whether any of the sectors had the magic number of 0x08012025. If not,
        // the slot is considered empty.
        var security_passed = false;

        // A counter for how many times the game has been saved.
        var counter: u32 = undefined;

        // The corresponding bit of a sector's ID is flipped if the sector passes the security and
        // checksum tests. If all bits are flipped, it means that all sectors are valid, and have
        // an unique ID.
        var sector_flag: u14 = 0;

        for (self.sectors) |sector| {
            if (sector.security == Sector.security_num) {
                security_passed = true;

                // TODO: Check what happens on cartidge when the id is higher than 13.
                if (sector.id < 14 and sector.checksum == sector.getChecksum()) {
                    counter = sector.counter;
                    sector_flag |= @as(u14, 1) << @intCast(u4, sector.id);
                }
            }
        }

        if (security_passed) {
            if (sector_flag == std.math.maxInt(u14))
                return .{ .valid = counter };

            return .invalid;
        }

        return .empty;
    }

    pub fn makeSimple() Slot {
        var array = [1]u8{0} ** @sizeOf(Slot);

        var id: u8 = 0;
        while (id < 14) : (id += 1) {
            const offset = 0x1000 * @as(u16, id);

            // Fill the ID field.
            array[offset + 0xFF4] = id;

            // Set the security field.
            std.mem.copy(u8, array[offset + 0xFF8 .. offset + 0xFFC], &.{ 0x25, 0x20, 0x01, 0x08 });
        }

        return @bitCast(Slot, array);
    }

    test "check simple slot" {
        const slot = Slot.makeSimplest();

        try std.testing.expectEqual(SlotStatus{ .valid = 0 }, slot.getStatus());
    }
};

// TODO: Check for other possible status values.
const SlotStatus = union(enum) {
    empty: void,
    // A "valid" slot is defined as a slot that the game is willing to attempt to load. It does not
    // mean the slot is an authentic save that can be attained without hacking, and running a valid
    // slot can still crash the game.
    //
    // The u32 value represents the save counter of the slot.
    valid: u32,
    invalid: void,
};
