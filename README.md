# 🎓 Decentralized Grading System (Grade)

A blockchain-based platform for recording student grades on-chain, providing an immutable and verifiable academic transcript system built on Stacks.

## 📋 Features

✨ **Immutable Records**: All grades are permanently stored on the blockchain  
👨‍🏫 **Role-Based Access**: Instructors, administrators, and contract owners have different permissions  
🔐 **Secure Grading**: Only authorized instructors can submit grades for their courses  
📊 **Automatic Letter Grades**: Numeric grades are automatically converted to letter grades  
🔍 **Transparent Verification**: Anyone can verify student grades and transcripts  
🏫 **Course Management**: Create and manage courses with assigned instructors  

## 🚀 Quick Start

### Prerequisites
- Clarinet installed
- Stacks wallet for testing

### Installation

```bash
git clone <repository-url>
cd Decentralized-Grading-System
clarinet integrate
```

## 📖 Usage Guide

### 🏛️ Administrative Functions

#### Add Administrator
```clarity
(contract-call? .Grade add-administrator 'SP1234... "John Admin")
```

#### Add Instructor
```clarity
(contract-call? .Grade add-instructor 'SP5678... "Dr. Smith" "Computer Science")
```

#### Enroll Student
```clarity
(contract-call? .Grade enroll-student 'SP9012... "Alice Johnson")
```

#### Create Course
```clarity
(contract-call? .Grade create-course "Introduction to Programming" "CS101" u3 'SP5678...)
```

### 📝 Grading Functions

#### Submit Grade
```clarity
(contract-call? .Grade submit-grade 'SP9012... "CS101" u85 "Fall 2024")
```

#### Update Grade
```clarity
(contract-call? .Grade update-grade 'SP9012... "CS101" u90)
```

### 🔍 Query Functions

#### Get Student Grade
```clarity
(contract-call? .Grade get-grade 'SP9012... "CS101")
```

#### Get Student Info
```clarity
(contract-call? .Grade get-student-info 'SP9012...)
```

#### Get Course Details
```clarity
(contract-call? .Grade get-course-details u1)
```

#### Check if Student is Enrolled
```clarity
(contract-call? .Grade is-student-enrolled 'SP9012...)
```

#### Get System Stats
```clarity
(contract-call? .Grade get-stats)
```

## 🎯 Grade Scale

| Numeric Grade | Letter Grade |
|---------------|--------------|
| 90-100        | A           |
| 80-89         | B           |
| 70-79         | C           |
| 60-69         | D           |
| 0-59          | F           |

## 🛡️ Security Features

- **Access Control**: Only authorized personnel can perform sensitive operations
- **Immutable Records**: Once submitted, grades create a permanent audit trail
- **Role Verification**: System validates instructor permissions before allowing grade submission
- **Data Integrity**: All student and course data is cryptographically secured

## 🔧 Error Codes

| Error Code | Description |
|------------|-------------|
| u100       | Unauthorized access |
| u101       | Student not found |
| u102       | Grade not found |
| u103       | Invalid grade value |
| u104       | Record already exists |
| u105       | Invalid course |
| u106       | Insufficient permissions |

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 📊 Data Structure

### Students
- Student ID (auto-generated)
- Student address (principal)
- Student name
- Enrollment date
- Status

### Courses
- Course ID (auto-generated)
- Course name
- Course code
- Credits
- Assigned instructor
- Creation date

### Grades
- Grade ID (auto-generated)
- Student ID
- Course ID
- Numeric grade (0-100)
- Letter grade (A-F)
- Graded by (instructor)
- Grade timestamp
- Semester

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
