"""Run Lua 5.1 files in an isolated VM without creating a LÖVE window."""
import ctypes
import os
from pathlib import Path

def run(path, prelude=''):
    dll=os.environ.get('LOVE_LUA_DLL',r'C:\Program Files\LOVE\lua51.dll')
    lua=ctypes.CDLL(dll)
    lua.luaL_newstate.restype=ctypes.c_void_p
    for name,args in {'luaL_openlibs':[ctypes.c_void_p], 'luaL_loadfile':[ctypes.c_void_p,ctypes.c_char_p],
                      'luaL_loadstring':[ctypes.c_void_p,ctypes.c_char_p],
                      'lua_pcall':[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int],
                      'lua_tolstring':[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p],
                      'lua_close':[ctypes.c_void_p]}.items():
        getattr(lua,name).argtypes=args
    lua.lua_tolstring.restype=ctypes.c_char_p
    state=lua.luaL_newstate(); lua.luaL_openlibs(state)
    try:
        if prelude:
            error=lua.luaL_loadstring(state,prelude.encode()) or lua.lua_pcall(state,0,0,0)
            if error: raise RuntimeError(lua.lua_tolstring(state,-1,None).decode())
        error=lua.luaL_loadfile(state,str(path).encode()) or lua.lua_pcall(state,0,0,0)
        if error: raise RuntimeError(lua.lua_tolstring(state,-1,None).decode())
    finally: lua.lua_close(state)

if __name__=='__main__':
    import sys
    failed=[]
    for path in (list(map(Path,sys.argv[1:])) or sorted(Path('scripts').glob('verify_*.lua'))):
        try: run(path); print('PASS',path)
        except RuntimeError as error: failed.append(str(path)); print('FAIL',path,error)
    sys.exit(bool(failed))
