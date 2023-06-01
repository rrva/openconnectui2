import Foundation

import Dispatch

var registeredPids = [pid_t: Int32]()

func noteExit(pid: pid_t, onExit: @escaping () -> Void) {
  logger.log("Registering exit hook for pid \(pid)")
  if registeredPids.keys.contains(pid) {
    logger.log("Exit hook already registered for pid \(pid)")
    return
  }

  let procKqueue = kqueue()
  if procKqueue == -1 {
    logger.log("Error creating kqueue")
    return
  }

  var changes = kevent(
    ident: UInt(pid),
    filter: Int16(EVFILT_PROC),
    flags: UInt16(EV_ADD | EV_RECEIPT),
    fflags: NOTE_EXIT,
    data: 0,
    udata: nil
  )
  if kevent(procKqueue, &changes, 1, nil, 0, nil) == -1 {
    logger.log("Error adding kevent for pid \(pid)")
    close(procKqueue)
    return
  }

  registeredPids[pid] = procKqueue

  DispatchQueue.global(qos: .default).async {
    var exitSignalled = false
    while true {
      var event = kevent()
      let status = kevent(procKqueue, nil, 0, &event, 1, nil)
      if status == 0 {
        logger.log("Timeout")
      } else if status > 0 && !exitSignalled {
        exitSignalled = true
        logger.log("OpenConnect exited")
        onExit()

        registeredPids[pid] = nil
        close(procKqueue)
        break
      } else {
        logger.log("Error reading kevent")
        break
      }
    }
  }
}
