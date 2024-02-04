import Dispatch
import Foundation

var registeredPids = [pid_t: Int32]()
var exitSemaphores = [pid_t: DispatchSemaphore]()  // Semaphore map to track exit signals
var latestPid: pid_t?  // Track the latest registered PID

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
  latestPid = pid  // Update latest PID
  let semaphore = DispatchSemaphore(value: 0)
  exitSemaphores[pid] = semaphore

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

        semaphore.signal()

        registeredPids.removeValue(forKey: pid)
        exitSemaphores.removeValue(forKey: pid)
        if latestPid == pid {
          latestPid = nil  // Reset latest PID if it's the one being removed
        }
        close(procKqueue)
        break
      } else {
        logger.log("Error reading kevent")
        break
      }
    }
  }
}

func waitForExit() {
    if let pid = latestPid, let semaphore = exitSemaphores[pid] {
        // Set a timeout for 10 seconds from now
        let timeout = DispatchTime.now() + .seconds(10)
        let result = semaphore.wait(timeout: timeout)

        switch result {
        case .success:
            logger.log("Process \(pid) exited within 10 seconds.")
        case .timedOut:
            logger.log("Timeout: Process \(pid) did not exit within 10 seconds.")
        }
    } else {
        logger.log("No process to wait for")
    }
}
