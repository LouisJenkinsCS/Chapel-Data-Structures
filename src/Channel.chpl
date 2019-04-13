
/*
   FIFO channel that can communicate across multiple locales. Data is sent in bulk when
   filled or flushed explicitly. Sending is inherently blocking due to concurrent algorithm
   that ensures that the last task to fill the buffer will handle sending it; senders wait until
   a receiver asks for more or if the Channel is closed.
*/

class ChannelClosedError : Error {
  proc message() {
    return "Attempt to Send/Receive from a Closed Channel!";
  }
}

class ChannelNotPairedError : Error {
  proc message() {
    return "Attempt to Send/Receive from a Non-Paired Channel! Call 'channel.pair' with another channel first!";
  }
}

// Default channel size
config param ChannelDefaultSize = 1024;

class Channel {
  type eltType;

  // Channel we are paired with
  var other : borrowed Channel(eltType);

  // Output buffer that we are writing to. other.inBuf == this.outBuf
  var outBuf : c_ptr(eltType);
  var outBufSize : int(64);
  // Amount of buffer claimed...
  var outBufClaimed : atomic int;
  // Amount of buffer filled...
  var outBufFilled : atomic int;

  // Input buffer that we are reading from. other.outBuf == this.inBuf
  var inBuf : c_ptr(eltType);
  // Amount of data pending, set by 'other'
  var inBufPending : atomic int;

  var closed : atomic bool;
}

proc Channel.init(type eltType, len = 1024) {
  this.eltType = eltType;
  this.outBuf = c_malloc(eltType, len);
  this.outBufSize = len;
}

proc Channel.pair(other : unmanaged Channel) {
  this.other = other;
  this.inBuf = other.outBuf;
  other.inBuf = this.outBuf;
  other.other = _to_unmanaged(this);
}

// Parallel safe...
// I.E: Channel.send(1..1000)
proc Channel.send(elt : eltType, param errorOnClose = false) throws : bool {
  if this.other == nil then throw new owned ChannelNotPairedError();
  if this.closed.read() == true {
    if errorOnClose then throw new owned ChannelClosedError();
    else return false;
  }

  // Fast Path: Attempt to claim a spot in the buffer
  var idx = outBufClaimed.fetchAdd(1);
  label outer while idx >= outBufSize {
    // Slow Path: Loop until we find a spot...
    // Read until the amount of claimed space is less than capacity
    var val = outBufClaimed.read();
    if val < outBufSize {
      idx = outBufClaimed.fetchAdd(1);
      continue;
    }

    chpl_task_yield();
  }

  // Write locally...
  this.outBuf[idx] = elt;

  // Report that we have filled another spot
  var filled = outBufFilled.fetchAdd(1) + 1;
  // If we are the last to fill the buffer, we are in charge of notifying other side that we have finished...
  if filled == outBufSize {
    // Wait for inBufPending to be 0...
    other.inBufPending.waitFor(0);
    other.inBufPending.write(filled);
  }
}

// not thread-safe
// Flushes current outBuf
proc Channel.flush() {
  other.inBufPending.waitFor(0);
  other.inBufPending.write(outBufClaimed.read());
}

// not thread-safe
proc Channel.recv() {
  if this.other == nil then halt("Attempt to receive on a non-paired Channel");

  // Wait for data to be available
  while !isClosed() && inBufPending.read() == 0 do chpl_task_yield();
  const sz = inBufPending.read() : uint(64);
  if sz == 0 {
    var emptyArr : [0..-1] eltType;
    return emptyArr;
  }
  var arr : [0..#sz] eltType;
  // Get input data
  var data = c_ptrTo(arr);
  if other.locale == here {
    c_memcpy(data, this.inBuf, c_sizeof(eltType) * sz);
  } else {
    __primitive("chpl_comm_array_get", data[0], other.locale.id, this.inBuf[0], c_sizeof(eltType) * sz);
  }

  inBufPending.write(0);
  other.outBufFilled.write(0);
  other.outBufClaimed.write(0);
  return arr;
}

// not thread-safe
proc Channel.close() {
  flush();
  closed.write(true);
  other.closed.write(true);
}

proc Channel.isClosed() return closed.read();

