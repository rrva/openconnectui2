import Foundation

func noteExit(pid: pid_t, withReply reply: @escaping (Bool) -> Void) {
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
      logger.log("Error adding kevent")
      close(procKqueue)
      return
  }

  DispatchQueue.global(qos: .default).async {
    while true {
      var event = kevent()
      let status = kevent(procKqueue, nil, 0, &event, 1, nil)
      if status == 0 {
        logger.log("Timeout")
      } else if status > 0 {
        logger.log("OpenConnect exited")
        reply(false)
        break
      } else {
        logger.log("Error reading kevent")
        break
      }
    }
    close(procKqueue)
  }
}
