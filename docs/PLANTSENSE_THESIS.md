# PlantSense - Graduation Project Thesis / System Specification

Kingdom of Saudi ArabiaMinistry of EducationJouf UniversityCollege of Computer and Information Sciences

In fulfillment of the requirements for the degree of

Bachelor in Computer Science

PlantSense Monitoring System

PROJECT SUPERVISORDr.Khulud Salem Alshudukhi

GROUP MEMBERS

Mariam Khalaf Al-ruwaili

441206003

Ghadi sultan alouthah

441205938

Alanoud Alkhmees

441206022

Raghad Khaled Al-Ruwaili

431205620

2026

PROJECT IN BRIEF

Project title:

PlantSense Monitoring System.

Organization:

Jouf University College of Computer and Information Sciences

Objectives:

To help urban farmers, home gardeners, and schools monitor and manage vertical plant growth using smart automation, image tracking, and data analysis.

Undertaken By:

Ghadi sultan alouthah, Mariam Khalaf Al-ruwaili, Raghad Khaled Al-Ruwaili, Alanoud Alkhmees.

Supervised By

Dr.Khulud Salem Alshudukhi

Date Started:

1/02/2026

Date Completed:

00/00/2026

Technologies Used:

SCRUM Method, UML Language, Microsoft PowerPoint, Microsoft Word, Edraw Max, draw.io

Operating System:

Windows 10

System Used:

HUAWEI

ACKNOWLEDGEMENT

We would like to thank our supervisor, Dr. Kholoud Salem Saleh Al-Shadoukhi, for her guidance and continuous support throughout this project. Her feedback and encouragement were a great help in bringing this work to completion.

We also thank all members of the project evaluation committee for taking the time to review our work and provide valuable feedback.

We are grateful to our families for their endless support and encouragement throughout our studies.

We extend our deepest gratitude to our generous families and dear guardians who contributed to our education and provided for our comfortable learning needs.

Finally, we thank everyone who helped us during our time at university.

DECLARATION

We declare that this project is our own original work and has not been copied from any other source, in whole or in part. We have written this report and developed this system ourselves. If any part is found to be taken from another source without proper reference, we accept full responsibility.

CERTIFICATION

It is certified that the contents and form of the project are entitled Design and Development of The PlantSense Monitoring System submitted by  Ghadi sultan alouthah, Mariam Khalaf Al-ruwaili, Raghad Khaled Al-Ruwaili, Alanoud Alkhmees.                                       been found satisfactory for the requirements.

For the award of the degree of         Bachelor in Computer Science

Supervisor: Dr.Khulud Salem Alshudukhi

Committee Member 1: Ghadi sultan alouthah.

Committee Member 2:Mariam Khalaf Al-ruwaili.

Committee Member 3: Alanoud Alkhmees.

Committee Member 4 : Raghad Khaled Al-Ruwaili.

Dated: 1/2/2026

ABSTRACT

The PlantSense Monitoring System (PSMS) is a mobile and web application that uses IoT cameras and AI to help users monitor and care for their vertical plants. The system places a dedicated camera on each plant and uses an AI engine to watch it around the clock. When the AI spots any sign of a problem such as wilting, yellowing leaves, or pests, it sends an instant notification to the user. Beyond monitoring, PSMS automatically creates a care schedule for each plant based on its species, keeps a full photo history of its growth, and provides an analytics dashboard with reports. The system also includes a public Plant Encyclopedia that anyone can browse without creating an account, making PSMS both a plant monitoring tool and a knowledge resource.

CONTENTS

PROJECT IN BRIEFii

ACKNOWLEDGEMENTiii

DECLARATIONiv

CERTIFICATIONv

ABSTRACTvi

CONTENTSvii

LIST OF FIGURESix

LIST OF TABLESx

ABBREVIATIONxi

CHAPTER 1:PROJECT OVERVIEW 12

1.1Introduction12

1.2Project Scope12

1.3Problem Description13

1.4  Comparative Analysis

1.4Proposed Solution14

1.5Proposed System Components14

1.6Main Features of the Proposed System15

1.7Conclusion16

CHAPTER 2: SYSTEM ANALYSIS17

2.1Introduction17

2.2Requirements17

2.3Specification Requirements18

2.1Functional Requirements18

2.2Non-Functional Requirements23

2.3Use Case Diagram24

2.4General Constraints26

2.5Product Requirements27

2.6Conclusion28

CHAPTER 3: SYSTEM DESIGN

3.1  Introduction29

3.2  SCRUM Methodology29

3.3  Product Backlog30

3.4  Sprints Backlogs31

3.5  Sequence Diagrams32

3.6  Activity Diagrams

3.7  Class Diagram

3.8  Entity Relationship Diagram

3.10  Data Dictionary

CHAPTER 4: FUTURE WORK

4.1  Introduction to Future Development

REFERENCES49

LIST OF FIGURES

Figure 1.1    PlantSense Monitoring System Architecture Overview

Figure 1.2    PSMS System Architecture — Frontend, Middleware, and Backend Layers

Figure 2.1    PSMS System-Level Use Case Diagram

Figure 3.5.1    Farmer / User Sequence Diagram

Figure 3.5.2    Administrator Sequence Diagram

Figure 3.5.3    Viewer / Guest Sequence Diagram

Figure 3.6.1    Live Camera and AI Health Detection Activity Diagram

Figure 3.6.2    View Plant List Activity Diagram

Figure 3.6.3    Generate Care Schedule Activity Diagram

Figure 3.6.4    User Registration Activity Diagram

Figure 3.6.5    Browse Plant Encyclopedia Activity Diagram

Figure 3.6.6    Admin Manage Encyclopedia Entry Activity Diagram

Figure 3.7    Class Diagram

Figure 3.8    Entity Relationship Diagram

LIST OF TABLES

Table 1.1    Comparative Analysis of PSMS Against Existing Solutions

Table 2.1    Software Requirements

Table 2.2    Hardware Requirements

Table 3.1    Product Backlog

Table 3.2    Sprints Backlogs

Table 3.5.1    Farmer / User Sequence Diagram Summary

Table 3.5.2    Administrator Sequence Diagram Summary

Table 3.5.3    Viewer / Guest Sequence Diagram Summary

Table 3.10.1    Data Dictionary — USER

Table 3.10.2    Data Dictionary — PLANT

Table 3.10.3    Data Dictionary — GROWTH_RECORD

Table 3.10.4    Data Dictionary — CARE_SCHEDULE

Table 3.10.5    Data Dictionary — NOTIFICATION

Table 3.10.6    Data Dictionary — ANALYTICS

Table 3.10.7    Data Dictionary — CARE_HISTORY

Table 3.10.8    Data Dictionary — IOT_CAMERA

Table 3.10.9    Data Dictionary — HEALTH_EVENT

Table 3.10.10    Data Dictionary — ENCYCLOPEDIA_ENTRY

ABBREVIATION

Abbreviation

Full Name

PSMS

PlantSense Monitoring System

IoT

Internet of Things

UI / UX

User Interface / User Experience

API

Application Programming Interface

DB

Database

SCRUM

Agile Software Development Framework

UML

Unified Modeling Language

MVP

Minimum Viable Product

RBAC

Role-Based Access Control

KPI

Key Performance Indicator

ER

Entity Relationship (Diagram)

FR

Functional Requirement

NFR

Non-Functional Requirement

FCM

Firebase Cloud Messaging

HTTPS

Hypertext Transfer Protocol Secure

TLS

Transport Layer Security

SMTP

Simple Mail Transfer Protocol

AI

Artificial Intelligence

ML

Machine Learning

CNN

Convolutional Neural Network

CRUD

Create, Read, Update, Delete

DFD

Data Flow Diagram

ChapterChapter11

Chapter

Chapter

1

1

PROJECT OVERVIEW

Introduction

Vertical farming is a method of growing plants in stacked layers inside controlled indoor spaces. It is becoming more popular because it allows people to grow fresh food in apartments, schools, offices, and other places where there is no outdoor space. As cities grow and outdoor farming becomes harder, vertical farming offers a practical and space-efficient alternative.

However, managing a vertical farm is not simple. Each plant type needs a specific amount of water, light, and fertilizer, and these needs change over time. If a plant does not get what it needs, problems such as slow growth, yellowing leaves, disease, or pest damage can develop quickly. The challenge is that most growers cannot watch their plants all the time.

From our research, we found that most people doing home-based or small-scale vertical farming check on their plants manually when they remember to. They take occasional photos, write notes by hand, and only respond to a problem after they notice it themselves. There is no tool that watches the plant continuously, catches early warning signs, or sends an alert before the problem gets worse.

This is the problem we set out to solve. PSMS combines a live camera placed directly on each plant with an AI engine that monitors the plant at all times. Instead of waiting for the user to check on the plant, the system watches it continuously and sends an alert the moment it detects any change. This turns plant care from a manual task into an automated, system-driven process.

Project Scope

This project covers the full process of plant monitoring and care management. It starts when the user registers a plant and ends with long-term reporting on how the plant grew. The system uses a live camera and AI to watch the plant continuously, generate a care schedule, send alerts, and produce reports. The goal is that the user never has to manually check on their plant to know if something is wrong.

Plant Registration and Growth Tracking: Users add each plant to the system by entering basic details such as its name, species, planting date, and location. Once added, a camera is assigned to the plant and starts recording continuously. The AI analyzes each frame and logs any health issues it detects. Users can also upload photos manually and add notes to keep track of how the plant is developing.

Care Schedule Management: When a plant is added, the system automatically creates a care schedule based on its species. This schedule includes watering and fertilization reminders that are specific to that plant type. The AI also monitors the live camera feed and sends an immediate alert if it detects the plant needs care ahead of schedule, so the user is never relying only on fixed reminders.

Analytics and Reporting: The system provides a dashboard that shows the user a clear picture of each plant's health and growth over time. It includes growth charts, a log of AI-detected health events, and a care completion rate. Users can filter the data and export reports in PDF or CSV format.

The system also includes a public Plant Encyclopedia that any visitor can browse without creating an account. It contains information on different plant species including care tips, common health problems, and growing advice. The encyclopedia is managed by admins and is open to everyone, making the platform useful not just for registered users but also for anyone looking for plant care information.

Figure 1.1: PlantSense Monitoring System Architecture Overview

Literature Review

This section looks at existing apps and systems in the area of plant monitoring and care. We describe each system briefly, then compare them with PSMS in a table to show what features are missing and why PSMS is different.

1  Plantix

Plantix is an AI mobile app by PEAT GmbH that helps farmers and gardeners identify plant diseases and pests. The user takes a photo of the plant, and the app uses image recognition to detect possible problems and suggest treatments. Plantix is useful for disease identification, but it only works when the user takes a photo manually. It does not provide continuous live monitoring, automated care scheduling, or growth history [1].

2  Greg App

Greg is a houseplant care app that helps users remember when to water and care for their plants. After the user adds a plant, the app creates a care schedule based on the species and the user's local environment and sends reminders when tasks are due. Greg works well for watering reminders but does not offer live monitoring, AI health detection, or a growth image timeline [2].

3  GreenSnap

GreenSnap is a plant identification and community sharing app. Users can take a photo of a plant to identify its species and share it with other users. The app also has an AI feature that can flag possible health problems in uploaded photos and includes a searchable plant encyclopedia. However, GreenSnap does not support continuous monitoring, automated care schedules, or IoT camera integration [3].

4  SmartPlant

SmartPlant is a plant care app for both home gardeners and professional growers. Its main feature is a care schedule that sends reminders for watering, feeding, and pruning based on the registered plant species. It also supports push alerts for upcoming and overdue tasks. However, SmartPlant does not include live camera monitoring, AI health detection from continuous footage, a growth image timeline, or a public plant encyclopedia [4].

Comparative Analysis

None of the existing systems combines all the features that PSMS offers in one place. No other app provides continuous IoT-based live monitoring, AI-powered real-time health detection, species-specific automated care schedules, and a publicly accessible plant encyclopedia together. The table below compares PSMS against the most well-known solutions to show these differences clearly.

Table 1.1: Comparative Analysis of PSMS Against Existing Solutions

Feature

PSMS

Plantix

Greg App

GreenSnap

SmartPlant

IoT Live Camera Monitoring

Yes

No

No

No

No

AI Real-Time Health Detection

Yes

Yes

No

Yes

No

Auto Care Schedule (AI/ML)

Yes

No

Yes

No

Yes

Real-Time Push Alerts

Yes

Yes

Yes

No

Yes

Growth Image Timeline

Yes

No

No

Yes

No

Public Plant Encyclopedia

Yes

No

No

Yes

No

Guest Access (No Login)

Yes

No

No

Yes

No

Vertical Farming Focus

Yes

No

No

No

No

Analytics and Export Reports

Yes

No

No

No

Yes

Multi-Role Access Control

Yes

No

No

No

Yes

Educational Use Support

Yes

No

No

No

No

As the table shows, PSMS is the only system that includes all of these features together. While Plantix is good at detecting diseases and Greg handles care reminders well, none of them offers continuous live camera monitoring, a public plant encyclopedia with guest access, and support for vertical farming and educational use at the same time. This combination is what makes PSMS different.

Problem Description

Through research and observation of people doing home-based or small-scale vertical farming, we found four main problems that keep coming up. These problems are connected, and fixing only one of them would not give users a complete solution. These are the issues that shaped this project.

No Continuous or Automated Monitoring: Most growers can only check on their plants when they remember to. There is nothing actively watching the plant between visits. Problems like wilting, yellowing, pests, or dehydration can develop within hours, but without a live monitoring system, the user may not notice until it is too late.

Missed and Reactive Care: Care reminders based on a fixed schedule do not reflect what the plant actually needs at that moment. A plant may need water earlier than scheduled because of temperature or other conditions. Without live monitoring to catch visible signs of distress, no alert is sent. PSMS solves this by combining scheduled reminders with real-time AI monitoring.

No Data on Plant Health: Without continuous monitoring, users have no information to work with. They cannot tell if their plants are growing well, if a care change made things better or worse, or what is affecting their plants. PSMS captures continuous visual data and uses AI to turn it into clear, useful insights.

Limited Tools for Educational Use: Schools and universities that use vertical farming for teaching have no dedicated platform for tracking plant health, documenting experiments, or comparing results. Without automated monitoring and analysis, the learning value of these setups is limited.

No Public Plant Knowledge Resource: There is no single, free, and well-organized online platform focused on vertical farming plant care. People looking for species-specific information have to rely on scattered web searches or general gardening blogs, which often leads to poor or inaccurate care decisions.

Proposed Solution

PSMS solves these problems by combining IoT cameras and AI in one platform. At the center of the system is a live camera mounted directly on each plant. The camera feeds continuous footage to an AI engine that watches the plant around the clock and sends an instant notification if anything changes. The user does not need to check manually; the system does the watching for them.

Plant Growth Tracking Module: Users register each plant and can upload photos at different stages. Everything is saved in order by date, so users can scroll through the plant's full history and see how it has changed over time.

Intelligent Care Management Module: When a plant is added, the system creates a care schedule based on its species. It sends reminders before tasks are due and alerts if something is missed. Users can confirm when they complete a task, and the system keeps a record of what was done and what was skipped.

Analytics and Reporting Dashboard: This section shows the user a clear summary of each plant's growth and health over time. It includes growth charts, AI health event logs, care completion rates, and reports that can be exported.

Public Plant Encyclopedia Module: This part of the system is open to everyone, including visitors without an account. It contains information on different plant species including care needs, growing conditions, health issues, and tips. Admins are responsible for adding and updating the content.

Proposed System Components

PSMS is made up of several software components that work together. Each component handles a specific part of the system, and they communicate through internal connections. This structure makes it easier to develop and update each part separately.

Figure 1.2: PSMS System Architecture — Frontend, Middleware, and Backend Layers

Component 1: Plant Management Module

This module stores and manages all plant profiles and their growth history. When a user adds a plant, this module saves its species, location, and care details. It also stores all the timestamped images captured by the camera, keeping them organized so the user can view the plant's visual history at any time.

Component 2: Care Scheduling Engine

When a plant is added, this module automatically creates a care schedule using AI. Watering and fertilization schedules are set based on the specific plant species since different plants have different needs. Disease and pest monitoring, however, applies to all plants the same way since these problems are not species-specific. A background process checks task deadlines and triggers the right notifications. If the AI camera detects a problem, it can send an alert right away without waiting for the scheduled reminder.

Component 3: Analytics and Dashboard Module

This module takes all the data from the camera, AI engine, and care logs and turns it into useful charts and reports. It shows how the plant has grown over time, logs all health events detected by the AI, calculates how often care tasks were completed, and lets users export a full summary of their plant's history.

Component 4: Notification Engine

This module sends all alerts and reminders to the user through push notifications on the phone and alerts inside the app. It receives inputs from two sources: the care schedule (which triggers time-based reminders) and the AI engine (which sends immediate alerts when a problem is detected). All notifications are saved so users can review them later.

Component 5: IoT Camera Module

A camera is placed directly on each plant and streams live footage to the system continuously. It captures the plant's condition at regular intervals and sends the images to the AI engine for analysis. In the current prototype, manual image uploads are used instead of a physical camera to allow testing of all features without needing hardware.

Component 6: AI Analysis Engine

This is the AI part of the system. It analyzes images from the camera using machine learning to detect signs of plant stress such as wilting, yellowing, dehydration, or pest activity. When it finds a problem, it immediately notifies the user through the Notification Engine. This module works around the clock and does not require the user to do anything.

Component 7: User Account and Security Module

This module handles user accounts, login, and access control. There are three user roles: Admin, who manages accounts and encyclopedia content; Farmer, who has full access to all features; and Viewer/Guest, which covers both registered users who can only view data and unregistered visitors who can browse the public encyclopedia. Passwords are stored securely and sessions are managed using token-based authentication.

Component 8: Plant Encyclopedia Module

This module manages the public plant encyclopedia. It is open to all visitors without login and provides a read-only view of plant species information. Admins can add, edit, and delete entries through a management interface. Each entry includes the species name, care requirements, known diseases, pest information, and growing tips. When a user registers a plant, this module provides the species data used to automatically set up the care schedule.

Main Features of the Proposed System

PSMS includes a set of features that work together to provide a complete plant monitoring and care solution. These features are designed to be easy to use for anyone, whether they are a home gardener, a student, or a professional farmer:

Plant profile registration where users enter the plant name, species, planting date, location, and assigned camera. This creates a searchable record that the system uses for monitoring and analytics.

Continuous live camera monitoring that automatically captures and saves images of the plant over time, organized by date with side-by-side comparison and a complete visual history, all without any manual effort from the user.

Observation note logging that lets users write notes about what they observe and link them to specific dates, making it easy to track changes and review past records.

AI health detection that continuously analyzes the live camera feed and automatically identifies problems such as wilting, yellowing, dehydration, pests, or disease. Each detected event is logged with a timestamp and immediately triggers a user alert.

Automated care schedule based on the plant's species that covers watering and fertilization, with reminders that are also informed by what the live camera is detecting in real time.

A complete care and AI event log that keeps a record of all completed and missed tasks alongside every health event detected by the AI, helping users understand care patterns and identify gaps.

A smart notification system that sends instant alerts when the AI detects a problem and scheduled reminders for upcoming or overdue tasks, delivered through mobile push notifications and in-app alerts.

An analytics dashboard with charts showing plant growth, AI health events, and care completion rates, updated automatically as new data comes in from the camera and AI engine.

Filtering and comparison tools that let users analyze their plants' health and growth by date range, plant type, or species, supporting better care decisions over time.

A public Plant Encyclopedia that anyone can browse without an account, containing searchable plant species profiles with care information, common problems, and growing advice.

Role-based access control with three permission levels — Admin, Farmer, and Viewer — so the system can be used safely in personal, professional, and educational settings.

Conclusion

This chapter introduced the PlantSense Monitoring System and explained the four main problems it is designed to solve: the lack of continuous plant monitoring, reactive care routines, no data-driven health insights, and the absence of good tools for educational use. The core idea of the system is a live IoT camera mounted on the plant, feeding footage to an AI engine that monitors the plant around the clock.

The system is made up of eight connected modules: the IoT Camera, AI Analysis Engine, Care Scheduling, Analytics, Notification, Plant Management, User Account, and Encyclopedia modules. Three user roles are supported: Admin, Farmer, and Viewer/Guest. The following chapters cover the system analysis and technical design in detail.

ChapterChapter22

Chapter

Chapter

2

2

SYSTEM ANALYSIS

Introduction

In this chapter, we move from the general idea described in Chapter 1 to a clear and specific set of requirements that define exactly what the system needs to do. System analysis is the step that connects the problem statement to the technical design, so it is important to be thorough and precise here.

We started by identifying who will use the system and what each type of user needs. This led us to define three user types: the Farmer, the Administrator, and the Viewer/Guest. The Viewer/Guest role covers both registered users who can only view data and unregistered visitors who can access the public Plant Encyclopedia. Understanding what each user needs was the first step in defining the system's requirements.

From there, we created a full list of functional requirements organized into six areas: user accounts, plant management, growth tracking, care schedules, notifications, and analytics. We also defined non-functional requirements that set the quality standards the system must meet. Use case diagrams then gave a visual view of how each user type interacts with the system.

Software and Hardware Requirements

This section lists the tools and technologies needed to build and run PSMS. It covers the software used to build the mobile and web interfaces, the backend, and the database, as well as the hardware devices needed for development and testing.

Table 2.1: Software Requirements

Category

Details

Mobile Frontend

Cross-platform mobile framework Android & iOS

Web Frontend

Responsive web application with modern UI framework

Backend API

RESTful JSON API using a server-side runtime environment

Database

Relational database local or hosted on free-tier cloud

Image Storage

Local filesystem for prototype; cloud object storage for production

Push Notifications

Mobile push notification service

Authentication

Token-based session management with hashed passwords

Dev Tools

Code editor, version control, API testing tools, diagramming tools

Table 2.2: Hardware Requirements

Category

Details

Hardware (Dev)

Standard laptop or desktop, Windows 10 or above

Hardware (User)

Android or iOS smartphone; any modern browser for web access

Requirements

Farmer / User: The main user of the system. The Farmer registers plants, assigns cameras, receives AI health alerts, manages care tasks, views live monitoring, and accesses analytics. This role covers home gardeners, urban farmers, and students.

Administrator: Manages user accounts, assigns roles, and oversees the system. In an educational setting, this is usually a teacher or IT administrator who is responsible for the platform and its hardware.

Viewer / Guest: A read-only role with two levels. Registered Viewers can browse plant profiles, view health event logs, and check analytics but cannot make any changes. Guest users, who do not need an account, can browse and search the public Plant Encyclopedia freely.

Plant Registration Specifications

The plant registration form must collect the plant name, species, planting date, location, and the ID of the assigned camera. Each plant gets a unique ID and can be created, edited, viewed, or deleted. When a plant is registered, the system automatically starts the camera and the AI monitoring pipeline for that plant.

Image and Observation Tracking

The camera streams live footage and each image is saved automatically with a timestamp and linked to the plant profile. The AI checks each image for health issues and logs any problems it finds. Users can scroll through all images, compare two images side by side, and add observation notes that can be searched by keyword. In the prototype, manual image uploads replace the live camera stream.

Care Schedule and Notifications

When a plant is added, the AI creates a care schedule based on the plant's species. The schedule covers watering, lighting, fertilization, and humidity. Each task has a due date and a completion status. The system sends reminders before tasks are due and follow-up alerts if something is missed. The AI also watches the live camera feed and sends an immediate alert if it sees the plant needs care before the next scheduled task.

Analytics

The analytics dashboard shows the total days of growth, care task completion rate, AI health event history with timestamps and severity levels, response time to alerts, and a plant health consistency score. All data updates automatically. Users can filter by date range, plant, or species.

User Accounts

To register, a user needs a unique email address, a username, and a password. Passwords are stored in encrypted form and never saved as plain text. Login creates a session token that expires after a set time. Users can reset their password through an email link. Admins can create accounts, change roles, and deactivate users without deleting their data.

Functional Requirements

The functional requirements describe what the system must be able to do to meet user needs. They are grouped into six areas, each covering a different part of the system. Each requirement has a unique ID and a priority level: High, Medium, or Low.

FR-1: User Account Management

ID

Requirement

Description

Priority

FR-1.1

User Self-Registration

The system must let new users create an account using a unique username, email address, and password that meets basic security requirements.

High

FR-1.2

Secure Login

The system must let users log in with their email and password and receive a session token when login is successful.

High

FR-1.3

Password Reset via Email

The system must let users reset their password through a secure link sent to their registered email address.

Medium

FR-1.4

Admin: Create & Manage Accounts

The Admin must be able to create new user accounts, assign roles, deactivate accounts, and reactivate them without losing any data.

High

FR-1.5

Profile & Notification Preferences

Users must be able to update their personal details and choose which types of notifications they want to receive and how.

Low

FR-2: Plant Management

ID

Requirement

Description

Priority

FR-2.1

Register New Plant

The system must let Farmers create a plant profile with a name, species, planting date, location, and initial notes.

High

FR-2.2

Edit Plant Profile

The system must let users edit any detail of a plant profile they have already registered.

Medium

FR-2.3

View Plant List

The system must show all plants registered by the logged-in user in a list that can be searched, filtered, and sorted.

High

FR-2.4

Delete Plant

The system must let users delete a plant profile after confirming the action, and all related records must be removed permanently.

Low

FR-2.5

Search & Filter Plants

The system must provide a search feature that lets users find plants by name, species, or date range.

Medium

FR-3: Growth Tracking

ID

Requirement

Description

Priority

FR-3.1

Live Camera Monitoring

The camera must continuously capture and stream live footage of the plant. Each image must be saved automatically with a timestamp. In the prototype, manual image upload replaces the live stream.

High

FR-3.2

View Chronological Image Gallery

The system must display all images of a plant in order from oldest to newest in a scrollable gallery.

High

FR-3.3

AI Health Detection and Notes

The AI engine must continuously check the camera images and log any health problems it detects such as wilting, yellowing, dehydration, or pest activity, along with the time they were detected. Users can also add their own written notes linked to specific dates.

High

FR-3.4

Compare Growth Stages

The system must let users pick two dates and view the plant images from those dates side by side.

Medium

FR-3.5

Delete Growth Record

Users must be able to delete individual images or notes from a plant's history.

Low

FR-4: Care Schedule Management

ID

Requirement

Description

Priority

FR-4.1

Auto-Generate Care Schedule

The system must automatically create a care schedule for each plant using AI. Watering and fertilization schedules are based on the specific plant species since each plant has different needs. Disease and pest monitoring is applied to all plants equally since these problems are not specific to one species. The schedule combines species-specific watering and fertilization reminders with continuous AI-based health monitoring for all plants.

High

FR-4.2

View Upcoming Tasks

The system must show all upcoming care tasks for each plant in order of due date in a clear and easy-to-read list.

High

FR-4.3

Mark Task as Completed

The system must let users mark a care task as done, and the system must save the date and time it was completed.

High

FR-4.4

View Care Task History

The system must show a history of completed and missed care tasks for each plant with dates and their status.

Medium

FR-4.5

Manually Add Custom Task

The system must let users create their own care tasks for a specific plant if they need something not covered by the automatic schedule.

Low

FR-5: Notifications and Alerts

ID

Requirement

Description

Priority

FR-5.1

Real-Time AI Alert and Task Notification

The system must send real-time push notifications when the AI detects any change in the plant's condition that needs attention, as well as scheduled reminders before care tasks are due.

High

FR-5.2

In-App Alert for Due Tasks

The system must show in-app alerts for AI health events and for care tasks that are due or overdue when the user is active in the app.

High

FR-5.3

Missed Task Alert

The system must send a notification when a care task is not completed by its due date.

Medium

FR-5.4

Configure Notification Preferences

Users must be able to turn specific notification types on or off and set how early they want to receive reminders.

Low

FR-6: Analytics Dashboard

ID

Requirement

Description

Priority

FR-6.1

Display Growth Progress Charts

The system must generate charts that show how the plant has grown over time based on the images captured by the camera, with AI-detected health events shown as markers on the chart.

High

FR-6.2

Show Care Compliance Rate

The system must calculate and display the percentage of care tasks that were completed on time for each plant.

Medium

FR-6.3

Filter Analytics by Plant / Date

The system must let users filter all dashboard data by plant, species category, or a custom date range.

Medium

FR-6.4

Comparative Plant Analytics

The system must let users compare the growth data of two or more plants in a single view.

Low

FR-6.5

Export Growth Report

The system must let users create and download a growth report for a selected plant in PDF or CSV format.

Low

Non-Functional Requirements

1. Performance

Main pages must load within 3 seconds on a normal internet connection. The analytics dashboard may take up to 5 seconds. All API responses must come back within 2 seconds. The system must be able to handle at least 100 users at the same time without slowing down.

2. Usability

The interface must be simple enough for a user with no technical experience. Navigation should be straightforward, and a first-time user should be able to add a plant and complete a care task without needing a tutorial. The mobile version must work well with one hand on a standard phone screen.

3. Security

Passwords must be hashed before being stored plain text passwords are never saved. User sessions expire after 24 hours by default. All communication between the app and the server must use HTTPS. The system must also protect against common threats like SQL injection and cross-site scripting.

4. Reliability

The system must be available at least 99% of the time during the semester. The database must be backed up every day and stored in a separate location. If one part of the system has a problem, the rest should continue working. If a notification fails to send, the system must retry automatically.

5. Compatibility

The mobile app must work on Android 8.0 and above and iOS 13 and above. The web app must work correctly on Chrome, Firefox, Safari, and Edge. The layout must display properly on screen widths from 320px to 2560px.

6. Scalability

The backend must be designed so it can support more users in the future without needing to be rewritten. The database must use proper indexing to stay fast as the data grows. Image storage must be ready to move to a cloud service if needed.

Use Case Diagram

The system-level use case diagram below shows all user types and how they interact with the different parts of PSMS. It covers the Farmer, Administrator, Viewer/Guest, and the IoT Camera and AI System. Individual diagrams for each user type are shown in the sections that follow.

Figure 2.1: PSMS System-Level Use Case Diagram

1. Farmer / User Use Case Diagram

The Farmer is the main user of PSMS. After logging in, the Farmer can register plants, assign cameras, view the live camera feed, receive AI health alerts, browse the health event log, add notes, compare growth images, complete care tasks, receive reminders, view the analytics dashboard, export reports, and browse the public Plant Encyclopedia. Two key use cases stand out: receiving real-time AI alerts, which is triggered automatically by the AI engine and does not require any action from the Farmer; and encyclopedia browsing, which is available to all users including guests.

2. Administrator Use Case Diagram

The Admin use case diagram shows everything the Administrator can do in the system. The Admin can create user accounts, assign roles, deactivate or reactivate profiles, view all users, set up IoT camera settings, check system health, run database backups, and manage the entire Plant Encyclopedia by adding, editing, or deleting species entries. Creating a user account always includes assigning a role, so these two actions are connected.

3. Viewer / Guest Use Case Diagram

The Viewer/Guest diagram covers two access levels in one role. Registered Viewers can log in and browse plant profiles, view AI health event logs, follow growth timelines, and check analytics, but they cannot make any changes. Guest users do not need an account and can freely browse and search the public Plant Encyclopedia and view individual species profiles.

General Constraints

The project was built within a set of real limitations that affected both what we built and how we built it. Being transparent about these constraints helps explain the design decisions made throughout the project and sets realistic expectations for what the current version can do.

Time: We had one semester to complete this project roughly three and a half months. That meant we had to focus on the most important features first and leave some ideas, like AI-based disease detection and IoT sensor integration, for a future version.

Resources: We used our personal laptops and university facilities. We had no access to dedicated servers or cloud credits. To work around this, we tested the system locally and used open-source tools throughout development.

Budget: This is a university project with no external funding. All tools and services we used are either free or open-source. We chose technologies based on availability and long-term reliability, not commercial preferences.

Technical Scope: We decided not to include physical sensor integration in this version. All data entry is done manually by the user. However, we designed the database and API so that sensor data could be added in the future without rebuilding the system from scratch.

Product Requirements

Role-based user management Admin, Farmer, and Viewer with separate permissions.

Full plant profile management including species, date, location, and cover photo.

Timestamped photo uploads with gallery and side-by-side comparison.

Searchable observation notes linked to dates.

Automatic care schedule based on plant species with reminders.

Push notifications and in-app alerts for tasks due and tasks missed.

Complete care task log showing what was done and what was skipped.

Analytics dashboard with growth charts and care compliance data.

Filter and compare plants and time periods in the analytics view.

Export reports in PDF or CSV format.

Conclusion

In this chapter, we covered all aspects of system analysis. We identified three user types — Farmer, Admin, and Viewer/Guest — and described what each one needs from the system. The Viewer/Guest role is unique because it serves both registered read-only users and unregistered public visitors who access the Plant Encyclopedia.

We defined 24 functional requirements across six areas: user accounts, plant management, growth tracking, care schedules, notifications, and analytics. We also set quality standards through six non-functional requirement categories covering performance, usability, security, availability, compatibility, and scalability.

Use case diagrams show how each user type interacts with the system. The constraints section explains the limitations we worked within, mainly time, resources, and budget.

With all requirements and constraints documented, the next step is the system design phase, where we create the database model, class diagrams, sequence diagrams, and the full technical architecture.

ChapterChapter33

Chapter

Chapter

3

3

SYSTEM DESIGN

3.1  Introduction

This chapter covers the full technical design of PSMS. The goal is to take the requirements from Chapter 2 and turn them into a complete design plan that can guide the development process.

This chapter walks through the technical design of PSMS step by step. It starts with the SCRUM agile method and the product and sprint backlogs that organized our work. Then it presents the full set of UML design diagrams: sequence diagrams that show how the system's modules communicate during key user actions, activity diagrams that show the step-by-step logic of important workflows, a class diagram that shows the system's structure, an ER diagram that shows the database design, and a data dictionary that describes every field in the database.

3.2  SCRUM Methodology

We used SCRUM to manage the development of PSMS. SCRUM breaks work into short focused periods called sprints, each lasting one to two weeks. At the start of each sprint, the team picks a set of tasks from the overall task list and commits to finishing them within that period. At the end of each sprint, the team reviews what was done and updates the plan for the next one.

SCRUM was a good fit for this project because combining IoT hardware, an AI engine, and a multi-role software platform involves a lot of complexity that is hard to plan for all at once. The sprint-based approach let us adjust requirements as we learned more, test things early, and always focus on the most important features first.

Product Backlog: A full list of everything the system needs to do, organized by priority. It is kept up to date throughout development so the team always knows what still needs to be done.

Sprint Backlog: A focused subset of items selected from the Product Backlog and committed to delivery within a single sprint. It provides the development team with a concrete, time-bounded target for each work cycle and serves as the primary basis for daily progress tracking and accountability.

3.3  Product Backlog

The table below shows all user stories for the system, sorted by priority. High-priority items were worked on first in the early sprints.

ID

User Story

Priority

1

As an Admin, I can create user accounts and assign roles so users can access the system.

High

2

As a general user, I can log in to the system to access my features.

High

3

As a general user, I can reset my password if I forget it.

Low

4

As a Farmer, I can add a new plant with its name, species, date, and location.

High

5

As a Farmer, I can view all my registered plants in a searchable list.

High

6

As a Farmer, the IoT camera automatically captures and streams live footage of my plant so I can track visual changes continuously without manual uploads.

High

7

As a Farmer, I can add written observation notes linked to specific dates.

High

8

As a Farmer, I can compare two plant photos side by side to see growth progress.

Medium

9

As a Farmer, I want the AI engine to automatically create a species-specific care schedule when I register a plant and send real-time alerts when the live camera detects my plant needs immediate attention.

High

10

As a Farmer, I can view upcoming care tasks sorted by due date.

High

11

As a Farmer, I can mark a care task as done and the system logs the time.

High

12

As a Farmer, I can see a history of completed and missed care tasks.

Medium

13

As a Farmer, I can add custom care tasks not covered by the default schedule.

Low

14

As a Farmer, I want to receive real-time push notifications when the AI detects any health change in my plant, as well as reminders before scheduled care tasks are due.

High

15

As a Farmer, I want to be alerted when a care task is overdue.

Medium

16

As a Farmer, I can view growth charts and care compliance data on a dashboard.

High

17

As a Farmer, I can filter analytics by plant or date range.

Medium

18

As a Farmer, I can compare two plants' growth data side by side in analytics.

Low

19

As a Farmer, I can export a plant growth report in PDF or CSV format.

Low

20

As a Viewer, I can browse plant profiles, AI health event logs, and analytics without editing anything.

21 | As a Viewer/Guest, I can browse the public Plant Encyclopedia and search for species information without creating an account, so I can learn about plant care freely. | High

22 | As a Viewer/Guest, I can view a full plant species profile with care requirements, growing conditions, and health tips without needing an account. | High

23 | As an Admin, I can create, edit, and delete plant species entries in the encyclopedia through a dedicated content management interface. | High

24 | As a Farmer, when I register a plant and select a species from the encyclopedia, the system automatically pre-populates my care schedule with the correct parameters. | Medium

Medium

Table 3.1: Product Backlog

3.4  Sprints Backlogs

The product backlog was split into seven sprints. Each sprint focused on one part of the system and took about one to two weeks to complete.

Sprint

User Story

Tasks

Actor

Sprint 1

As an Admin, I want to create user accounts with defined roles.

Design login page UI Build registration form Implement role assignment Hash and store passwords

Admin

Sprint 1

As a user, I want to log in and reset my password.

Build login with JWT authentication Implement password reset via email link

All Users

Sprint 2

As a Farmer, I want to add and manage plant profiles.

Create plant registration form Build plant list view with search/filter Implement edit and delete plant

Farmer

Sprint 3

As a Farmer, I want the IoT camera to automatically capture plant images and the AI to analyze them for health issues.

Build image upload with timestamp Create gallery view per plant Build observation notes form Implement side-by-side comparison view

Farmer

Sprint 4

As a Farmer, I want the AI to generate a care schedule and send real-time alerts when the live camera detects my plant needs care.

Build AI-powered species care knowledge base Auto-generate care schedule using ML Save tasks to care_schedule table Implement AI real-time alert trigger from camera feed

Farmer

Sprint 5

As a Farmer, I want to view, complete, and track care tasks.

Build upcoming tasks list view Implement mark-as-done with timestamp Build care history log per plant Allow custom task creation

Farmer

Sprint 6

As a Farmer, I want to receive notifications for care tasks.

Integrate push notification service Set up background task scheduler Build in-app alert for overdue tasks Build notification settings screen

Farmer

Sprint 7

As a Farmer, I want an analytics dashboard with charts and reports.

Sprint 8 | As a Visitor, I can browse and search the public Plant Encyclopedia. As an Admin, I can manage all encyclopedia entries. | Build public encyclopedia browse and search UI. Build species profile detail page. Build Admin content management interface for encyclopedia entries. Implement encyclopedia-to-care-schedule auto-population on plant registration. | Visitor / Admin / Farmer

Build growth progress charts Calculate care compliance rate Add plant comparison feature Implement PDF/CSV export

Farmer / Viewer

Table 3.2: Sprints Backlogs

3.5  Sequence Diagrams

Sequence diagrams show how different parts of the system communicate with each other during a specific action. They show the order in which things happen and how data moves between modules. Each diagram follows one user type through a complete interaction from start to finish.

1  Farmer / User Sequence Diagram

This diagram follows a Farmer through a complete session: logging in, viewing the plant list, receiving a real-time AI alert triggered by the camera, checking the care schedule, marking a task as done, and viewing the analytics dashboard. It shows how the Login Service, Plant Module, IoT Camera, AI Engine, Care Schedule Module, Notification Engine, and Analytics Module interact in sequence to support the Farmer's actions.

Figure 3.5.1: Farmer / User Sequence Diagram

Field

Details

Use Case

Farmer / User Session

Primary Actor

Farmer / User

Level

High

Modules Involved

Login Service, Plant Module, Care Schedule Module, Analytics Module, Database

Normal Flow

1. Enter credentials → validate → login confirmed 2. View plant list → fetch from DB → display 3. Upload image → save with timestamp → gallery updated 4. View care schedule → fetch tasks → display upcoming 5. Mark task done → update status → confirmed 6. View analytics → fetch records → show charts

Key Messages

Enter credentials, Validate, Login confirmed, Upload image, Save record, Mark complete, Show charts

Table 3.5.1: Farmer / User Sequence Diagram Summary

3.5.2  Administrator Sequence Diagram

This diagram shows the Admin's typical workflow: logging in, viewing the user list, creating a new account with a role, updating a user's role, and running a database backup. It covers the Auth Service, User Management Module, Backup Service, and Database.

Figure 3.5.2: Administrator Sequence Diagram

Field

Details

Use Case

Administrator Management Session

Primary Actor

Administrator

Level

High

Modules Involved

Auth Service, User Management Module, Backup Service, Database

Normal Flow

1. Enter credentials → validate → login confirmed 2. View all users → fetch list → display 3. Create user → save with role → confirmed 4. Update role → change permissions → confirmed 5. Initiate backup → run backup → backup complete

Key Messages

Login, View user list, Create account, Assign role, Update permissions, Backup completed

Table 3.5.2: Administrator Sequence Diagram Summary

3.5.3  Viewer / Guest Sequence Diagram

This diagram shows how a Viewer uses the system: logging in, browsing the plant list, opening a plant profile, viewing the image gallery, and checking the analytics dashboard. The Viewer cannot add, edit, or delete anything; all actions are read-only.

Figure 3.5.3: Viewer / Guest Sequence Diagram

Field

Details

Use Case

Viewer Read-Only Session

Primary Actor

Viewer / Guest

Level

Medium

Modules Involved

Auth Service, Plant Module, Analytics Module, Database

Normal Flow

1. Enter credentials → validate → read-only session 2. View plant list → fetch all plants → display 3. Open plant profile → fetch details + images + notes → display 4. View analytics → fetch data → show charts (view only)

Restriction

No create, edit, or delete operations are permitted for this role.

Table 3.5.3: Viewer / Guest Sequence Diagram Summary

3.6  Activity Diagrams

Activity diagrams show the step-by-step flow of specific processes in the system, including all decision points and possible paths. The diagrams below cover the most important workflows in PSMS.

3.6.1  Live Camera & AI Health Detection

This diagram shows how the IoT camera and AI health detection work together. The camera streams live footage to the AI engine, which checks each image for signs of plant stress such as wilting, yellowing, dehydration, pests, or disease. If a problem is found, the system classifies it by type and severity, logs it as a health event with a timestamp, and immediately sends a push alert to the Farmer through the Notification Engine. If no problem is found, the camera continues streaming normally.

Figure 3.6.1: Live Camera and AI Health Detection Activity Diagram

3.6.2  View Plant List Activity Diagram

This diagram shows what happens when a user opens the plant list page. If the user is not logged in, the system checks whether they are accessing the public Plant Encyclopedia, in which case it serves them without login. Otherwise, it redirects them to the login page. For logged-in users, the system validates the session and fetches all registered plants from the database. If no plants are found, it shows an empty state with a button to add a new plant. If plants exist, it displays the full list.

Figure 3.6.2: View Plant List Activity Diagram

3.6.3  Generate Care Schedule Activity Diagram

This diagram shows the automated process that runs when a Farmer registers a new plant. When the Farmer adds a plant and selects a species from the Plant Encyclopedia, the system looks up the species in the AI knowledge base. If found, the AI creates a care schedule with watering and fertilization settings specific to that species, while disease and pest monitoring is set up to apply to all plants equally. The schedule is saved, the camera is activated, reminders are queued, and live feed analysis begins. If the species is not found, a default care schedule is used instead.

Figure 3.6.3: Generate Care Schedule Activity Diagram

3.6.4  User Registration Activity Diagram

This diagram shows the full user registration process. The user fills in a username, email, and password. The system checks that all fields are filled in correctly. If not, it shows error messages and returns the user to the form. If the fields are valid, the system checks if the email is already in use. If it is, the user is redirected to the login page. If the email is new, the system creates the account, assigns a default role, sends a welcome email, and logs the user in.

Figure 3.6.4: User Registration Activity Diagram

3.6.5  Browse Plant Encyclopedia Activity Diagram

This diagram shows how a visitor browses the public Plant Encyclopedia. The user opens the encyclopedia page, which loads all categories immediately. They can search by keyword or filter by category. The system queries the encyclopedia database and shows the results. If nothing is found, it shows a message and suggests related categories. If results are found, the user can select a species to view its full profile.

Figure 3.6.5: Browse Plant Encyclopedia Activity Diagram

3.6.6  Admin Manage Encyclopedia Activity Diagram

This diagram shows how an Admin manages the Plant Encyclopedia. After logging in and going to the encyclopedia management section, the Admin can add a new entry, edit an existing one, or delete one. When adding, the Admin fills in all required fields and the system saves the entry if everything is valid. For edits, existing data is loaded first and updated after validation. For deletions, the Admin must confirm before the entry is removed.

Figure 3.6.6: Admin Manage Encyclopedia Entry Activity Diagram

Note: The Admin encyclopedia management diagram follows the same basic structure as the public browsing diagram, but adds branches for adding, editing, and deleting entries, along with a confirmation step for deletion.

3.7  Class Diagram

The class diagram shows the structure of the PSMS software, including all main classes, their data fields, their functions, and how they are connected. The User class is the starting point: a user can have multiple plants, each plant is connected to an IoT camera, and the camera feeds data to the AI engine. Care tasks, growth records, health events, and notifications are all linked to the plant class, making it the central entity in the system.

Figure 3.7: Class Diagram

3.8  Entity Relationship Diagram

The ER diagram shows the structure of the PSMS database and how all the tables are connected. A single user account can be linked to multiple plant profiles. Each plant is connected to one IoT camera and can have many growth records, care schedule entries, health events, and notifications. The analytics table collects data from all these tables to produce the charts and reports shown in the dashboard.

Figure 3.8: Entity Relationship Diagram

3.10  Data Dictionary

The Data Dictionary lists every field in every table in the PSMS database. For each field, it shows the field name, data type, size limit, any constraints such as primary key or foreign key, and a simple description of what the field is used for. This dictionary is the technical reference for all development, testing, and database work on the project.

Table 3.10.1: Data Dictionary USER

Field Name

Data Type

Field Length

Constraint

Description

user_id

INT

10

PK, Not Null

Unique identifier for each user account

username

VARCHAR

100

Not Null

The user's display name used for login

email

VARCHAR

100

Not Null

The user's email address — must be unique

password_hash

VARCHAR

255

Not Null

Hashed version of the user's password (bcrypt)

role

ENUM

—

Not Null

User role: Admin (system and encyclopedia manager), Farmer (full monitoring and care access), or Viewer/Guest (read-only and public encyclopedia access)

created_at

DATETIME

—

Not Null

Date and time the account was created

Table 3.10.2: Data Dictionary PLANT

Field Name

Data Type

Field Length

Constraint

Description

plant_id

INT

10

PK, Not Null

Unique identifier for the plant profile

plant_name

VARCHAR

150

Not Null

The name given to this plant by the user

species

VARCHAR

100

Not Null

Botanical species or variety of the plant

planting_date

DATE

—

Not Null

Date the plant was planted or moved into the setup

location

VARCHAR

100

Not Null

Location within the vertical farming setup

cover_image

VARCHAR

200

Nullable

File path or cloud URL of the primary profile image automatically captured by the IoT camera at registration

user_id

INT

10

FK → USER

Links this plant to its owner

camera_id

INT

10

FK -> IOT_CAMERA

Links this plant to its assigned IoT monitoring camera

encyclopedia_entry_id

INT

10

FK -> ENCYCLOPEDIA_ENTRY, Nullable

Links this plant to its species entry in the public encyclopedia, used to pre-populate care schedule parameters

Table 3.10.3: Data Dictionary GROWTH_RECORD

Field Name

Data Type

Field Length

Constraint

Description

record_id

INT

10

PK, Not Null

Unique identifier for each growth record entry

image_path

VARCHAR

200

Nullable

File path or cloud storage URL of the growth image automatically captured and stored by the IoT camera pipeline

notes

TEXT

—

Nullable

Written observation notes added by the user

recorded_date

DATETIME

—

Not Null

Timestamp automatically assigned at upload

plant_id

INT

10

FK → PLANT

Links this record to its parent plant

Table 3.10.4: Data Dictionary CARE_SCHEDULE

Field Name

Data Type

Field Length

Constraint

Description

schedule_id

INT

10

PK, Not Null

Unique identifier for the care task

task_type

ENUM

—

Not Null

Type of task: Watering, Lighting, or Fertilization

due_date

DATETIME

—

Not Null

The date and time the task is scheduled to be done

is_completed

BOOLEAN

—

Not Null

TRUE if the user marked this task as done

completed_at

DATETIME

—

Nullable

Actual timestamp when the task was completed

plant_id

INT

10

FK → PLANT

Links this task to its plant

generated_by_ai

BOOLEAN

---

Not Null

TRUE if this schedule was auto-generated by the AI engine based on species encyclopedia data

humidity_threshold

FLOAT

---

Nullable

Recommended humidity level threshold for this plant species, used by AI to detect dehydration risk

Table 3.10.5: Data Dictionary NOTIFICATION

Field Name

Data Type

Field Length

Constraint

Description

notif_id

INT

10

PK, Not Null

Unique identifier for the notification

message

VARCHAR

250

Not Null

The text content of the notification message

sent_at

DATETIME

—

Not Null

Date and time the notification was sent

is_read

BOOLEAN

—

Not Null

TRUE if the user has opened/dismissed the notification

user_id

INT

10

FK → USER

The user who should receive this notification

plant_id

INT

10

FK → PLANT

The plant this notification is related to

notif_type

ENUM

---

Not Null

Type of notification: AIAlert (real-time health detection), CareReminder (scheduled task), or MissedTask (overdue alert)

Table 3.10.6: Data Dictionary ANALYTICS

Field Name

Data Type

Field Length

Constraint

Description

analytics_id

INT

10

PK, Not Null

Unique identifier for the analytics record

metric_type

VARCHAR

100

Not Null

Name of the metric being recorded (e.g., care_compliance_rate, ai_alert_count, growth_rate, response_time_to_alert)

metric_value

FLOAT

—

Not Null

Calculated numeric value for this metric

calc_date

DATE

—

Not Null

The date this metric was calculated

plant_id

INT

10

FK → PLANT

The plant this metric belongs to

Table 3.10.7: Data Dictionary CARE_HISTORY

Field Name

Data Type

Field Length

Constraint

Description

history_id

INT

10

PK, Not Null

Unique identifier for the care history entry

task_type

VARCHAR

100

Not Null

Type of care task that was completed

completed_at

DATETIME

—

Not Null

Date and time the task was actually done

user_id

INT

10

FK → USER

The user who performed the task

plant_id

INT

10

FK → PLANT

The plant this care action was performed on

Table 3.10.8: Data Dictionary IOT_CAMERA

Field Name

Data Type

Length

Constraint

Description

camera_id

INT

10

PK, Not Null

Unique identifier for the IoT camera device

plant_id

INT

10

FK -> PLANT

Links this camera to the plant it monitors

stream_url

VARCHAR

255

Nullable

URL of the live camera stream endpoint

status

ENUM

---

Not Null

Current camera status: Active or Offline

last_capture

DATETIME

---

Nullable

Timestamp of the most recent frame captured and processed by the AI engine

Table 3.10.9: Data Dictionary HEALTH_EVENT

Field Name

Data Type

Length

Constraint

Description

event_id

INT

10

PK, Not Null

Unique identifier for the AI-detected health event

plant_id

INT

10

FK -> PLANT

The plant for which this health event was detected

issue_type

VARCHAR

100

Not Null

Classification of detected issue: Wilting, Discoloration, Dehydration, Pest, or Disease

severity

ENUM

---

Not Null

Severity level assigned by the AI engine: Low, Medium, or High

detected_at

DATETIME

---

Not Null

Timestamp when the AI engine first detected the health issue from the live feed

resolved

BOOLEAN

---

Not Null

TRUE if the Farmer has acknowledged and resolved this alert

resolved_at

DATETIME

---

Nullable

Timestamp when the Farmer marked the health event as resolved

Table 3.10.10: Data Dictionary ENCYCLOPEDIA_ENTRY

Field Name

Data Type

Length

Constraint

Description

entry_id

INT

10

PK, Not Null

Unique identifier for the encyclopedia species entry

species_name

VARCHAR

150

Not Null, Unique

The botanical name of the plant species

watering_frequency

INT

---

Not Null

Recommended number of days between watering sessions for this species

light_requirement

VARCHAR

100

Not Null

Required daily light exposure level: Low, Medium, or High

humidity_range

VARCHAR

50

Nullable

Optimal humidity percentage range for healthy growth

common_diseases

TEXT

---

Nullable

Description of common diseases and their visual symptoms for this species

pest_vulnerabilities

TEXT

---

Nullable

Known pest threats and early visual indicators of infestation

cultivation_tips

TEXT

---

Nullable

Practical growing recommendations and care best practices

created_by

INT

10

FK -> USER

The Administrator user who created or last modified this entry

updated_at

DATETIME

---

Not Null

Timestamp of the most recent modification to this encyclopedia entry

3.11  Conclusion

This chapter presented the complete technical design of PSMS, turning the requirements from Chapter 2 into a set of design artifacts ready for development. It started with an overview of how SCRUM was used to manage the project, followed by the product and sprint backlogs that organized all development tasks.

Three sequence diagrams showed how the Farmer, Administrator, and Viewer/Guest interact with the system modules during a full session, covering the flow of calls between the IoT Camera, AI Engine, Care Schedule Module, Notification Engine, Plant Module, Encyclopedia Module, Analytics Module, and the Database. Six activity diagrams showed the step-by-step logic of the most important workflows: live camera and AI health detection, viewing the plant list, generating a care schedule, user registration, browsing the encyclopedia, and admin encyclopedia management.

The class diagram defined the structure of the system with the IoT Camera and AI Analysis Engine as the central classes, alongside User, Plant, CareSchedule, HealthEvent, Notification, Analytics, GrowthRecord, and EncyclopediaEntry. The ER diagram provided the full database design across ten tables. The Data Dictionary documented every field in all ten tables.

With all design artifacts complete, the system architecture is fully documented and ready to guide the development phase.

ChapterChapter44

Chapter

Chapter

4

4

FUTURE WORK

4.1  Introduction to Future Development

The current version of PSMS provides a solid working foundation for IoT and AI-based plant care management. However, several improvements have been planned for future versions that would make the system more powerful, scalable, and widely usable.

Advanced AI Disease and Pest Detection

The current AI engine detects general visual signs of plant stress such as wilting and discoloration. A planned improvement is to train more specialized models that can identify specific plant diseases, fungal infections, and pest types by name from camera images. This would allow the system to not only alert the user but also suggest the right treatment based on the encyclopedia knowledge base.

IoT Sensor Integration for Environmental Monitoring

Future versions will add physical environmental sensors alongside the camera, such as soil moisture sensors, temperature and humidity gauges, and light meters. Data from these sensors would be fed into the AI engine together with the camera images, allowing the system to detect problems that are not yet visible, such as root dehydration or nutrient deficiency.

Community Features and User-Contributed Encyclopedia Content

The Plant Encyclopedia is currently managed only by Admins. A planned update would allow trusted Farmer users to submit their own observations, tips, and care experiences. After Admin review, these would be added to the public encyclopedia, helping the knowledge base grow faster and making the platform more community-driven.

Multi-Farm and Large-Scale Deployment Support

The current version is designed for a small setup of two to three plants. A future version would extend the system to support large commercial vertical farms with hundreds of plants across multiple locations, with a central management dashboard for Admins to monitor all cameras and see AI health reports across the whole farm.

Automated Irrigation and Environmental Control Integration

A long-term goal for PSMS is to add actuator hardware that would allow the system to act on what the AI detects. For example, if the AI detects that a plant is dehydrated, it could automatically open an irrigation valve instead of just sending a notification. This would turn PSMS from a monitoring system into a fully automated vertical farming platform.

Multilingual Encyclopedia and Localization

To make PSMS and the Plant Encyclopedia useful to more people around the world, future development will add full multilingual support including Arabic. This would allow users from the Middle East and other non-English-speaking regions to use the entire system, including the interface, encyclopedia content, AI alerts, and exported reports, in their own language.

REFERENCES

Related Applications

PEAT GmbH. (2023). Plantix: AI-powered crop disease and pest diagnosis app. PEAT GmbH. https://plantix.net/en/

Thrive Engineering Inc. (2024). Greg: Smart plant care app. App Store / Google Play. https://greg.app/

GreenSnap Inc. (2024). GreenSnap: Plant identification and community app. GreenSnap Inc. https://greensnapapp.com/

SmartPlant. (2024). SmartPlant: The plant care app. Smart Plant Ltd. https://smartplanthome.com/

Books and Academic Textbooks

Sommerville, I. (2016). Software engineering (10th ed.). Pearson Education. https://www.pearson.com/en-us/subject-catalog/p/software-engineering/P200000003226

Pressman, R. S., & Maxim, B. R. (2019). Software engineering: A practitioner's approach (9th ed.). McGraw-Hill Education.

Schwaber, K., & Sutherland, J. (2020). The Scrum guide: The definitive guide to Scrum The rules of the game. Scrum.org. https://scrumguides.org/scrum-guide.html

Journal Articles and Research Papers

Benke, K., & Tomkins, B. (2017). Future food-production systems: Vertical farming and controlled-environment agriculture. Sustainability: Science, Practice and Policy, 13(1), 13–26. https://doi.org/10.1080/15487733.2017.1394054

Kozai, T., Niu, G., & Takagaki, M. (Eds.). (2020). Plant factory: An indoor vertical farming system for efficient quality food production (2nd ed.). Academic Press. https://doi.org/10.1016/C2019-0-00570-7

Avgoustaki, D. D., & Xydis, G. (2020). Indoor plant factories in a world of increasing water scarcity: A review. Food Security, 12, 1–14. https://doi.org/10.1007/s12571-019-00983-8

Technical Documentation and Online Resources

Scrum Alliance. (2023). What is Scrum? An agile framework for developing, delivering, and sustaining complex products. Scrum Alliance. https://www.scrumalliance.org/about-scrum

React Native Documentation. (2024). Getting started with React Native. Meta Open Source. https://reactnative.dev/docs/getting-started

Flutter Documentation. (2024). Flutter Build apps for any screen. Google. https://flutter.dev/docs

Node.js Documentation. (2024). Node.js v20 LTS Documentation. OpenJS Foundation. https://nodejs.org/en/docs

PostgreSQL Global Development Group. (2024). PostgreSQL 16 documentation. https://www.postgresql.org/docs/16/

Firebase. (2024). Firebase Cloud Messaging: Cross-platform messaging solution. Google. https://firebase.google.com/docs/cloud-messaging

Express.js. (2024). Express Fast, unopinionated, minimalist web framework for Node.js. https://expressjs.com/

Object Management Group. (2017). Unified modeling language specification version 2.5.1. OMG Document formal/2017-12-05. https://www.omg.org/spec/UML/2.5.1

Wrike. (2023). Scrum sprint planning: A complete guide. Wrike Inc. https://www.wrike.com/scrum-guide/scrum-sprint-planning/

Atlassian. (2024). What is Scrum? Atlassian Agile Coach. https://www.atlassian.com/agile/scrum

Standards and Guidelines

Open Web Application Security Project. (2023). OWASP Top Ten 2023: The ten most critical web application security risks. OWASP Foundation. https://owasp.org/www-project-top-ten/