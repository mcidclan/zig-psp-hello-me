pub const KFunc = *const fn () callconv(.c) c_int;
pub extern fn kCall(func: KFunc) callconv(.c) void;
