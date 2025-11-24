"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Clock, FileText, Shield, AlertTriangle } from "lucide-react"
import { useRouter } from "next/navigation"

interface Exam {
  id: string
  title: string
  duration: number
  status: "upcoming" | "active" | "completed"
  startTime: string
  endTime: string
  formUrl: string
  proctored: boolean
}

export default function StudentDashboard() {
  const [studentId, setStudentId] = useState("")
  const [exams, setExams] = useState<Exam[]>([])
  const router = useRouter()

  useEffect(() => {
    const storedStudentId = localStorage.getItem("studentId")
    const userRole = localStorage.getItem("userRole")

    if (!storedStudentId || userRole !== "student") {
      router.push("/")
      return
    }

    setStudentId(storedStudentId)

    // Mock exam data
    setExams([
      {
        id: "exam1",
        title: "Mathematics Final Exam",
        duration: 120,
        status: "active",
        startTime: "2024-01-20 10:00",
        endTime: "2024-01-20 12:00",
        formUrl: "https://forms.google.com/sample-math-exam",
        proctored: true,
      },
      {
        id: "exam2",
        title: "Physics Quiz",
        duration: 60,
        status: "upcoming",
        startTime: "2024-01-21 14:00",
        endTime: "2024-01-21 15:00",
        formUrl: "https://forms.google.com/sample-physics-quiz",
        proctored: true,
      },
      {
        id: "exam3",
        title: "Chemistry Lab Report",
        duration: 90,
        status: "completed",
        startTime: "2024-01-18 09:00",
        endTime: "2024-01-18 10:30",
        formUrl: "https://forms.google.com/sample-chemistry-report",
        proctored: false,
      },
    ])
  }, [router])

  const handleStartExam = (exam: Exam) => {
    if (exam.proctored) {
      router.push(`/student/exam/${exam.id}`)
    } else {
      window.open(exam.formUrl, "_blank")
    }
  }

  const handleLogout = () => {
    localStorage.removeItem("studentId")
    localStorage.removeItem("userRole")
    router.push("/")
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
        return "bg-green-100 text-green-800"
      case "upcoming":
        return "bg-blue-100 text-blue-800"
      case "completed":
        return "bg-gray-100 text-gray-800"
      default:
        return "bg-gray-100 text-gray-800"
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <Shield className="h-8 w-8 text-blue-600" />
              <div>
                <h1 className="text-xl font-bold text-gray-900">Student Exam Portal</h1>
                <p className="text-sm text-gray-600">Teacher: teacher@itproctool.edu / teacher123</p>
              </div>
            </div>
            <Button variant="outline" onClick={handleLogout}>
              Logout
            </Button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">My Exams</h2>
          <p className="text-gray-600">View and access your scheduled examinations</p>
        </div>

        {/* Proctoring Notice */}
        <Card className="mb-8 border-amber-200 bg-amber-50">
          <CardContent className="pt-6">
            <div className="flex items-start space-x-3">
              <AlertTriangle className="h-5 w-5 text-amber-600 mt-0.5" />
              <div>
                <h3 className="font-semibold text-amber-800">Proctoring Notice</h3>
                <p className="text-sm text-amber-700 mt-1">
                  Proctored exams will monitor your activity including tab switching, fullscreen exit, and inactivity.
                  Ensure you have a stable internet connection and are in a quiet environment.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Exams Grid */}
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {exams.map((exam) => (
            <Card key={exam.id} className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="flex justify-between items-start">
                  <CardTitle className="text-lg">{exam.title}</CardTitle>
                  <Badge className={getStatusColor(exam.status)}>{exam.status}</Badge>
                </div>
                <CardDescription>
                  {exam.proctored && (
                    <div className="flex items-center gap-1 text-amber-600 mb-2">
                      <Shield className="h-4 w-4" />
                      <span className="text-xs font-medium">Proctored Exam</span>
                    </div>
                  )}
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="flex items-center gap-2 text-sm text-gray-600">
                    <Clock className="h-4 w-4" />
                    <span>{exam.duration} minutes</span>
                  </div>
                  <div className="text-sm text-gray-600">
                    <p>
                      <strong>Start:</strong> {exam.startTime}
                    </p>
                    <p>
                      <strong>End:</strong> {exam.endTime}
                    </p>
                  </div>

                  {exam.status === "active" && (
                    <Button
                      onClick={() => handleStartExam(exam)}
                      className="w-full"
                      variant={exam.proctored ? "default" : "outline"}
                    >
                      <FileText className="h-4 w-4 mr-2" />
                      {exam.proctored ? "Start Proctored Exam" : "Open Form"}
                    </Button>
                  )}

                  {exam.status === "upcoming" && (
                    <Button disabled className="w-full bg-transparent" variant="outline">
                      Exam Not Started
                    </Button>
                  )}

                  {exam.status === "completed" && (
                    <Button disabled className="w-full bg-transparent" variant="outline">
                      Completed
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </main>
    </div>
  )
}
