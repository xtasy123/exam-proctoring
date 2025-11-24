"use client"

import { useEffect, useCallback, useState } from "react"
import { useToast } from "@/hooks/use-toast"

interface ProctoringMonitorProps {
  onViolation: (type: string, description: string) => void
  isActive: boolean
}

export function ProctoringMonitor({ onViolation, isActive }: ProctoringMonitorProps) {
  const [lastActivity, setLastActivity] = useState(Date.now())
  const { toast } = useToast()

  const updateActivity = useCallback(() => {
    setLastActivity(Date.now())
  }, [])

  const logViolation = useCallback(
    (type: string, description: string) => {
      onViolation(type, description)

      // In a real application, this would send data to the server
      console.log("Violation detected:", { type, description, timestamp: new Date().toISOString() })
    },
    [onViolation],
  )

  useEffect(() => {
    if (!isActive) return

    const handleVisibilityChange = () => {
      if (document.hidden) {
        logViolation("TAB_SWITCH", "Student switched tabs or minimized window")
      }
    }

    const handleFullscreenChange = () => {
      if (!document.fullscreenElement) {
        logViolation("FULLSCREEN_EXIT", "Student exited fullscreen mode")
      }
    }

    const handleKeyDown = (e: KeyboardEvent) => {
      updateActivity()

      // Block common cheating shortcuts
      if (e.altKey && e.key === "Tab") {
        e.preventDefault()
        logViolation("ALT_TAB", "Student attempted Alt+Tab")
      }

      if (e.ctrlKey && ["t", "n", "w", "r"].includes(e.key)) {
        e.preventDefault()
        logViolation("KEYBOARD_SHORTCUT", `Student attempted to use Ctrl+${e.key.toUpperCase()}`)
      }

      // Block paste operations
      if (e.ctrlKey && e.key === "v") {
        e.preventDefault()
        logViolation("PASTE_ATTEMPT", "Student attempted to paste content (Ctrl+V)")
      }

      // Block copy operations
      if (e.ctrlKey && e.key === "c") {
        e.preventDefault()
        logViolation("COPY_ATTEMPT", "Student attempted to copy content (Ctrl+C)")
      }

      // Block cut operations
      if (e.ctrlKey && e.key === "x") {
        e.preventDefault()
        logViolation("CUT_ATTEMPT", "Student attempted to cut content (Ctrl+X)")
      }

      // Block select all
      if (e.ctrlKey && e.key === "a") {
        e.preventDefault()
        logViolation("SELECT_ALL", "Student attempted to select all content (Ctrl+A)")
      }

      if (e.key === "F12" || (e.ctrlKey && e.shiftKey && e.key === "I")) {
        e.preventDefault()
        logViolation("DEV_TOOLS", "Student attempted to open developer tools")
      }
    }

    const handleContextMenu = (e: MouseEvent) => {
      e.preventDefault()
      logViolation("RIGHT_CLICK", "Student attempted right-click")
    }

    const handleMouseMove = () => {
      updateActivity()
    }

    // Add event listeners
    document.addEventListener("visibilitychange", handleVisibilityChange)
    document.addEventListener("fullscreenchange", handleFullscreenChange)
    document.addEventListener("keydown", handleKeyDown)
    document.addEventListener("contextmenu", handleContextMenu)
    document.addEventListener("mousemove", handleMouseMove)

    // Inactivity check
    const inactivityCheck = setInterval(() => {
      const timeSinceLastActivity = Date.now() - lastActivity
      if (timeSinceLastActivity > 300000) {
        // 5 minutes
        logViolation("INACTIVITY", "Student inactive for more than 5 minutes")
      }
    }, 60000) // Check every minute

    return () => {
      document.removeEventListener("visibilitychange", handleVisibilityChange)
      document.removeEventListener("fullscreenchange", handleFullscreenChange)
      document.removeEventListener("keydown", handleKeyDown)
      document.removeEventListener("contextmenu", handleContextMenu)
      document.removeEventListener("mousemove", handleMouseMove)
      clearInterval(inactivityCheck)
    }
  }, [isActive, lastActivity, logViolation, updateActivity])

  return null // This component doesn't render anything
}
