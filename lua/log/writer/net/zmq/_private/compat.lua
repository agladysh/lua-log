local function prequire(...) 
  local ok, mod = pcall(require, ...)
  return ok and mod, mod or nil
end

local zmq, zthreads, zpoller
local zstrerror, zassert, ETERM
local zconnect, zbind
local zrecv_all, zrecv

zmq = prequire "lzmq"
if zmq then
  zpoller   = prequire "lzmq.poller"
  zthreads  = prequire "lzmq.threads"
  ETERM     = zmq.errors.ETERM
  zstrerror = zmq.strerror
  zassert   = zmq.assert
  zrecv_all = function(skt)       return skt:recv_all() end
  zconnect  = function(skt, addr) return skt:connect(addr) end
  zbind     = function(skt, addr) return skt:bind(addr) end
else
  zmq       = require "zmq"
  zpoller   = require "zmq.poller"
  zthreads  = prequire "zmq.threads"
  ETERM     = 'closed'
  zstrerror = function(err) return err end
  zassert   = assert
  zrecv_all = function(skt)
    local t = {}
    local r, err = skt:recv()
    if not r then return nil, err end
    table.insert(t,r)
    while skt:rcvmore() == 1 do
      r, err = skt:recv()
      if not r then return nil, err, t end
      table.insert(t,r)
    end 
    return t
  end
  zconnect  = function(skt, addr) 
    if type(addr) == 'table' then
      for i,a in ipairs(addr) do
        local ok, err = skt:connect(a)
        if not ok then return nil, err, i end
      end
      return true
    end
    return skt:connect(addr)
  end
  zbind     = function(skt, addr)
    if type(addr) == 'table' then
      for i,a in ipairs(addr) do
        local ok, err = skt:bind(a)
        if not ok then return nil, err, i end
      end
      return true
    end
    return skt:bind(addr)
  end
end

zrecv = function(skt)
  local ok, err, t = zrecv_all(skt)
  if not ok then 
    if t and t[1] then return t[1] end
    return nil, err
  end
  return ok[1]
end

return {
  zmq      = zmq;
  threads  = zthreads;
  poller   = zpoller;
  connect  = zconnect;
  bind     = zbind;
  recv_all = zrecv_all;
  recv     = zrecv;
  strerror = zstrerror;
  assert   = zassert;
  ETERM    = ETERM;
}