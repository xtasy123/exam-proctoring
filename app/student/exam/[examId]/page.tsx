"use client"

import { useState, useEffect, useCallback } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { AlertTriangle, Shield, Clock, Eye } from "lucide-react"
import { useRouter } from "next/navigation"
import { useToast } from "@/hooks/use-toast"

interface Violation {
  type: string
  timestamp: string
  description: string
}

export default function ExamPage({ params }: { params: { examId: string } }) {
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [examStarted, setExamStarted] = useState(false)
  const [violations, setViolations] = useState<Violation[]>([])
  const [isBlocked, setIsBlocked] = useState(false)
  const [timeRemaining, setTimeRemaining] = useState(0) // Initialize with 0
  const [lastActivity, setLastActivity] = useState(Date.now())
  const [showWarning, setShowWarning] = useState(false)
  const [warningMessage, setWarningMessage] = useState("")

  const router = useRouter()
  const { toast } = useToast()

  // Get exam data from localStorage
  const [examData, setExamData] = useState<any>(null)

  useEffect(() => {
    // Load exam data from localStorage
    const currentExam = localStorage.getItem("currentExam")
    if (currentExam) {
      const exam = JSON.parse(currentExam)
      setExamData({
        title: exam.title,
        formUrl: exam.formUrl,
        duration: exam.duration,
        uniqueId: exam.uniqueId,
      })
      setTimeRemaining(exam.duration * 60) // Convert minutes to seconds
    } else {
      // Fallback to mock data if no current exam
      setExamData({
        title: "Mathematics Final Exam",
        formUrl: "https://docs.google.com/forms/d/e/1FAIpQLSf_example/viewform",
        duration: 120,
        uniqueId: "MATH2024001",
      })
      setTimeRemaining(120 * 60) // Convert minutes to seconds
    }
  }, [])

  const logViolation = useCallback(
    (type: string, description: string) => {
      const violation: Violation = {
        type,
        timestamp: new Date().toISOString(),
        description,
      }

      setViolations((prev) => [...prev, violation])

      // Send to teacher dashboard (in real app, this would be via WebSocket or API)
      console.log("Violation logged:", violation)

      // Show warning
      setWarningMessage(description)
      setShowWarning(true)
      setIsBlocked(true)

      // Auto-unblock after 10 seconds
      setTimeout(() => {
        setShowWarning(false)
        setIsBlocked(false)
      }, 10000)

      toast({
        title: "Violation Detected",
        description: description,
        variant: "destructive",
      })
    },
    [toast],
  )

  // Fullscreen management
  const enterFullscreen = useCallback(() => {
    const elem = document.documentElement
    if (elem.requestFullscreen) {
      elem.requestFullscreen()
    }
  }, [])

  const exitFullscreen = useCallback(() => {
    if (document.exitFullscreen) {
      document.exitFullscreen()
    }
  }, [])

  // Activity monitoring
  const updateActivity = useCallback(() => {
    setLastActivity(Date.now())
  }, [])

  // Event listeners
  useEffect(() => {
    if (!examStarted) return

    const handleFullscreenChange = () => {
      const isCurrentlyFullscreen = !!document.fullscreenElement
      setIsFullscreen(isCurrentlyFullscreen)

      if (!isCurrentlyFullscreen && examStarted) {
        logViolation("FULLSCREEN_EXIT", "Student exited fullscreen mode during exam")
      }
    }

    const handleVisibilityChange = () => {
      if (document.hidden && examStarted) {
        logViolation("TAB_SWITCH", "Student switched tabs or minimized window")
      }
    }

    const handleKeyDown = (e: KeyboardEvent) => {
      updateActivity()

      // Prevent common cheating shortcuts
      if (examStarted) {
        if (e.altKey && e.key === "Tab") {
          e.preventDefault()
          logViolation("ALT_TAB", "Student attempted to use Alt+Tab")
        }
        if (e.ctrlKey && (e.key === "t" || e.key === "n" || e.key === "w")) {
          e.preventDefault()
          logViolation("KEYBOARD_SHORTCUT", `Student attempted to use Ctrl+${e.key.toUpperCase()}`)
        }

        // Block clipboard operations
        if (e.ctrlKey && e.key === "v") {
          e.preventDefault()
          logViolation("PASTE_ATTEMPT", "Student attempted to paste content (Ctrl+V)")
        }
        if (e.ctrlKey && e.key === "c") {
          e.preventDefault()
          logViolation("COPY_ATTEMPT", "Student attempted to copy content (Ctrl+C)")
        }
        if (e.ctrlKey && e.key === "x") {
          e.preventDefault()
          logViolation("CUT_ATTEMPT", "Student attempted to cut content (Ctrl+X)")
        }
        if (e.ctrlKey && e.key === "a") {
          e.preventDefault()
          logViolation("SELECT_ALL", "Student attempted to select all content (Ctrl+A)")
        }

        if (e.key === "F12" || (e.ctrlKey && e.shiftKey && e.key === "I")) {
          e.preventDefault()
          logViolation("DEV_TOOLS", "Student attempted to open developer tools")
        }
      }
    }

    const handleMouseMove = () => {
      updateActivity()
    }

    const handleContextMenu = (e: MouseEvent) => {
      if (examStarted) {
        e.preventDefault()
        e.stopPropagation()
        logViolation("RIGHT_CLICK", "Student attempted to right-click")
        return false
      }
    }

    const handleSelectStart = (e: Event) => {
      if (examStarted) {
        e.preventDefault()
        return false
      }
    }

    const handleDragStart = (e: DragEvent) => {
      if (examStarted) {
        e.preventDefault()
        return false
      }
    }

    // Add comprehensive event listeners
    document.addEventListener("fullscreenchange", handleFullscreenChange)
    document.addEventListener("visibilitychange", handleVisibilityChange)
    document.addEventListener("keydown", handleKeyDown)
    document.addEventListener("mousemove", handleMouseMove)
    document.addEventListener("contextmenu", handleContextMenu)
    document.addEventListener("selectstart", handleSelectStart)
    document.addEventListener("dragstart", handleDragStart)

    // Also add to window for broader coverage
    window.addEventListener("contextmenu", handleContextMenu)

    return () => {
      document.removeEventListener("fullscreenchange", handleFullscreenChange)
      document.removeEventListener("visibilitychange", handleVisibilityChange)
      document.removeEventListener("keydown", handleKeyDown)
      document.removeEventListener("mousemove", handleMouseMove)
      document.removeEventListener("contextmenu", handleContextMenu)
      document.removeEventListener("selectstart", handleSelectStart)
      document.removeEventListener("dragstart", handleDragStart)
      window.removeEventListener("contextmenu", handleContextMenu)
    }
  }, [examStarted, logViolation, updateActivity])

  // Inactivity monitoring
  useEffect(() => {
    if (!examStarted) return

    const checkInactivity = setInterval(() => {
      const timeSinceLastActivity = Date.now() - lastActivity
      if (timeSinceLastActivity > 300000) {
        // 5 minutes
        logViolation("INACTIVITY", "Student inactive for more than 5 minutes")
      }
    }, 60000) // Check every minute

    return () => clearInterval(checkInactivity)
  }, [examStarted, lastActivity, logViolation])

  // Timer
  useEffect(() => {
    if (!examStarted) return

    const timer = setInterval(() => {
      setTimeRemaining((prev) => {
        if (prev <= 1) {
          handleEndExam()
          return 0
        }
        return prev - 1
      })
    }, 1000)

    return () => clearInterval(timer)
  }, [examStarted])

  const handleStartExam = () => {
    enterFullscreen()
    setExamStarted(true)
    updateActivity()

    toast({
      title: "Exam Started",
      description: "You are now being monitored. Good luck!",
    })
  }

  const handleEndExam = () => {
    setExamStarted(false)
    exitFullscreen()

    toast({
      title: "Exam Ended",
      description: "Your responses have been recorded.",
    })

    // Redirect back to dashboard
    setTimeout(() => {
      router.push("/student/dashboard")
    }, 2000)
  }

  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const secs = seconds % 60
    return `${hours.toString().padStart(2, "0")}:${minutes.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`
  }

  if (showWarning) {
    return (
      <div className="fixed inset-0 bg-black flex items-center justify-center z-50">
        <Card className="max-w-md mx-4">
          <CardContent className="pt-6">
            <div className="text-center space-y-4">
              <AlertTriangle className="h-16 w-16 text-red-500 mx-auto" />
              <h2 className="text-2xl font-bold text-red-600">Violation Detected</h2>
              <p className="text-gray-700">{warningMessage}</p>
              <p className="text-sm text-gray-600">
                Your teacher has been notified. The exam will resume in a few seconds.
              </p>
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-red-500 mx-auto"></div>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  if (!examData) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
          <p>Loading exam...</p>
        </div>
      </div>
    )
  }

  if (!examStarted) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Card className="max-w-2xl mx-4">
          <CardContent className="pt-6">
            <div className="text-center space-y-6">
              <Shield className="h-16 w-16 text-blue-600 mx-auto" />
              <h1 className="text-3xl font-bold text-gray-900">{examData.title}</h1>

              <div className="bg-amber-50 border border-amber-200 rounded-lg p-4">
                <h3 className="font-semibold text-amber-800 mb-2">Proctoring Rules</h3>
                <ul className="text-sm text-amber-700 space-y-1 text-left">
                  <li>• You must remain in fullscreen mode throughout the exam</li>
                  <li>• Tab switching or window minimizing is not allowed</li>
                  <li>• Right-clicking and keyboard shortcuts are disabled</li>
                  <li>• Copy, paste, and text selection are blocked</li>
                  <li>• Extended inactivity will be flagged</li>
                  <li>• All violations are logged and reported to your teacher</li>
                </ul>
              </div>

              <div className="flex items-center justify-center gap-2 text-gray-600">
                <Clock className="h-5 w-5" />
                <span>Duration: {examData.duration} minutes</span>
              </div>

              <Button onClick={handleStartExam} size="lg" className="px-8">
                Start Proctored Exam
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Add CSS to disable right-click globally */}
      <style jsx>{`
        * {
          -webkit-user-select: none;
          -moz-user-select: none;
          -ms-user-select: none;
          user-select: none;
          -webkit-touch-callout: none;
          -webkit-tap-highlight-color: transparent;
        }
        
        iframe {
          pointer-events: auto;
        }
      `}</style>

      {/* Proctoring Header */}
      <div className="bg-red-600 text-white px-4 py-2 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Eye className="h-4 w-4" />
          <span className="text-sm font-medium">EXAM IN PROGRESS - MONITORED</span>
        </div>
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4" />
            <span className="font-mono">{formatTime(timeRemaining)}</span>
          </div>
          <Button
            onClick={handleEndExam}
            variant="outline"
            size="sm"
            className="bg-white text-red-600 hover:bg-gray-100"
          >
            End Exam
          </Button>
        </div>
      </div>

      {/* Exam Content */}
      <div className="p-4">
        {isBlocked ? (
          <div className="flex items-center justify-center h-96">
            <div className="text-center">
              <AlertTriangle className="h-16 w-16 text-red-500 mx-auto mb-4" />
              <h2 className="text-xl font-bold text-red-600 mb-2">Exam Temporarily Blocked</h2>
              <p className="text-gray-600">Please wait while the violation is being processed...</p>
            </div>
          </div>
        ) : (
          <div className="max-w-4xl mx-auto">
            <iframe
              src={examData.formUrl}
              className="w-full h-screen border-0"
              title="Exam Form"
              sandbox="allow-forms allow-scripts allow-same-origin"
              onContextMenu={(e) => {
                e.preventDefault()
                logViolation("RIGHT_CLICK", "Student attempted to right-click on exam form")
                return false
              }}
            />
          </div>
        )}
      </div>
    </div>
  )
}
