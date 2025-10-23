(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-STUDENT-NOT-FOUND (err u101))
(define-constant ERR-GRADE-NOT-FOUND (err u102))
(define-constant ERR-INVALID-GRADE (err u103))
(define-constant ERR-ALREADY-EXISTS (err u104))
(define-constant ERR-INVALID-COURSE (err u105))
(define-constant ERR-INSUFFICIENT-PERMISSION (err u106))
(define-constant ERR-NO-GRADES-FOUND (err u107))

(define-data-var contract-owner principal tx-sender)
(define-data-var next-student-id uint u1)
(define-data-var next-course-id uint u1)
(define-data-var next-grade-id uint u1)

(define-map students
  { student-id: uint }
  {
    student-address: principal,
    student-name: (string-ascii 100),
    enrollment-date: uint,
    status: (string-ascii 20)
  }
)

(define-map student-lookup
  { student-address: principal }
  { student-id: uint }
)

(define-map courses
  { course-id: uint }
  {
    course-name: (string-ascii 100),
    course-code: (string-ascii 20),
    credits: uint,
    instructor: principal,
    created-at: uint
  }
)

(define-map course-lookup
  { course-code: (string-ascii 20) }
  { course-id: uint }
)

(define-map grades
  { grade-id: uint }
  {
    student-id: uint,
    course-id: uint,
    grade-value: uint,
    letter-grade: (string-ascii 2),
    graded-by: principal,
    graded-at: uint,
    semester: (string-ascii 20)
  }
)

(define-map student-grades
  { student-id: uint, course-id: uint }
  { grade-id: uint }
)

(define-map student-gpa-data
  { student-id: uint }
  {
    total-grade-points: uint,
    total-credits: uint,
    gpa: uint,
    academic-standing: (string-ascii 20),
    last-updated: uint
  }
)

(define-map instructors
  { instructor: principal }
  {
    name: (string-ascii 100),
    department: (string-ascii 50),
    authorized: bool
  }
)

(define-map administrators
  { admin: principal }
  { authorized: bool }
)

(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

(define-private (is-authorized-instructor (instructor principal))
  (default-to false (get authorized (map-get? instructors { instructor: instructor })))
)

(define-private (is-administrator (admin principal))
  (default-to false (get authorized (map-get? administrators { admin: admin })))
)

(define-private (can-grade (course-id uint))
  (let ((course (unwrap! (map-get? courses { course-id: course-id }) false)))
    (or 
      (is-eq tx-sender (get instructor course))
      (is-administrator tx-sender)
      (is-contract-owner)
    )
  )
)

(define-private (calculate-letter-grade (numeric-grade uint))
  (if (>= numeric-grade u90)
    "A"
    (if (>= numeric-grade u80)
      "B"
      (if (>= numeric-grade u70)
        "C"
        (if (>= numeric-grade u60)
          "D"
          "F"
        )
      )
    )
  )
)

(define-private (grade-to-points (numeric-grade uint))
  (if (>= numeric-grade u90)
    u400
    (if (>= numeric-grade u80)
      u300
      (if (>= numeric-grade u70)
        u200
        (if (>= numeric-grade u60)
          u100
          u0
        )
      )
    )
  )
)

(define-private (calculate-academic-standing (gpa uint))
  (if (>= gpa u350)
    "Honor Roll"
    (if (>= gpa u300)
      "Dean's List"
      (if (>= gpa u200)
        "Good Standing"
        (if (>= gpa u150)
          "Warning"
          "Probation"
        )
      )
    )
  )
)

(define-public (add-administrator (admin principal) (name (string-ascii 100)))
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    (ok (map-set administrators { admin: admin } { authorized: true }))
  )
)

(define-public (add-instructor (instructor principal) (name (string-ascii 100)) (department (string-ascii 50)))
  (begin
    (asserts! (or (is-contract-owner) (is-administrator tx-sender)) ERR-UNAUTHORIZED)
    (ok (map-set instructors 
      { instructor: instructor } 
      { name: name, department: department, authorized: true }
    ))
  )
)

(define-public (enroll-student (student-address principal) (student-name (string-ascii 100)))
  (let ((student-id (var-get next-student-id)))
    (begin
      (asserts! (or (is-contract-owner) (is-administrator tx-sender)) ERR-UNAUTHORIZED)
      (asserts! (is-none (map-get? student-lookup { student-address: student-address })) ERR-ALREADY-EXISTS)
      (map-set students
        { student-id: student-id }
        {
          student-address: student-address,
          student-name: student-name,
          enrollment-date: stacks-block-height,
          status: "active"
        }
      )
      (map-set student-lookup { student-address: student-address } { student-id: student-id })
      (var-set next-student-id (+ student-id u1))
      (ok student-id)
    )
  )
)

(define-public (create-course (course-name (string-ascii 100)) (course-code (string-ascii 20)) (credits uint) (instructor principal))
  (let ((course-id (var-get next-course-id)))
    (begin
      (asserts! (or (is-contract-owner) (is-administrator tx-sender)) ERR-UNAUTHORIZED)
      (asserts! (is-none (map-get? course-lookup { course-code: course-code })) ERR-ALREADY-EXISTS)
      (asserts! (is-authorized-instructor instructor) ERR-INSUFFICIENT-PERMISSION)
      (map-set courses
        { course-id: course-id }
        {
          course-name: course-name,
          course-code: course-code,
          credits: credits,
          instructor: instructor,
          created-at: stacks-block-height
        }
      )
      (map-set course-lookup { course-code: course-code } { course-id: course-id })
      (var-set next-course-id (+ course-id u1))
      (ok course-id)
    )
  )
)

(define-public (submit-grade (student-address principal) (course-code (string-ascii 20)) (grade-value uint) (semester (string-ascii 20)))
  (let 
    (
      (student-data (unwrap! (map-get? student-lookup { student-address: student-address }) ERR-STUDENT-NOT-FOUND))
      (course-data (unwrap! (map-get? course-lookup { course-code: course-code }) ERR-INVALID-COURSE))
      (student-id (get student-id student-data))
      (course-id (get course-id course-data))
      (grade-id (var-get next-grade-id))
      (letter-grade (calculate-letter-grade grade-value))
    )
    (begin
      (asserts! (can-grade course-id) ERR-UNAUTHORIZED)
      (asserts! (<= grade-value u100) ERR-INVALID-GRADE)
      (map-set grades
        { grade-id: grade-id }
        {
          student-id: student-id,
          course-id: course-id,
          grade-value: grade-value,
          letter-grade: letter-grade,
          graded-by: tx-sender,
          graded-at: stacks-block-height,
          semester: semester
        }
      )
      (map-set student-grades 
        { student-id: student-id, course-id: course-id } 
        { grade-id: grade-id }
      )
      (var-set next-grade-id (+ grade-id u1))
      (ok grade-id)
    )
  )
)

(define-public (update-grade (student-address principal) (course-code (string-ascii 20)) (new-grade-value uint))
  (let 
    (
      (student-data (unwrap! (map-get? student-lookup { student-address: student-address }) ERR-STUDENT-NOT-FOUND))
      (course-data (unwrap! (map-get? course-lookup { course-code: course-code }) ERR-INVALID-COURSE))
      (student-id (get student-id student-data))
      (course-id (get course-id course-data))
      (grade-entry (unwrap! (map-get? student-grades { student-id: student-id, course-id: course-id }) ERR-GRADE-NOT-FOUND))
      (grade-id (get grade-id grade-entry))
      (existing-grade (unwrap! (map-get? grades { grade-id: grade-id }) ERR-GRADE-NOT-FOUND))
      (new-letter-grade (calculate-letter-grade new-grade-value))
    )
    (begin
      (asserts! (can-grade course-id) ERR-UNAUTHORIZED)
      (asserts! (<= new-grade-value u100) ERR-INVALID-GRADE)
      (map-set grades
        { grade-id: grade-id }
        (merge existing-grade {
          grade-value: new-grade-value,
          letter-grade: new-letter-grade,
          graded-by: tx-sender,
          graded-at: stacks-block-height
        })
      )
      (ok grade-id)
    )
  )
)

(define-read-only (get-student-info (student-address principal))
  (map-get? student-lookup { student-address: student-address })
)

(define-read-only (get-student-details (student-id uint))
  (map-get? students { student-id: student-id })
)

(define-read-only (get-course-info (course-code (string-ascii 20)))
  (map-get? course-lookup { course-code: course-code })
)

(define-read-only (get-course-details (course-id uint))
  (map-get? courses { course-id: course-id })
)

(define-read-only (get-grade (student-address principal) (course-code (string-ascii 20)))
  (match (map-get? student-lookup { student-address: student-address })
    student-data
      (match (map-get? course-lookup { course-code: course-code })
        course-data
          (let 
            (
              (student-id (get student-id student-data))
              (course-id (get course-id course-data))
            )
            (match (map-get? student-grades { student-id: student-id, course-id: course-id })
              grade-entry
                (let ((grade-id (get grade-id grade-entry)))
                  (map-get? grades { grade-id: grade-id })
                )
              none
            )
          )
        none
      )
    none
  )
)

(define-read-only (get-instructor-info (instructor principal))
  (map-get? instructors { instructor: instructor })
)

(define-read-only (is-student-enrolled (student-address principal))
  (is-some (map-get? student-lookup { student-address: student-address }))
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-read-only (get-stats)
  {
    total-students: (- (var-get next-student-id) u1),
    total-courses: (- (var-get next-course-id) u1),
    total-grades: (- (var-get next-grade-id) u1),
    current-block: stacks-block-height
  }
)

(define-public (calculate-student-gpa (student-id uint))
  (let
    (
      (student (unwrap! (map-get? students { student-id: student-id }) ERR-STUDENT-NOT-FOUND))
    )
    (let
      (
        (gpa-result (fold calculate-gpa-for-course (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20) { student-id: student-id, total-points: u0, total-credits: u0 }))
        (total-points (get total-points gpa-result))
        (total-credits (get total-credits gpa-result))
      )
      (if (is-eq total-credits u0)
        ERR-NO-GRADES-FOUND
        (let
          (
            (gpa (/ total-points total-credits))
            (standing (calculate-academic-standing gpa))
          )
          (begin
            (map-set student-gpa-data
              { student-id: student-id }
              {
                total-grade-points: total-points,
                total-credits: total-credits,
                gpa: gpa,
                academic-standing: standing,
                last-updated: stacks-block-height
              }
            )
            (ok { gpa: gpa, academic-standing: standing, total-credits: total-credits })
          )
        )
      )
    )
  )
)

(define-private (calculate-gpa-for-course (course-id uint) (acc { student-id: uint, total-points: uint, total-credits: uint }))
  (let
    (
      (student-id (get student-id acc))
      (grade-entry (map-get? student-grades { student-id: student-id, course-id: course-id }))
    )
    (match grade-entry
      entry
        (let
          (
            (grade-id (get grade-id entry))
            (grade-data (unwrap-panic (map-get? grades { grade-id: grade-id })))
            (course-data (unwrap-panic (map-get? courses { course-id: course-id })))
            (credits (get credits course-data))
            (grade-value (get grade-value grade-data))
            (grade-points (grade-to-points grade-value))
          )
          {
            student-id: student-id,
            total-points: (+ (get total-points acc) (* grade-points credits)),
            total-credits: (+ (get total-credits acc) credits)
          }
        )
      acc
    )
  )
)

(define-read-only (get-student-gpa (student-id uint))
  (map-get? student-gpa-data { student-id: student-id })
)

(define-read-only (get-student-gpa-by-address (student-address principal))
  (match (map-get? student-lookup { student-address: student-address })
    student-data
      (let ((student-id (get student-id student-data)))
        (map-get? student-gpa-data { student-id: student-id })
      )
    none
  )
)
