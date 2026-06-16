# MYBAHAYA - PROJECT CONTEXT

## Project Overview

MyBahaya is an AI-powered emergency reporting and real-time community alert platform designed specifically for Malaysia.

The main objective of MyBahaya is to reduce emergency reporting time by allowing citizens to instantly report dangerous incidents using photos, videos, and location data, without requiring lengthy manual descriptions or phone calls.

The system uses Artificial Intelligence to analyze uploaded media, classify the incident type, generate a summary, determine the appropriate emergency organization, and notify nearby users about potential dangers.

The platform consists of:

1. Mobile Application (Citizens)
2. Web Dashboard (Emergency Organizations)
3. Backend API Services
4. AI Analysis Services
5. Cloud Media Storage
6. Real-Time Notification Services

---

# Problem Statement

Current emergency reporting methods in Malaysia rely heavily on:

* Calling 999
* Manually describing incidents
* Waiting for operators to redirect calls
* Delayed information sharing

During emergencies, victims or witnesses often:

* Panic
* Have difficulty describing situations
* Cannot identify the correct emergency agency
* Need a faster way to submit evidence

There is currently no unified platform allowing citizens to instantly submit multimedia evidence while simultaneously informing nearby communities and relevant emergency organizations.

---

# Proposed Solution

MyBahaya enables citizens to:

* Capture photos or videos
* Upload evidence instantly
* Share location automatically
* Submit reports with minimal interaction

The AI system will:

* Analyze images/videos
* Identify incident category
* Generate short emergency summaries
* Suggest responsible emergency organizations

The system will then:

* Save reports
* Notify nearby organizations
* Alert nearby citizens
* Track emergency response progress

---

# User Roles

## Citizen User

Purpose:
General public users.

Features:

* Register/Login
* View nearby emergency reports
* Submit emergency reports
* Upload photos/videos
* Receive nearby danger alerts
* View report history
* Track report status
* Manage profile

---

## Emergency Organization

Purpose:
Authorized agencies.

Examples:

* Police
* Bomba
* Hospital
* Ambulance Services
* JPAM / APM

Features:

* View assigned reports
* View incident location
* View uploaded evidence
* Update report status
* Manage emergency response
* View analytics dashboard
* Manage organization profile

---

## System Administrator

Purpose:
Platform management.

Features:

* Manage users
* Manage organizations
* Moderate reports
* Detect abuse
* System monitoring
* Analytics
* Audit logs

---

# System Architecture

Mobile App (Flutter)

↓

Spring Boot Backend API

↓

AI Processing Service

↓

Firestore Database

*

MinIO Object Storage

↓

React Web Dashboard

↓

Firebase Cloud Messaging

---

# Technology Stack

## Mobile Application

Framework:
Flutter

Language:
Dart

Purpose:
Cross-platform Android and iOS application.

---

## Web Dashboard

Framework:
React

Language:
TypeScript

Purpose:
Emergency organization management portal.

---

## Backend

Framework:
Spring Boot

Language:
Java 21

Build Tool:
Maven

Purpose:
Business logic and API services.

---

## Database

Platform:
Firebase Firestore

Purpose:
Store structured data.

Examples:

* Users
* Reports
* Organizations
* Notifications
* Status updates

---

## Object Storage

Platform:
MinIO

Purpose:
Store media files.

Examples:

* Images
* Videos
* Evidence attachments

Media URLs are stored in Firestore.

---

## Notifications

Platform:
Firebase Cloud Messaging (FCM)

Purpose:

* Push notifications
* Community alerts
* Emergency updates

---

## Maps

Platform:
OpenStreetMap

Flutter:
flutter_map

Web:
Leaflet

Purpose:

* Report locations
* Incident visualization
* Nearby report discovery

---

## AI Service

Primary Model:
Google Gemini 1.5 Flash

Purpose:

* Image analysis
* Video analysis
* Emergency classification
* Incident summarization

---

# AI Workflow

Citizen uploads:

* Image
* Video
* Location

↓

Backend receives report

↓

Media stored in MinIO

↓

Media URL stored

↓

AI analyzes media

↓

AI returns:

* Incident category
* Summary
* Suggested organization
* Confidence score

↓

Report updated

↓

Organization notified

↓

Nearby users alerted

---

# Incident Categories

Examples:

* Fire
* Road Accident
* Flood
* Landslide
* Theft
* Robbery
* Assault
* Shooting
* Suspicious Activity
* Medical Emergency
* Building Collapse
* Hazardous Materials
* Other

---

# Report Lifecycle

Status Flow:

SUBMITTED

↓

AI_ANALYZING

↓

VERIFIED

↓

ASSIGNED

↓

IN_PROGRESS

↓

RESOLVED

↓

CLOSED

---

# Media Storage Architecture

MinIO stores:

* Photos
* Videos
* Attachments

Firestore stores:

* Report information
* Media URLs
* Metadata

Example:

Report
{
reportId,
category,
summary,
latitude,
longitude,
mediaUrl,
status,
createdAt
}

---

# Home Feed Algorithm

Priority:

1. Nearby incidents
2. Active emergencies
3. Recent reports
4. Regional reports
5. Historical incidents

Feed style inspired by:

* TikTok
* X (Twitter)
* Community Alert Systems

---

# Security Features

* Firebase Authentication
* JWT Authentication
* Role-based Access Control
* Media Validation
* Rate Limiting
* Audit Logging

---

# Fake Report Prevention

Mechanisms:

1. AI confidence scoring
2. User reputation system
3. Multiple user confirmations
4. Admin moderation
5. Community verification
6. Account suspension system

---

# FYP Scope

## FYP 1

Core System

* Authentication
* Report Submission
* Media Upload
* MinIO Integration
* Firestore Integration
* AI Analysis
* Community Alerts
* Organization Dashboard
* Report Management

---

## FYP 2

Advanced Features

* Live Streaming
* Real-Time Video Reporting
* AI Risk Prediction
* Heat Maps
* Emergency Resource Tracking
* Advanced Analytics
* Smart Dispatch Suggestions
* Cross-Agency Collaboration

---

# Expected Benefits

Citizens:

* Faster reporting
* Easier reporting
* Better awareness

Emergency Organizations:

* Faster information delivery
* Better evidence collection
* Improved response coordination

Government:

* Improved emergency management
* Better public safety monitoring
* Enhanced disaster response

---

# Long-Term Vision

MyBahaya aims to become a nationwide emergency reporting ecosystem that connects citizens, emergency organizations, and intelligent decision-support systems into a single unified platform capable of improving emergency response speed and public safety throughout Malaysia.
