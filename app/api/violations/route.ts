import { type NextRequest, NextResponse } from "next/server"
import { executeQuery } from "@/lib/db"

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const teacherId = searchParams.get("teacherId")

    if (!teacherId) {
      return NextResponse.json({ success: false, message: "Teacher ID is required" }, { status: 400 })
    }

    const query = `
      SELECT v.*, e.title as exam_title
      FROM violations v
      JOIN exam_sessions es ON v.exam_session_id = es.id
      JOIN exams e ON es.exam_id = e.id
      WHERE e.teacher_id = ?
      ORDER BY v.timestamp DESC
      LIMIT 50
    `

    const results = (await executeQuery(query, [teacherId])) as any[]

    return NextResponse.json({
      success: true,
      violations: results,
    })
  } catch (error) {
    console.error("Get violations error:", error)
    return NextResponse.json(
      {
        success: false,
        message: "Failed to fetch violations",
        error: error.message,
      },
      { status: 500 },
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const { examSessionId, studentName, examTitle, violationType, description, severity } = await request.json()

    if (!examSessionId || !studentName || !examTitle || !violationType || !description) {
      return NextResponse.json({ success: false, message: "Missing required fields" }, { status: 400 })
    }

    const query = `
      INSERT INTO violations (exam_session_id, student_name, exam_title, violation_type, description, severity)
      VALUES (?, ?, ?, ?, ?, ?)
    `

    const result = (await executeQuery(query, [
      examSessionId,
      studentName,
      examTitle,
      violationType,
      description,
      severity || "medium",
    ])) as any

    return NextResponse.json({
      success: true,
      message: "Violation logged successfully",
      violationId: result.insertId,
    })
  } catch (error) {
    console.error("Log violation error:", error)
    return NextResponse.json(
      {
        success: false,
        message: "Failed to log violation",
        error: error.message,
      },
      { status: 500 },
    )
  }
}
