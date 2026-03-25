pub const KFunc = *const fn () callconv(.c) c_int;
pub extern fn kcall(func: KFunc) callconv(.c) void;
