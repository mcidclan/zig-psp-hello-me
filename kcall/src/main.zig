pub export fn module_start(args: c_int, argp: ?*anyopaque) callconv(.c) c_int {
  _ = args;
  _ = argp;
  return 0;
}

pub export fn module_stop() callconv(.c) c_int {
  return 0;
}
