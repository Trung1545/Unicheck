CAPSTONE PROJECT REPORT

Report 4 – Software Design Document

– Da Nang, May 2026 –

Table of Contents

I. Record of Changes3

II. Software Design Document4

1. System Design4

1.1 System Architecture4

1.2 Package Diagram4

2. Database Design4

3. Detailed Design5

3.1 Authentication5

3.2 System Account Management6

3.3. Notification Management6

3.4. System Monitoring & Audit6

3.5. Student Records Management6

3.6. Lecturer Records Management6

3.7. Facility Management6

3.8. Curriculum Management6

3.9. Course Catalog Management6

3.10. Semester Management6

3.11. Class Management6

3.12. Enrollment Management6

3.13. Timetable Operations6

3.14. Academic Request Management6

3.15. Attendance Configuration6

3.16. Attendance Taking & Reporting6

3.17. Lecturer Teaching Workspace6

3.18. Student Learning Workspace6

3.19. Grading & Assessment6

3.20. Class Communication6

3.21. AI Support Service6

Table of Tables

Table 1 - Cost Estimation3

Table 2 - Web-Frontend Package Descriptions4

Table 3 - App-Frontend Package Descriptions4

Table 4 - Backend Package Descriptions4

Table 5 - Table Descriptions4

Table of Figures

Figure 1: System Architecture Diagram3

Figure 2: Web-Frontend Package Diagram3

Figure 3: App-Frontend Package Diagram3

Figure 4: Backend Package Diagram3

Figure 5: AI Service Package Diagram3

Figure 6: Database Design Diagram3

Figure 7: Authentication Class Diagram23

Figure 8: Login Sequence Diagram23

Figure 9: Logout Sequence Diagram24

Figure 10: View Profile Sequence Diagram24

Figure 11: Update Profile Sequence Diagram25

Figure 12: Change password Sequence Diagram26

Figure 13: Forgot password Sequence Diagram27

Figure 14: System Account Management Class Diagram28

Figure 15: Import List of User Inactive Class Diagram29

Figure 16: Active User Account Class Diagram30

Figure 17: Create User Account Class Diagram30

Figure 18: View User Account Class Diagram31

Figure 19: Update User Account Class Diagram32

Figure 20: Delete User Account Class Diagram33

Figure 21: View List of Inactive User Class Diagram33

Figure 22: View List of Active User Class Diagram34

Figure 23: Block/Unblock User Account Class Diagram34

Figure 24: Assign User Permission Class Diagram35

Figure 25: Notification Management Class Diagram36

Figure 26: View Notification List Sequence Diagram37

Figure 27: View Notification Detail Sequence Diagram37

Figure 28: View List of News Sequence Diagram38

Figure 29: View List of News Sequence Diagram38

Figure 30: Create News Sequence Diagram39

Figure 31: View News Detail Sequence Diagram39

Figure 32: Update News Sequence Diagram40

Figure 33: Delete News Sequence Diagram40

Figure 34: System Monitoring & Audit Class Diagram41

Figure 35: View Log Access Sequence Diagram42

Figure 36: View System Log Sequence Diagram42

Figure 37: Student Records Management Class Diagram43

Figure 38: Import Information for Student List Sequence Diagram44

Figure 39: Export List Of Student Information Sequence Diagram44

Figure 40: View Student List Sequence Diagram45

Figure 41: View Student Information Detail Sequence Diagram45

Figure 42: Update Student Information Sequence Diagram45

Figure 43: Class Diagram for Lecturer Records Management46

Figure 44: Import List of Lecturer Information Sequence Diagram47

Figure 45: Export List of Lecturer Information Sequence Diagram47

Figure 46: View Lecturer List Sequence Diagram47

Figure 47: View Lecturer Information Detail Sequence Diagram48

Figure 48: Update Lecturer Profile Sequence Diagram48

Figure 49: Facility Management Class Diagram49

Figure 50: View List Of Classroom Sequence Diagram50

Figure 51: Create Classroom Sequence Diagram50

Figure 52: View Details Classroom Sequence Diagram51

Figure 53: Update Classroom Sequence Diagram51

Figure 54: Delete Classroom Sequence Diagram52

Figure 55: Create Wifi Access Point Sequence Diagram52

Figure 56: Update Wifi Access Point Sequence Diagram53

Figure 57: Delete Wifi Access Point Sequence Diagram54

Figure 58: View Wifi Access Point Sequence Diagram54

Figure 59: Assign Access Point To Room Sequence Diagram55

Figure 60: Curriculum Management Class Diagram56

Figure 61: Import Majors Sequence Diagram57

Figure 62: View List of Major Sequence Diagram57

Figure 63: Create Major Sequence Diagram58

Figure 64: Update Major Sequence Diagram58

Figure 65: Delete Major Sequence Diagram59

Figure 66: Import Specializations Sequence Diagram59

Figure 67: View List of Specializations Sequence Diagram60

Figure 68: Create Specializations Sequence Diagram60

Figure 69: View Details Specializations Sequence Diagram61

Figure 70: Update Specializations Sequence Diagram61

Figure 71: Delete Specializations Sequence Diagram62

Figure 72: Create SubSpecialization Sequence Diagram62

Figure 73: Update SubSpecialization Sequence Diagram63

Figure 74: Delete SubSpecializations Sequence Diagram63

Figure 75: Assign Course To Specialization Sequence Diagram64

Figure 76: Assign Course To SubSpecialization Sequence Diagram64

Figure 77: Course Catalog Management Class Diagram65

Figure 78: Import Courses Sequence Diagram66

Figure 79: View List Of Course Sequence Diagram66

Figure 80: Create Course Sequence Diagram67

Figure 81: View Details Course Sequence Diagram67

Figure 82: Update Course Sequence Diagram68

Figure 83: Delete Course Sequence Diagram68

Figure 84: Assign Prerequisite Course To Course Sequence Diagram69

Figure 85: Import Grade Component Sequence Diagram70

Figure 86: Create Component Sequence Diagram71

Figure 87: Update Component Sequence Diagram72

Figure 88: Delete Component Sequence Diagram72

Figure 89: Class Diagram for Semester Management73

Figure 90: Create Semester Sequence Diagram74

Figure 91: View Semester Sequence Diagram74

Figure 92: Update Semester Sequence Diagram75

Figure 93: Delete Semester Sequence Diagram75

Figure 94: Configure Semester In Details Sequence Diagram76

Figure 95: Class Management Class Diagram77

Figure 96: Import Class For Semester Sequence Diagram78

Figure 97: View List Class For Semester Sequence Diagram78

Figure 98: Create Class For Semester Sequence Diagram79

Figure 99: Update Class For Semester Sequence Diagram79

Figure 100: Delete Class For Semester Sequence Diagram80

Figure 101: Enrollment Management Class Diagram80

Figure 102: Import Enrollments Sequence Diagram81

Figure 103: Create Enrollment For Semester Sequence Diagram81

Figure 104: View Enrollment For Semester Sequence Diagram82

Figure 105: Update Enrollment For Semester Sequence Diagram82

Figure 106: Delete Enrollment For Semester Sequence Diagram83

Figure 107: Timetable Operations Class Diagram84

Figure 108: Generate Timetable Automatically Sequence Diagram85

Figure 109: View Timetable by Slot Sequence Diagram85

Figure 110: Enable Display for Users Sequence Diagram86

Figure 111: Export Timetable to Excel Sequence Diagram86

Figure 112: Academic Request Management Class Diagram87

Figure 113: View List Schedule Request Sequence Diagram87

Figure 114: View Schedule Request Sequence Diagram88

Figure 115:  Approve/Reject Schedule Request Sequence Diagram88

Figure 116: Create Schedule Request Sequence Diagram89

Figure 117: View Academic Request Detail Sequence Diagram89

Figure 118: View List of Request Sequence Diagram90

Figure 119: Create Academic Request Sequence Diagram90

Figure 120: Accept/Reject Academic Request Sequence Diagram91

Figure 121: Attendance Configuration Class Diagram92

Figure 122: Configure Attendance System Sequence Diagram93

Figure 123: View Attendance System Configuration Sequence Diagram93

Figure 124: Attendance Taking & Reporting Class Diagram94

Figure 125: Update Attendance Manually Sequence Diagram95

Figure 126: Register Face Recognition Sequence Diagram96

Figure 127: Scan Face Recognition Attendance Sequence Diagram96

Figure 128: View Student Attendance Of Slot Sequence Diagram97

Figure 129: View Attendance Report Sequence Diagram97

Figure 130: View Attendance Statistics by Class Sequence Diagram98

Figure 131: Export Attendance Statistics by Class Sequence Diagram98

Figure 132 : Generate Dynamic QR Code Sequence Diagram…………………………………………………………………99

Figure 133: Scan Dynamic QR Attendance Sequence Diagram…………………………………………………………….100

Figure 134: Class Diagram for Lecturer Teaching Workspace99

Figure 135: View Teaching Classes Sequence Diagram100

Figure 136: View Teaching Classes Detail Sequence Diagram100

Figure 137: Create Assignment for Slot Sequence Diagram101

Figure 138: View Detail Assignment Sequence Diagram101

Figure 139: Update Assignment for Slot Sequence Diagram102

Figure 140: Delete Assignment for Slot Sequence Diagram102

Figure 141: View List Of Assignment Sequence Diagram103

Figure 142: Comment Student's Assignment Sequence Diagram103

Figure 143: Class Diagram for Student Teaching Workspace104

Figure 144: View Personal Timetable105

Figure 145: View Study Slot Detail105

Figure 146: Save Timetable to Calendar106

Figure 147: View List Of Assignment for Class106

Figure 148: Submit Assignment107

Figure 149: Grading & Assessment Class Diagram107

Figure 150: Import Class's Component Grade Sequence Diagram108

Figure 151: Send Class's Component Grade Sequence Diagram108

Figure 152: Import Final Exam Grade Sequence Diagram109

Figure 153: Import Resit Exam Grade Sequence Diagram110

Figure 154: Publish Grade Sequence Diagram111

Figure 155: View Total Grade Report Sequence Diagram111

Figure 156: View Detail Course Grade Sequence Diagram112

Figure 157: Class Communication Class Diagram113

Figure 158: Create Chat Group Sequence Diagram114

Figure 159: Chat Sequence Diagram114

Figure 160: AI Support Service Class Diagram115

Figure 161: AI Support Service Sequence Diagram115

I. Record of Changes

Date

A*M, D

In charge

Change Description

A

Initial Report 4 and Design System Architecture

A

Design Database Schema (ERD & Data Dictionary)

A

Design Package Diagram

A

Draw Sequence Diagrams (Each member for assigned modules)

A

Design Class Diagram (Feature classes)

M

Review, format, and finalize Design Document

*A - Added M - Modified D - Deleted

II. Software Design Document

1. System Design

1.1 System Architecture

1.1.1 System Architecture Overview

Figure 1: System Architecture Diagram

1.1.2 System Architecture Explanation

1.1.2.1. React (with Vite framework)

React is the core foundation of our frontend web application, paired with Vite as the build tool to ensure lightning-fast development server start times and optimized production builds. This combination enables the creation of a highly efficient Single Page Application (SPA), delivering a seamless, interactive user experience with fast client-side routing and optimized asset loading.

1.1.2.2. Tailwind CSS

Tailwind CSS is a utility-first CSS framework used to rapidly build a responsive and modern user interface. By leveraging pre-defined utility classes trực tiếp trong các components, nó đảm bảo hệ thống thiết kế đồng nhất và dễ bảo trì trên nhiều kích thước màn hình mà không cần viết quá nhiều file CSS tùy chỉnh.

1.1.2.3. Flutter & Dart

Flutter, powered by the Dart programming language, is utilized to build the cross-platform mobile application for both iOS and Android. It allows sharing a single codebase to deliver high-performance, native-like mobile experiences with smooth animations, while seamlessly connecting to the same backend APIs through the ngrok gateway.

1.1.2.4. TypeScript

TypeScript enhances frontend code quality and maintainability by adding static type checking to JavaScript. It is heavily used across the React web project to improve developer productivity, reduce runtime errors, and establish a robust, self-documenting code architecture.

1.1.2.5. Axios & RESTful API

Axios is the primary HTTP client used for making RESTful API calls. In this architecture, Axios connects the frontend applications (Vercel & Mobile) to the backend by calling the public URL provided by ngrok, which then tunnels the requests to our local services.

1.1.2.6. WebSockets (STOMP)

WebSockets, implemented via the STOMP protocol, is integrated for real-time bidirectional communication. This allows the system to push instant updates and notifications. The WebSocket connection is consistently maintained even through the ngrok tunnel, ensuring real-time features work across both web and mobile.

1.1.2.7. Java & Spring Boot

Java Spring Boot serves as the robust foundation for the backend RESTful APIs. Running locally within a Docker environment, it handles core business logic, user authentication (JWT), and coordinates between the local database and the Python-based AI Service.

1.1.2.8. PostgreSQL (Local Docker Instance)

PostgreSQL is the primary relational database system used to store structured data (user records, grades, courses). Unlike the previous cloud-based setup, it is now hosted as a local Docker container for faster access during development, ensuring full ACID compliance while maintaining data sovereignty.

1.1.2.9. Redis

Redis is implemented as an in-memory data store within our local Docker network. It functions as a high-speed caching layer for frequently accessed query results, significantly reducing the load on the local PostgreSQL database and improving overall system response times.

1.1.2.10. AI Service (Python & Flask)

A dedicated AI Service, built with Python and Flask, operates as a specialized microservice within the local environment. It handles heavy computational workloads independently from the Spring Boot backend, ensuring performance stability for the main application.

1.1.2.11. OpenCV & Face Recognition

OpenCV, integrated within the local Python AI Service, powers the facial recognition capabilities of the system. This allows for automated attendance tracking or identity verification by processing image data directly on the local server infrastructure.

1.1.2.12. OpenRouter

The AI Chatbot functionality is powered by OpenRouter, providing access to advanced Large Language Models. This allows the system to understand complex user queries and provide intelligent responses while offloading the heavy LLM processing to high-performance cloud infrastructure.

1.1.2.13. Cloudinary

Cloudinary handles all image and media asset management. It provides cloud-based storage, dynamic formatting, and delivery through a global CDN. This ensures that assets like user avatars or uploaded documents are stored securely and loaded instantly in optimized formats.

1.1.2.14. Firebase Cloud Messaging (FCM)

Firebase is utilized for its Cloud Messaging capabilities. It provides the infrastructure to send targeted push notifications and alerts to users, ensuring they stay updated with important system events in real-time, especially on the mobile platform.

1.1.2.15. Git & GitHub

Git and GitHub facilitate source version control and collaborative workflow. GitHub maintains code integrity and acts as the central hub for issuing pull requests and performing code reviews before changes are pulled to the local deployment server.

1.1.2.16. ngrok (Secure Gateway & Reverse Proxy)

ngrok serves as the critical bridge between our local server and the public internet. It creates a secure HTTPS tunnel that allows the frontend (hosted on Vercel) and the Mobile App to communicate with the local Spring Boot backend. This effectively acts as a reverse proxy, handling SSL termination and providing a public entry point without complex network configuration.

1.1.2.17. Deployment Infrastructure (Vercel & Local Docker)

The deployment is a hybrid model: the React frontend is deployed on Vercel for global scalability and speed, while the entire backend stack (Spring Boot, Python AI, PostgreSQL, Redis) is containerized using Docker and hosted on a Local Server, exposed to the web securely via ngrok.

1.1.3 Cost Estimation

#

Service

Monthly cost

Year cost

Note

Development

1

React + Vite + Tailwind CSS

0 VND

0 VND

2

Flutter + Dart

0 VND

0 VND

3

Java Spring Boot

0 VND

0 VND

4

PostgreSQL (Local Docker)

0 VND

0 VND

5

Tools & IDE (VS Code, IntelliJ IDEA CE)

0 VND

0 VND

6

GitHub (Source Code Control)

0 VND

0 VND

Actual operational implementation

7

Vercel (Frontend Deployment)

0 VND

0 VND

8

ngrok (Gateway Service)

9

Cloudinary

(Image & Media Cloud)

0 VND

0 VND

10

Firebase

(Cloud Messaging/Push Noti)

0 VND

0 VND

11

Groq API (AI LLM Chatbot)

Total Estimated

Table 1 - Cost Estimation

1.2 Package Diagram

1.2.1 Web-Frontend

Figure 2: Web-Frontend Package Diagram

Package Descriptions

No

Package

Description

1

routes

App routing configuration and navigation flow.

2

provider

Global context wrappers (e.g., Theme, Auth, State).

3

pages

Main application screens that assemble components.

4

hooks

Feature-specific custom hooks for business logic.

5

api

Feature-specific API requests and data fetching.

6

components

UI components dedicated to a specific feature.

7

common-ui

Reusable UI components shared across the app.

8

global-hooks

Reusable, multi-purpose custom hooks.

9

utils

General helper functions (e.g., formatting, parsing).

10

store

Global state management configuration.

11

api-client

Base HTTP client setup and interceptors.

12

types

Core TypeScript types and interfaces.

13

constants

Application-wide constants and enums.

14

config

Environment variables and app configurations.

Table 2 - Web-Frontend Package Descriptions

1.2.2 App-Frontend

Figure 3: App-Frontend Package Diagram

Package Descriptions

No

Package

Description

1

auth/views

UI screens for user authentication and authorization.

2

home/views

Main dashboard and landing screens.

3

profile/views

UI screens for managing user account details.

4

schedule/views

UI screens for viewing and managing timetable slots.

5

share/widgets

Reusable UI components shared across various features.

6

core/widgets

Fundamental, application-wide UI components.

7

feature/*/models

Data structures and entities defining feature data.

8

feature/*/controllers

Business logic and state management for specific features.

9

feature/*/bindings

Dependency injection mapping controllers to their views.

10

feature/*/services

API calls and data fetching specific to a single feature.

11

core/utils

Shared helper functions and formatting tools.

12

core/theme

Application-wide design system, colors, and typography.

13

core/constants

System-wide constant values and configuration keys.

14

core/services

Foundational background services (e.g., network client, local storage).

Table 3 - App-Frontend Package Descriptions

1.2.3 Backend

Figure 4: Backend Package Diagram

Package Descriptions

No

Package

Description

1

controller

Handles incoming HTTP requests and returns responses (Presentation).

2

security

Handles authentication, authorization, and security configurations.

3

config

Contains application setups and framework configurations.

4

util

Shared helper classes and general utility functions.

5

service

Interfaces defining the core business logic operations.

6

service/impl

Concrete implementations of the business logic interfaces.

7

scheduler

Manages automated background jobs and scheduled tasks.

8

repository

Data access interfaces that abstract database operations.

9

exception

Custom error definitions and domain-specific exception handling.

10

client

External API clients and third-party service integrations.

11

model

Database entities, DTOs, and data persistence structures.

12

test

Unit and integration testing suites for the application.

Table 4 - Backend Package Descriptions

Figure 5: AI Service Package Diagram

Package Descriptions

No

Package

Description

1

chat_routes

API endpoints handling incoming conversational requests.

2

face_routes

API endpoints for facial recognition operations, like smart attendance.

3

chatbot/service

Business logic managing chatbot conversational flows and context.

4

face_recognition/service

Business logic orchestrating face verification and identity matching.

5

LLMRoute & Agent

LLM request routing and autonomous agent task execution.

6

vectorDB

Vector database interactions for semantic search and RAG retrieval.

7

feature_extractor

Core engine that extracts facial embeddings from image data.

8

liveness_detect

Anti-spoofing checks verifying a real, physical person is present.

9

config

AI model configurations, thresholds, and environment variables.

10

store

Infrastructure access for persisting media, embeddings, or logs.

Table 5 - AI Service Package Descriptions

2. Database Design

Figure 6: Database Design Diagram

Table Descriptions

No

Table

Description

1

users

Core system user account information.

- Primary keys: id

- Foreign keys: None

2

student_profiles

Detailed student profiles (major, GPA, etc.).

- Primary keys: user_id

- Foreign keys: user_id (users), major_id (majors), specialization_id (specializations), sub_specialization_id (sub_specializations)

3

lecturer_profiles

Detailed lecturer profiles (department, expertise).

- Primary keys: user_id

- Foreign keys: user_id (users)

4

lecturer_grade_otps

OTPs for authenticating lecturers when submitting grades.

- Primary keys: user_id

- Foreign keys: user_id (users)

5

user_permissions

Specific permissions granted to individual users.

- Primary keys: id

- Foreign keys: user_id (users), granted_by (users)

6

user_device_tokens

Device tokens stored for Push Notifications.

- Primary keys: id

- Foreign keys: user_id (users)

7

face_encodings

Facial vectors used for AI attendance checking.

- Primary keys: id

- Foreign keys: user_id (users)

8

majors

Main academic majors management.

- Primary keys: id

- Foreign keys: None

9

specializations

Narrower academic specializations management.

- Primary keys: id

- Foreign keys: major_id (majors)

10

sub_specializations

Sub-specializations or minor branches management.

- Primary keys: id

- Foreign keys: specialization_id (specializations)

11

courses

Catalog of courses available in the program.

- Primary keys: id

- Foreign keys: None

12

course_prerequisites

Prerequisite course constraints.

- Primary keys: course_id, prerequisite_id

- Foreign keys: course_id (courses), prerequisite_id (courses)

13

specialization_courses

Mapping of courses to specific specializations.

- Primary keys: id

- Foreign keys: specialization_id (specializations), course_id (courses)

14

sub_specialization_courses

Mapping of courses to specific sub-specializations.

- Primary keys: id

- Foreign keys: sub_specialization_id (sub_specializations), course_id (courses)

15

grade_components

Grade structures (Progress test, Final exam, etc.) for courses.

- Primary keys: id

- Foreign keys: reference_component_id (grade_components), course_id (courses)

16

semesters

Academic semester management (e.g., FA24, SP25).

- Primary keys: id

- Foreign keys: None

17

semester_configs

Specific configuration parameters for each semester.

- Primary keys: id

- Foreign keys: semester_id (semesters)

18

semester_weekdays

Valid study weekdays within a given semester.

- Primary keys: id

- Foreign keys: semester_id (semesters)

19

holidays

System-wide or semester-specific holidays.

- Primary keys: id

- Foreign keys: semester_id (semesters)

20

slot_types

Timeframe configurations for study slots.

- Primary keys: id

- Foreign keys: semester_id (semesters)

21

rooms

List of classrooms, labs, and pseudo-rooms.

- Primary keys: id

- Foreign keys: None

22

wifi_access_points

Campus Wi-Fi access points management.

- Primary keys: id

- Foreign keys: None

23

room_wifi_access_points

Mapping of Wi-Fi access points to specific rooms (for Wi-Fi attendance).

- Primary keys: id

- Foreign keys: room_id (rooms), wifi_access_point_id (wifi_access_points)

24

class_sections

Management of class sections opened for courses in a semester.

- Primary keys: class_name

- Foreign keys: course_id (courses), semester_id (semesters), lecturer_id (users), grades_submitted_by (users),

grades_published_by (users), resit_grades_published_by (users)

25

teaching_assignments

Assignment of lecturers to teach specific courses.

- Primary keys: id

- Foreign keys: lecturer_id (users), course_id (courses), semester_id (semesters)

26

enrollments

Student registrations for class sections.

- Primary keys: id

- Foreign keys: class_name (class_sections), student_id (users)

27

timetable_slots

Detailed timetable slots scheduled for classes.

- Primary keys: id

- Foreign keys: class_name (class_sections), room_id (rooms), slot_type_id (slot_types)

28

student_grades

Student scores for individual grade components.

- Primary keys: id

- Foreign keys: enrollment_id (enrollments), grade_component_id (grade_components), graded_by_id (users)

29

attendance_configs

Attendance rules configuration (absence thresholds, methods, etc.).

- Primary keys: id

- Foreign keys: None

30

attendance_sessions

Attendance sessions opened for each timetable slot.

- Primary keys: id

- Foreign keys: timetable_slot_id (timetable_slots), lecturer_id (users)

31

student_attendances

Detailed attendance status for individual students.

- Primary keys: id

- Foreign keys: session_id (attendance_sessions), student_id (users), updated_by_id (users), manual_verified_by (users)

32

assignments

Tasks or assignments given by lecturers to classes.

- Primary keys: id

- Foreign keys: class_name (class_sections), created_by (users), timetable_slot_id (timetable_slots)

33

assignment_submissions

Student submissions for assignments.

- Primary keys: id

- Foreign keys: assignment_id (assignments), student_id (users), enrollment_id (enrollments)

34

chat_groups

Discussion chat groups (by class, course, etc.).

- Primary keys: id

- Foreign keys: class_name (class_sections), created_by_id (users)

35

chat_group_members

Members participating in chat groups.

- Primary keys: id

- Foreign keys: chat_group_id (chat_groups), user_id (users)

36

chat_messages

Message content sent within chat groups.

- Primary keys: id

- Foreign keys: chat_group_id (chat_groups), sender_id (users), reply_to_id (chat_messages)

37

chat_message_reads

Read status tracking for individual chat messages.

- Primary keys: id

- Foreign keys: message_id (chat_messages), user_id (users)

38

chat_message_reactions

Emoji reactions left on chat messages.

- Primary keys: id

- Foreign keys: message_id (chat_messages), user_id (users)

39

ai_chat_sessions

User conversation sessions with the AI Chatbot.

- Primary keys: id

- Foreign keys: user_id (users)

40

ai_chat_messages

Detailed exchange content between users and AI within sessions.

- Primary keys: id

- Foreign keys: session_id (ai_chat_sessions)

41

notifications

System notifications sent to users.

- Primary keys: id

- Foreign keys: None

42

news

General news and announcements for the school or classes.

- Primary keys: id

- Foreign keys: sender_id (users)

43

news_attachments

Files and media attached to news articles.

- Primary keys: None

- Foreign keys: news_id (news)

44

academic_requests

Student academic requests (pause semester, retake course, etc.).

- Primary keys: id

- Foreign keys: student_id (users), semester_id (semesters), course_id (courses), class_section_id (class_sections), approver_id (users)

45

schedule_requests

Lecturer requests to change schedules or swap rooms.

- Primary keys: id

- Foreign keys: requester_id (users), class_name (class_sections), original_slot_id (timetable_slots),

requested_slot_id (timetable_slots), requested_room_id (rooms), approver_id (users)

46

access_logs

Logs of user system access and activity.

- Primary keys: id

- Foreign keys: user_id (users)

47

user_sessions

Detailed login session data (location, device) for users.

- Primary keys: id

- Foreign keys: user_id (users)

48

alerts

Automated system alerts (errors, risks, warnings).

- Primary keys: id

- Foreign keys: user_id (users)

49

system_logs

Logs of all significant data modification actions.

- Primary keys: id

- Foreign keys: performer_id (users)

50

import_jobs

Management of large data import/export processes.

- Primary keys: id

- Foreign keys: None

Table 5 - Table Descriptions

3. Detailed Design

3.1. Authentication

3.1.1 Class Diagram

Figure 7: Authentication Class Diagram

3.1.2 Login

Figure 8: Login Sequence Diagram

3.1.3 Logout

Figure 9: Logout Sequence Diagram

3.1.4 View Profile

Figure 10: View Profile Sequence Diagram

3.1.5 Update Profile

Figure 11: Update Profile Sequence Diagram

3.1.6 Change password

Figure 12: Change password Sequence Diagram

3.1.7 Forgot password

Figure 13: Forgot password Sequence Diagram

3.2. System Account Management

3.2.1 Class Diagram

Figure 14: System Account Management Class Diagram

3.2.2 Import List of User Inactive

Figure 15: Import List of User Inactive Class Diagram

3.2.3 Active User Account

Figure 16: Active User Account Class Diagram

3.2.4 Create User Account

Figure 17: Create User Account Class Diagram

3.2.5 View User Account

Figure 18: View User Account Class Diagram

3.2.6 Update User Account

Figure 19: Update User Account Class Diagram

3.2.7 Delete User Account

Figure 20: Delete User Account Class Diagram

3.2.5 View List of Inactive User

Figure 21: View List of Inactive User Class Diagram

3.2.6 View List of Active User

Figure 22: View List of Active User Class Diagram

3.2.7 Block/Unblock User Account

Figure 23: Block/Unblock User Account Class Diagram

3.2.8 Assign User Permission

Figure 24: Assign User Permission Class Diagram

3.3. Notification Management

3.3.1 Class Diagram

Figure 25: Notification Management Class Diagram

3.3.2 View Notification List

Figure 26: View Notification List Sequence Diagram

3.3.3 View Notification Detail

Figure 27: View Notification Detail Sequence Diagram

3.3.4 View List of News

Figure 28: View List of News Sequence Diagram

3.3.5 View List of News Management

Figure 29: View List of News Sequence Diagram

3.3.6 Create News

Figure 30: Create News Sequence Diagram

3.3.7 View News Detail

Figure 31: View News Detail Sequence Diagram

3.3.8 Update News

Figure 32: Update News Sequence Diagram

3.3.9 Delete News

Figure 33: Delete News Sequence Diagram

3.4. System Monitoring & Audit

3.4.1. Class Diagram:

Figure 34: System Monitoring & Audit Class Diagram

3.4.2 View Log Access

Figure 35: View Log Access Sequence Diagram

3.4.3 View System Log

Figure 36: View System Log Sequence Diagram

3.5. Student Records Management

3.5.1 Class diagram

Figure 37: Student Records Management Class Diagram

3.5.2 Import Information for Student List

Figure 38: Import Information for Student List Sequence Diagram

3.5.3 Export list of Student information

Figure 39: Export List Of Student Information Sequence Diagram

3.5.4 View Student List

Figure 40: View Student List Sequence Diagram

3.5.5 View Student information in detail

Figure 41: View Student Information Detail Sequence Diagram

3.5.6 Update Student Information

Figure 42: Update Student Information Sequence Diagram

3.6. Lecturer Records Management

3.6.1 Class diagram

Figure 43: Class Diagram for Lecturer Records Management

3.6.2 Import List of Lecturer information

Figure 44: Import List of Lecturer Information Sequence Diagram

3.6.3 Export List of Lecturer information

Figure 45: Export List of Lecturer Information Sequence Diagram

3.6.4 View Lecturer List

Figure 46: View Lecturer List Sequence Diagram

3.6.5 View Lecturer information in detail

Figure 47: View Lecturer Information Detail Sequence Diagram

3.6.6 Update Lecturer Profile

Figure 48: Update Lecturer Profile Sequence Diagram

3.7. Facility Management

3.7.1 Class Diagram

Figure 49: Facility Management Class Diagram

3.7.2 View List Of Classroom Sequence Diagram

Figure 50: View List Of Classroom Sequence Diagram

3.7.3 Create Classroom Sequence Diagram

Figure 51: Create Classroom Sequence Diagram

3.7.4 View Details Classroom Sequence Diagram

Figure 52: View Details Classroom Sequence Diagram

3.7.5 Update Classroom Sequence Diagram

Figure 53: Update Classroom Sequence Diagram

3.7.6 Delete Room Sequence Diagram

Figure 54: Delete Classroom Sequence Diagram

3.7.7 Create Wifi Access Point Sequence Diagram

Figure 55: Create Wifi Access Point Sequence Diagram

3.7.8 Update Wifi Access Point Sequence Diagram

Figure 56: Update Wifi Access Point Sequence Diagram

3.7.9 Delete Wifi Access Point Sequence Diagram

Figure 57: Delete Wifi Access Point Sequence Diagram

3.7.10 View Wifi Access Point Sequence Diagram

Figure 58: View Wifi Access Point Sequence Diagram

3.7.11 Assign Access Point To Room Sequence Diagram

Figure 59: Assign Access Point To Room Sequence Diagram

3.8. Curriculum Management

3.8.1 Class Diagram:

Figure 60: Curriculum Management Class Diagram

3.8.2 Import List of Major Sequence Diagram

Figure 61: Import Majors Sequence Diagram

3.8.3 View List of Major Sequence Diagram

Figure 62: View List of Major Sequence Diagram

3.8.4 Create Major Sequence Diagram

Figure 63: Create Major Sequence Diagram

3.8.5 Update Major Sequence Diagram

Figure 64: Update Major Sequence Diagram

3.8.6 Delete Major Sequence Diagram

Figure 65: Delete Major Sequence Diagram

3.8.7 Import List Of Specializations Sequence Diagram

Figure 66: Import Specializations Sequence Diagram

3.8.8 View List of Specializations Sequence Diagram

Figure 67: View List of Specializations Sequence Diagram

3.8.9 Create Specializations Sequence Diagram

Figure 68: Create Specializations Sequence Diagram

3.8.10 View Details Specializations Sequence Diagram

Figure 69: View Details Specializations Sequence Diagram

3.8.11 Update Specializations Sequence Diagram

Figure 70: Update Specializations Sequence Diagram

3.8.12 Delete Specializations Sequence Diagram

Figure 71: Delete Specializations Sequence Diagram

3.8.13 Create SubSpecialization Sequence Diagram

Figure 72: Create SubSpecialization Sequence Diagram

3.8.14 Update SubSpecialization Sequence Diagram

Figure 73: Update SubSpecialization Sequence Diagram

3.8.15 Delete SubSpecializations Sequence Diagram

Figure 74: Delete SubSpecializations Sequence Diagram

3.8.16 Assign Course To Specialization Sequence Diagram

Figure 75: Assign Course To Specialization Sequence Diagram

3.8.17 Assign Course To SubSpecialization Sequence Diagram

Figure 76: Assign Course To SubSpecialization Sequence Diagram

3.9. Course Catalog Management

3.9.1 Class Diagram

Figure 77: Course Catalog Management Class Diagram

3.9.2 Import List Of Course Sequence Diagram

Figure 78: Import Courses Sequence Diagram

3.9.3 View List Of Course Sequence Diagram

Figure 79: View List Of Course Sequence Diagram

3.9.4 Create Course Sequence Diagram

Figure 80: Create Course Sequence Diagram

3.9.5 View Details Course Sequence Diagram

Figure 81: View Details Course Sequence Diagram

3.9.6 Update Course Sequence Diagram

Figure 82: Update Course Sequence Diagram

3.9.7 Delete Course Sequence Diagram

Figure 83: Delete Course Sequence Diagram

3.9.8 Assign Prerequisite Course To Course Sequence Diagram

Figure 84: Assign Prerequisite Course To Course Sequence Diagram

3.9.9 Import Grade Component Sequence Diagram

Figure 85: Import Grade Component Sequence Diagram

3.9.10 Create Component Sequence Diagram

Figure 86: Create Component Sequence Diagram

3.9.11 Update Component Sequence Diagram

Figure 87: Update Component Sequence Diagram

3.9.12 Delete Component Sequence Diagram

Figure 88: Delete Component Sequence Diagram

3.10. Semester Management

3.10.1 Class Diagram

Figure 89: Class Diagram for Semester Management

3.10.2 Create Semester

Figure 90: Create Semester Sequence Diagram

3.10.3 View Semester

Figure 91: View Semester Sequence Diagram

3.10.4 Update Semester

Figure 92: Update Semester Sequence Diagram

3.10.5 Delete Semester

Figure 93: Delete Semester Sequence Diagram

3.10.6 Configure Semester In Details

Figure 94: Configure Semester In Details Sequence Diagram

3.11. Class Management

3.11.1 Class Diagram

Figure 95: Class Management Class Diagram

3.11.2 Import Class For Semester

Figure 96: Import Class For Semester Sequence Diagram

3.11.3 View List of Class For Semester

Figure 97: View List Class For Semester Sequence Diagram

3.11.4 Create Class For Semester

Figure 98: Create Class For Semester Sequence Diagram

3.11.5 Update Class For Semester

Figure 99: Update Class For Semester Sequence Diagram

3.11.6 Delete Class For Semester

Figure 100: Delete Class For Semester Sequence Diagram

3.12. Enrollment Management

3.12.1 Class Diagram

Figure 101: Enrollment Management Class Diagram

3.12.2 Import Enrollment of Class For Semester

Figure 102: Import Enrollments Sequence Diagram

3.12.3 Create Enrollment For Semester

Figure 103: Create Enrollment For Semester Sequence Diagram

3.12.4 View Enrollment For Semester

Figure 104: View Enrollment For Semester Sequence Diagram

3.12.5 Update Enrollment For Semester

Figure 105: Update Enrollment For Semester Sequence Diagram

3.12.6 Delete Enrollment For Semester

Figure 106: Delete Enrollment For Semester Sequence Diagram

3.13. Timetable Operations

3.13.1 Class Diagram

Figure 107: Timetable Operations Class Diagram

3.13.2 Generate Timetable Automatically

Figure 108: Generate Timetable Automatically Sequence Diagram

3.13.3 View Timetable by Slot

Figure 109: View Timetable by Slot Sequence Diagram

3.13.4 Enable Display for Users

Figure 110: Enable Display for Users Sequence Diagram

3.13.5 Export Timetable to Excel

Figure 111: Export Timetable to Excel Sequence Diagram

3.14. Academic Request Management

3.14.1 Class Diagram

Figure 112: Academic Request Management Class Diagram

3.14.2 View List Schedule Request

Figure 113: View List Schedule Request Sequence Diagram

3.14.3 View Schedule Request

Figure 114: View Schedule Request Sequence Diagram

3.14.4 Approve/Reject Schedule Request

Figure 115:  Approve/Reject Schedule Request Sequence Diagram

3.14.5 Create Schedule Request

Figure 116: Create Schedule Request Sequence Diagram

3.14.6 View Academic Request Detail

Figure 117: View Academic Request Detail Sequence Diagram

3.14.7 View List of Request

Figure 118: View List of Request Sequence Diagram

3.14.8 Create Academic Request

Figure 119: Create Academic Request Sequence Diagram

3.14.9 Accept/Reject Academic Request

Figure 120: Accept/Reject Academic Request Sequence Diagram

3.15. Attendance Configuration

3.15.1 Class Diagram

Figure 121: Attendance Configuration Class Diagram

3.15.2 Configure Attendance System

Figure 122: Configure Attendance System Sequence Diagram

3.15.3 View Attendance System Configuration

Figure 123: View Attendance System Configuration Sequence Diagram

3.16. Attendance Taking & Reporting

3.16.1 Class Diagram

Figure 124: Attendance Taking & Reporting Class Diagram

3.16.2 Update Attendance Manually

Figure 125: Update Attendance Manually Sequence Diagram

3.16.3 Register Face Recognition

Figure 126: Register Face Recognition Sequence Diagram

3.16.4 Scan Face Recognition Attendance

Figure 127: Scan Face Recognition Attendance Sequence Diagram

3.16.5 View Student Attendance Of Slot

Figure 128: View Student Attendance Of Slot Sequence Diagram

3.16.6 View Attendance Report

Figure 129: View Attendance Report Sequence Diagram

3.16.7 View Attendance Statistics by Class

Figure 130: View Attendance Statistics by Class Sequence Diagram

3.16.8 Export Attendance Statistics by Class

Figure 131: Export Attendance Statistics by Class Sequence Diagram

3.17. Lecturer Teaching Workspace

3.17.1 Class diagram

Figure 132: Class Diagram for Lecturer Teaching Workspace

3.17.2. View Teaching Classes

Figure 133: View Teaching Classes Sequence Diagram

3.17.3. View Teaching Classes Detail

Figure 134: View Teaching Classes Detail Sequence Diagram

3.17.4  Create Assignment for Slot

Figure 135: Create Assignment for Slot Sequence Diagram

3.17.5. View Detail Assignment

Figure 136: View Detail Assignment Sequence Diagram

3.17.6  Update Assignment for Slot

Figure 137: Update Assignment for Slot Sequence Diagram

3.17.7. Delete Assignment for Slot

Figure 138: Delete Assignment for Slot Sequence Diagram

3.17.8. View List Of Assignment

Figure 139: View List Of Assignment Sequence Diagram

3.17.9. Comment Student's Assignment

Figure 140: Comment Student's Assignment Sequence Diagram

3.18. Student Learning Workspace

3.18.1 Class Diagram

Figure 141: Class Diagram for Student Teaching Workspace

3.18.2 View Personal Timetable

Figure 142: View Personal Timetable

3.18.3 View Study Slot Detail

Figure 143: View Study Slot Detail

3.8.4 Save Timetable to Calendar

Figure 144: Save Timetable to Calendar

3.18.5 View List Of Assignment for Class

Figure 145: View List Of Assignment for Class

3.18.6 Submit Assignment

Figure 146: Submit Assignment

3.19. Grading & Assessment

3.19.1 Grading & Assessment Class Diagram

Figure 147: Grading & Assessment Class Diagram

3.19.2 Import Class's Component Grade

Figure 148: Import Class's Component Grade Sequence Diagram

3.19.3 Send Class's Component Grade

Figure 149: Send Class's Component Grade Sequence Diagram

3.19.4 Import Final Exam Grade Diagram

Figure 150: Import Final Exam Grade Sequence Diagram

3.19.5  Import Resit Exam Grade Diagram

Figure 151: Import Resit Exam Grade Sequence Diagram

3.19.6 Publish Grade Diagram

Figure 152: Publish Grade Sequence Diagram

3.19.7 View Total Grade Report Diagram

Figure 153: View Total Grade Report Sequence Diagram

3.19.8 View Detail Course Grade Diagram

Figure 154: View Detail Course Grade Sequence Diagram

3.20. Class Communication

3.20.1 Class Diagram

Figure 155: Class Communication Class Diagram

3.20.2 Create chat group

Figure 156: Create Chat Group Sequence Diagram

3.20.3 Chat

Figure 157: Chat Sequence Diagram

3.21. AI Support Service

3.21.1 Class digram

Figure 157: AI Support Service Class Diagram

3.21.2 Interact with AI Chatbox Sequence Diagram

Figure 158: AI Support Service Sequence Diagram

3.21.2 View List AI Tools

Figure 159: View List AI Tools Sequence Diagram

3.21.2 Active/ Inactive AI Tools

Figure 160: Active/ Inactive AI Tools Sequence Diagram

3.21.2 Test Tools AI

Figure 160: Test Tools AI Sequence Diagram

3.21.2 Check Assignment Similarity

Figure 161:  Check Assignment Similarity Sequence Diagram