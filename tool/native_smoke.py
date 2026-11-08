import ctypes, time, pathlib
lib=ctypes.CDLL(str(pathlib.Path('build/native/libcastlei_engine.so').resolve()))
lib.castlei_create.restype=ctypes.c_void_p
lib.castlei_send.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
lib.castlei_poll.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_int]
lib.castlei_dispose.argtypes=[ctypes.c_void_p]
for run in range(3):
 h=lib.castlei_create();b=ctypes.create_string_buffer(65536)
 def send(s): assert lib.castlei_send(h,s.encode())==0
 def until(prefix,timeout=20):
  start=time.monotonic()
  while time.monotonic()-start<timeout:
   if lib.castlei_poll(h,b,65536)>0:
    s=b.value.decode()
    if s.startswith(prefix): return s
   time.sleep(.01)
  raise AssertionError('Timed out: '+prefix)
 send('uci');until('uciok');send('setoption name Hash value 64');send('isready');until('readyok')
 send('position startpos');send('go movetime 150');print(until('bestmove'))
 send('go infinite');time.sleep(.05);send('stop');until('bestmove')
 lib.castlei_dispose(h)
print('Native handshake, search, stop and repeated disposal passed')
