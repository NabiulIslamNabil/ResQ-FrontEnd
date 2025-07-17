# ResQ API Documentation

## Overview

ResQ is an emergency response coordination platform designed to connect citizens with emergency services during crisis situations. This document provides comprehensive API documentation for developers.

## Base URL

```
https://api.resq-app.com/api/
```

For local development:

```
http://localhost:8000/api/
```

## Authentication

### Authentication Methods

ResQ supports multiple authentication methods:

1. **JWT Authentication**: Primary authentication method using JSON Web Tokens
2. **Firebase Authentication**: Alternative method for mobile clients

#### JWT Authentication

Most endpoints require an access token in the Authorization header:

```
Authorization: Bearer {your_access_token}
```

To obtain tokens, use the login endpoint.

#### Firebase Authentication

Mobile clients can authenticate using Firebase:

```
Authorization: Firebase {firebase_id_token}
```

### Authentication Endpoints

#### Register a New User

**Endpoint**: `POST /users/register/`

**Description**: Create a new user account

**Request Body**:

```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "secure_password",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+905551234567",
  "role": "CITIZEN",
  "location": {
    "latitude": 38.4192,
    "longitude": 27.1287
  }
}
```

**Response (201 Created)**:

```json
{
  "user": {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "username": "john_doe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+905551234567",
    "role": "CITIZEN",
    "is_active": true,
    "date_joined": "2025-04-15T09:12:33Z"
  },
  "refresh": "eyJ0eXA...",
  "access": "eyJ0eXA..."
}
```

#### User Login

**Endpoint**: `POST /users/login/`

**Description**: Authenticate and receive JWT tokens

**Request Body**:

```json
{
  "username": "john_doe",
  "password": "secure_password"
}
```

**Response (200 OK)**:

```json
{
  "refresh": "eyJ0eXA...",
  "access": "eyJ0eXA...",
  "user": {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "username": "john_doe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+905551234567",
    "role": "CITIZEN",
    "is_active": true,
    "date_joined": "2025-04-15T09:12:33Z"
  }
}
```

#### Refresh Token

**Endpoint**: `POST /users/token/refresh/`

**Description**: Get a new access token using refresh token

**Request Body**:

```json
{
  "refresh": "eyJ0eXA..."
}
```

**Response (200 OK)**:

```json
{
  "access": "eyJ0eXA..."
}
```

## User Management

### Get Current User Profile

**Endpoint**: `GET /users/me/`

**Description**: Retrieve the authenticated user's profile

**Authentication**: Required

**Response (200 OK)**:

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "username": "john_doe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+905551234567",
  "role": "CITIZEN",
  "is_active": true,
  "date_joined": "2025-04-15T09:12:33Z"
}
```

### Update User Profile

**Endpoint**: `PATCH /users/me/`

**Description**: Update current user's profile

**Authentication**: Required

**Request Body**:

```json
{
  "first_name": "Johnny",
  "last_name": "Doe",
  "phone_number": "+905559876543"
}
```

**Response (200 OK)**:

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "username": "john_doe",
  "email": "john@example.com",
  "first_name": "Johnny",
  "last_name": "Doe",
  "phone_number": "+905559876543",
  "role": "CITIZEN",
  "is_active": true,
  "date_joined": "2025-04-15T09:12:33Z"
}
```

### List Emergency Service Users

**Endpoint**: `GET /users/list/?role=FIRE_STATION`

**Description**: Get a list of users filtered by role

**Authentication**: Required

**Query Parameters**:

- `role`: Filter by user role (CITIZEN, FIRE_STATION, POLICE, RED_CRESCENT)

**Response (200 OK)**:

```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa7",
    "username": "central_fire_station",
    "email": "fire@example.com",
    "first_name": "Central",
    "last_name": "Fire Station",
    "phone_number": "+905551112233",
    "role": "FIRE_STATION",
    "is_active": true,
    "date_joined": "2025-04-10T09:12:33Z"
  }
]
```

## Location Management

### Update User Location

**Endpoint**: `POST /locations/`

**Description**: Update the user's current location

**Authentication**: Required

**Request Body**:

```json
{
  "latitude": 38.4192,
  "longitude": 27.1287,
  "address": "123 Main St, Izmir, Turkey",
  "is_current": true
}
```

**Response (201 Created)**:

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa8",
  "user": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "latitude": 38.4192,
  "longitude": 27.1287,
  "address": "123 Main St, Izmir, Turkey",
  "is_current": true,
  "is_emergency": false,
  "timestamp": "2025-04-15T10:15:33Z"
}
```

### Get User's Location History

**Endpoint**: `GET /locations/`

**Description**: Retrieve the user's location history

**Authentication**: Required

**Response (200 OK)**:

```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa8",
    "user": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "latitude": 38.4192,
    "longitude": 27.1287,
    "address": "123 Main St, Izmir, Turkey",
    "is_current": true,
    "is_emergency": false,
    "timestamp": "2025-04-15T10:15:33Z"
  },
  {
    "id": "4fa85f64-5717-4562-b3fc-2c963f66afa9",
    "user": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "latitude": 38.418,
    "longitude": 27.129,
    "address": "456 Park Ave, Izmir, Turkey",
    "is_current": false,
    "is_emergency": false,
    "timestamp": "2025-04-14T15:20:33Z"
  }
]
```

### Emergency Location Update

**Endpoint**: `POST /locations/emergency/`

**Description**: Update user's location during an emergency

**Authentication**: Required

**Request Body**:

```json
{
  "latitude": 38.4192,
  "longitude": 27.1287,
  "address": "123 Main St, Izmir, Turkey"
}
```

**Response (201 Created)**:

```json
{
  "id": "5fa85f64-5717-4562-b3fc-2c963f66afaa",
  "user": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "latitude": 38.4192,
  "longitude": 27.1287,
  "address": "123 Main St, Izmir, Turkey",
  "is_current": true,
  "is_emergency": true,
  "timestamp": "2025-04-15T10:25:33Z"
}
```

### Emergency Locations List

**Endpoint**: `GET /locations/emergency-locations/`

**Description**: Get all current emergency locations (for emergency services only)

**Authentication**: Required (Emergency services only)

**Response (200 OK)**:

```json
[
  {
    "id": "5fa85f64-5717-4562-b3fc-2c963f66afaa",
    "user": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "username": "john_doe",
      "phone_number": "+905551234567"
    },
    "latitude": 38.4192,
    "longitude": 27.1287,
    "address": "123 Main St, Izmir, Turkey",
    "is_emergency": true,
    "timestamp": "2025-04-15T10:25:33Z"
  }
]
```

## Emergency Management

### List Emergency Tags

**Endpoint**: `GET /emergency/tags/`

**Description**: Get a list of all emergency tags for categorization

**Authentication**: Required

**Response (200 OK)**:

```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afab",
    "name": "Building Collapse",
    "emergency_type": "EARTHQUAKE",
    "description": "Structural damage or building collapse"
  },
  {
    "id": "4fa85f64-5717-4562-b3fc-2c963f66afac",
    "name": "Fire",
    "emergency_type": "FIRE",
    "description": "Active fire emergency"
  },
  {
    "id": "5fa85f64-5717-4562-b3fc-2c963f66afad",
    "name": "Trapped Individuals",
    "emergency_type": "DISASTER",
    "description": "People trapped or in need of rescue"
  }
]
```

### Report Emergency

**Endpoint**: `POST /emergency/reports/report_emergency/`

**Description**: Report a new emergency with coordinates

**Authentication**: Required

**Request Body**:

```json
{
  "reporter_type": "VICTIM",
  "description": "Building collapsed, need urgent help",
  "latitude": 38.4192,
  "longitude": 27.1287,
  "tags": [
    "3fa85f64-5717-4562-b3fc-2c963f66afab",
    "5fa85f64-5717-4562-b3fc-2c963f66afad"
  ],
  "media_file": "[binary file - optional]"
}
```

**Response (201 Created)**:

```json
{
  "id": "6fa85f64-5717-4562-b3fc-2c963f66afae",
  "reporter": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "reporter_type": "VICTIM",
  "description": "Building collapsed, need urgent help",
  "latitude": 38.4192,
  "longitude": 27.1287,
  "status": "PENDING",
  "is_emergency": true,
  "tags": [
    {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afab",
      "name": "Building Collapse",
      "emergency_type": "EARTHQUAKE"
    },
    {
      "id": "5fa85f64-5717-4562-b3fc-2c963f66afad",
      "name": "Trapped Individuals",
      "emergency_type": "DISASTER"
    }
  ],
  "timestamp": "2025-04-15T10:30:33Z"
}
```

### Create Standard Report

**Endpoint**: `POST /emergency/reports/`

**Description**: Create a standard emergency report

**Authentication**: Required

**Request Body**:

```json
{
  "reporter_type": "SPECTATOR",
  "description": "Traffic accident on main highway",
  "latitude": 38.418,
  "longitude": 27.129,
  "is_emergency": true,
  "tag_ids": ["4fa85f64-5717-4562-b3fc-2c963f66afac"]
}
```

**Response (201 Created)**:

```json
{
  "id": "7fa85f64-5717-4562-b3fc-2c963f66afaf",
  "reporter": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "reporter_type": "SPECTATOR",
  "description": "Traffic accident on main highway",
  "latitude": 38.418,
  "longitude": 27.129,
  "status": "PENDING",
  "is_emergency": true,
  "tags": [
    {
      "id": "4fa85f64-5717-4562-b3fc-2c963f66afac",
      "name": "Traffic Accident",
      "emergency_type": "TRAFFIC"
    }
  ],
  "timestamp": "2025-04-15T11:30:33Z"
}
```

### Non-Emergency Report

**Endpoint**: `POST /emergency/reports/`

**Description**: Create a non-emergency report (such as infrastructure issues)

**Authentication**: Required

**Request Body**:

```json
{
  "reporter_type": "SPECTATOR",
  "description": "Damaged street light on 5th Avenue",
  "latitude": 38.4175,
  "longitude": 27.1295,
  "is_emergency": false,
  "tag_ids": []
}
```

**Response (201 Created)**:

```json
{
  "id": "8fa85f64-5717-4562-b3fc-2c963f66afb0",
  "reporter": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "reporter_type": "SPECTATOR",
  "description": "Damaged street light on 5th Avenue",
  "latitude": 38.4175,
  "longitude": 27.1295,
  "status": "PENDING",
  "is_emergency": false,
  "tags": [],
  "timestamp": "2025-04-15T12:30:33Z"
}
```

### Anonymous Report

**Endpoint**: `POST /emergency/reports/`

**Description**: Create an anonymous report (reporter details are masked in response)

**Authentication**: Required (but reporter identity is protected)

**Request Body**:

```json
{
  "reporter_type": "SPECTATOR",
  "description": "Suspicious activity in abandoned building",
  "latitude": 38.4165,
  "longitude": 27.1305,
  "is_emergency": true,
  "is_anonymous": true,
  "tag_ids": ["5fa85f64-5717-4562-b3fc-2c963f66afae"]
}
```

**Response (201 Created)**:

```json
{
  "id": "9fa85f64-5717-4562-b3fc-2c963f66afb1",
  "reporter": "ANONYMOUS",
  "reporter_type": "SPECTATOR",
  "description": "Suspicious activity in abandoned building",
  "latitude": 38.4165,
  "longitude": 27.1305,
  "status": "PENDING",
  "is_emergency": true,
  "tags": [
    {
      "id": "5fa85f64-5717-4562-b3fc-2c963f66afae",
      "name": "Suspicious Activity",
      "emergency_type": "OTHER"
    }
  ],
  "timestamp": "2025-04-15T13:30:33Z"
}
```

### Multiple Location Reports

**Endpoint**: `POST /emergency/reports/multi_location/`

**Description**: Report an emergency affecting multiple locations (e.g., wildfire)

**Authentication**: Required

**Request Body**:

```json
{
  "reporter_type": "SPECTATOR",
  "description": "Wildfire spreading across multiple areas",
  "locations": [
    {
      "latitude": 38.415,
      "longitude": 27.127
    },
    {
      "latitude": 38.414,
      "longitude": 27.128
    }
  ],
  "tag_ids": ["3fa85f64-5717-4562-b3fc-2c963f66afa5"],
  "is_emergency": true
}
```

**Response (201 Created)**:

```json
{
  "main_report": {
    "id": "10fa85f64-5717-4562-b3fc-2c963f66afb2",
    "reporter": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "reporter_type": "SPECTATOR",
    "description": "Wildfire spreading across multiple areas",
    "latitude": 38.415,
    "longitude": 27.127,
    "status": "PENDING",
    "is_emergency": true,
    "tags": [
      {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa5",
        "name": "Wildfire",
        "emergency_type": "FIRE"
      }
    ],
    "timestamp": "2025-04-15T14:30:33Z"
  },
  "additional_reports": [
    {
      "id": "11fa85f64-5717-4562-b3fc-2c963f66afb3",
      "latitude": 38.414,
      "longitude": 27.128
    }
  ],
  "total_locations": 2
}
```

### Update Emergency Status

**Endpoint**: `POST /emergency/reports/{id}/update_status/`

**Description**: Update the status of an emergency (for emergency services)

**Authentication**: Required (Emergency services only)

**Request Body**:

```json
{
  "status": "RESPONDING"
}
```

**Status Options**:

- `PENDING`: Not yet addressed
- `RESPONDING`: Emergency services on the way
- `ON_SCENE`: Emergency services at the location
- `RESOLVED`: Emergency has been resolved

**Response (200 OK)**:

```json
{
  "id": "6fa85f64-5717-4562-b3fc-2c963f66afae",
  "reporter": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "reporter_type": "VICTIM",
  "description": "Building collapsed, need urgent help",
  "latitude": 38.4192,
  "longitude": 27.1287,
  "status": "RESPONDING",
  "is_emergency": true,
  "tags": [
    {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afab",
      "name": "Building Collapse",
      "emergency_type": "EARTHQUAKE"
    },
    {
      "id": "5fa85f64-5717-4562-b3fc-2c963f66afad",
      "name": "Trapped Individuals",
      "emergency_type": "DISASTER"
    }
  ],
  "timestamp": "2025-04-15T10:30:33Z"
}
```

### Find Nearby Emergencies

**Endpoint**: `GET /emergency/nearby/?lat=38.4192&lng=27.1287&radius=5`

**Description**: Find emergencies within a specific radius

**Authentication**: Required

**Query Parameters**:

- `lat`: Latitude (required)
- `lng`: Longitude (required)
- `radius`: Search radius in kilometers (default: 5)

**Response (200 OK)**:

```json
[
  {
    "id": "6fa85f64-5717-4562-b3fc-2c963f66afae",
    "reporter": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "username": "john_doe"
    },
    "description": "Building collapsed, need urgent help",
    "latitude": 38.4192,
    "longitude": 27.1287,
    "status": "RESPONDING",
    "is_emergency": true,
    "tags": [
      {
        "name": "Building Collapse",
        "emergency_type": "EARTHQUAKE"
      },
      {
        "name": "Trapped Individuals",
        "emergency_type": "DISASTER"
      }
    ],
    "timestamp": "2025-04-15T10:30:33Z",
    "distance": 0.35
  }
]
```

## Chatbot & AI Assistance

ResQ includes an intelligent AI chatbot powered by Google's Gemini AI that provides emergency guidance and support. The chatbot maintains conversation history and provides contextual responses based on user roles and emergency scenarios.

### Send Message to Chatbot

**Endpoint**: `POST /chatbot/chat/`

**Description**: Send a message to the AI chatbot and receive emergency guidance

**Authentication**: Required

**Request Body**:

```json
{
  "message": "What should I do if there's a fire in my building?"
}
```

**Response (200 OK)**:

```json
{
  "id": "12fa85f64-5717-4562-b3fc-2c963f66afb4",
  "message": "What should I do if there's a fire in my building?",
  "response": "🔥 **FIRE EMERGENCY PROTOCOL:**\n\n1. **IMMEDIATE ACTION**: Call emergency services (911) immediately\n2. **EVACUATE SAFELY**: Leave the building via the nearest safe exit\n3. **STAY LOW**: Crawl under smoke to avoid inhalation\n4. **DON'T USE ELEVATORS**: Always use stairs during fire emergencies\n5. **MEETING POINT**: Go to your designated assembly area\n6. **DON'T RE-ENTER**: Never go back inside for belongings\n\nIs this an active emergency? If so, please call emergency services immediately and use our emergency reporting feature.",
  "timestamp": "2025-04-15T12:00:33Z",
  "user_role": "CITIZEN"
}
```

### Send Message via ViewSet

**Endpoint**: `POST /chatbot/sessions/send_message/`

**Description**: Send a message using the ChatViewSet for more detailed session management

**Authentication**: Required

**Request Body**:

```json
{
  "message": "How do I perform CPR?"
}
```

**Response (201 Created)**:

```json
{
  "id": "13fa85f64-5717-4562-b3fc-2c963f66afb5",
  "message": "How do I perform CPR?",
  "response": "🚑 **CPR (Cardiopulmonary Resuscitation) Steps:**\n\n**FIRST: Call emergency services (911) immediately**\n\n**For Adults:**\n1. **Check Responsiveness**: Tap shoulders, shout \"Are you okay?\"\n2. **Position**: Place on firm, flat surface\n3. **Hand Placement**: Heel of hand on center of chest, between nipples\n4. **Compressions**: Push hard and fast, at least 2 inches deep\n5. **Rate**: 100-120 compressions per minute\n6. **Count**: 30 compressions, then 2 rescue breaths\n7. **Continue**: Until emergency services arrive\n\n**Important**: Only perform if trained. If untrained, focus on continuous chest compressions.\n\nIs this an emergency situation happening now?",
  "timestamp": "2025-04-15T12:05:33Z"
}
```

### Get Chat Session History

**Endpoint**: `GET /chatbot/sessions/session_history/?limit=10`

**Description**: Retrieve chat history for the current user

**Authentication**: Required

**Query Parameters**:

- `limit`: Number of recent sessions to retrieve (default: 20)

**Response (200 OK)**:

```json
[
  {
    "id": "13fa85f64-5717-4562-b3fc-2c963f66afb5",
    "user": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "user_username": "john_doe",
    "message": "How do I perform CPR?",
    "response": "🚑 **CPR (Cardiopulmonary Resuscitation) Steps:**\n\n**FIRST: Call emergency services (911) immediately**...",
    "timestamp": "2025-04-15T12:05:33Z"
  },
  {
    "id": "12fa85f64-5717-4562-b3fc-2c963f66afb4",
    "user": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "user_username": "john_doe",
    "message": "What should I do if there's a fire in my building?",
    "response": "🔥 **FIRE EMERGENCY PROTOCOL:**\n\n1. **IMMEDIATE ACTION**: Call emergency services (911) immediately...",
    "timestamp": "2025-04-15T12:00:33Z"
  }
]
```

### Get Quick Emergency Responses

**Endpoint**: `GET /chatbot/sessions/quick_responses/`

**Description**: Get predefined quick responses for common emergency scenarios

**Authentication**: Required

**Response (200 OK)**:

```json
{
  "fire": "🔥 FIRE EMERGENCY:\n1. Call emergency services immediately\n2. Evacuate the building safely\n3. Stay low to avoid smoke\n4. Don't use elevators\n5. Meet at designated assembly point",
  "medical": "🚑 MEDICAL EMERGENCY:\n1. Call emergency services (911)\n2. Check for responsiveness\n3. Check breathing and pulse\n4. Apply first aid if trained\n5. Stay with the person until help arrives",
  "police": "🚓 POLICE EMERGENCY:\n1. Call emergency services immediately\n2. Stay in a safe location\n3. Provide clear location details\n4. Follow dispatcher instructions\n5. Stay on the line until help arrives",
  "natural_disaster": "🌪️ NATURAL DISASTER:\n1. Follow local emergency broadcasts\n2. Take shelter immediately\n3. Stay away from windows\n4. Have emergency supplies ready\n5. Follow evacuation orders if given"
}
```

### Clear Chat History

**Endpoint**: `DELETE /chatbot/sessions/clear_history/`

**Description**: Clear all chat history for the current user

**Authentication**: Required

**Response (200 OK)**:

```json
{
  "message": "Cleared 15 chat sessions"
}
```

### Get Chat Statistics

**Endpoint**: `GET /chatbot/stats/`

**Description**: Get chat usage statistics for the current user

**Authentication**: Required

**Response (200 OK)**:

```json
{
  "total_sessions": 47,
  "recent_sessions": 8,
  "user_role": "CITIZEN"
}
```

### List All Chat Sessions

**Endpoint**: `GET /chatbot/sessions/`

**Description**: Get a paginated list of all chat sessions for the current user

**Authentication**: Required

**Response (200 OK)**:

```json
{
  "count": 47,
  "next": "http://localhost:8000/api/chatbot/sessions/?page=2",
  "previous": null,
  "results": [
    {
      "id": "13fa85f64-5717-4562-b3fc-2c963f66afb5",
      "user": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "user_username": "john_doe",
      "message": "How do I perform CPR?",
      "response": "🚑 **CPR (Cardiopulmonary Resuscitation) Steps:**...",
      "timestamp": "2025-04-15T12:05:33Z"
    }
  ]
}
```

### Get Specific Chat Session

**Endpoint**: `GET /chatbot/sessions/{id}/`

**Description**: Retrieve details of a specific chat session

**Authentication**: Required

**Response (200 OK)**:

```json
{
  "id": "13fa85f64-5717-4562-b3fc-2c963f66afb5",
  "user": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "user_username": "john_doe",
  "message": "How do I perform CPR?",
  "response": "🚑 **CPR (Cardiopulmonary Resuscitation) Steps:**\n\n**FIRST: Call emergency services (911) immediately**\n\n**For Adults:**\n1. **Check Responsiveness**: Tap shoulders, shout \"Are you okay?\"\n2. **Position**: Place on firm, flat surface\n3. **Hand Placement**: Heel of hand on center of chest, between nipples\n4. **Compressions**: Push hard and fast, at least 2 inches deep\n5. **Rate**: 100-120 compressions per minute\n6. **Count**: 30 compressions, then 2 rescue breaths\n7. **Continue**: Until emergency services arrive\n\n**Important**: Only perform if trained. If untrained, focus on continuous chest compressions.\n\nIs this an emergency situation happening now?",
  "timestamp": "2025-04-15T12:05:33Z"
}
```

## Notifications

### List User Notifications

**Endpoint**: `GET /notifications/`

**Description**: Get a list of notifications for the current user

**Authentication**: Required

**Query Parameters**:

- `page`: Page number for pagination
- `page_size`: Number of items per page (default: 20, max: 50)

**Response (200 OK)**:

```json
{
  "count": 2,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "7fa85f64-5717-4562-b3fc-2c963f66afaf",
      "title": "Emergency Nearby",
      "message": "Emergency reported 0.5km from your location",
      "notification_type": "EMERGENCY",
      "is_read": false,
      "timestamp": "2025-04-15T10:35:33Z"
    },
    {
      "id": "8fa85f64-5717-4562-b3fc-2c963f66afb0",
      "title": "Status Update",
      "message": "Emergency services are responding to your report",
      "notification_type": "UPDATE",
      "is_read": true,
      "timestamp": "2025-04-15T10:40:33Z"
    }
  ]
}
```

### Get Notification Details

**Endpoint**: `GET /notifications/{id}/`

**Description**: Get details of a specific notification

**Authentication**: Required

**Response (200 OK)**:

```json
{
  "id": "7fa85f64-5717-4562-b3fc-2c963f66afaf",
  "title": "Emergency Nearby",
  "message": "Emergency reported 0.5km from your location",
  "notification_type": "EMERGENCY",
  "is_read": false,
  "timestamp": "2025-04-15T10:35:33Z"
}
```

### Mark Notification as Read

**Endpoint**: `PATCH /notifications/{id}/`

**Description**: Mark a notification as read

**Authentication**: Required

**Request Body**:

```json
{
  "is_read": true
}
```

**Response (200 OK)**:

```json
{
  "id": "7fa85f64-5717-4562-b3fc-2c963f66afaf",
  "title": "Emergency Nearby",
  "message": "Emergency reported 0.5km from your location",
  "notification_type": "EMERGENCY",
  "is_read": true,
  "timestamp": "2025-04-15T10:35:33Z"
}
```

### Mark All Notifications as Read

**Endpoint**: `POST /notifications/mark-all-read/`

**Description**: Mark all notifications as read

**Authentication**: Required

**Response (200 OK)**:

```json
{
  "status": "All notifications marked as read"
}
```

### Register FCM Token

**Endpoint**: `POST /notifications/register-token/`

**Description**: Register a Firebase Cloud Messaging token for push notifications

**Authentication**: Required

**Request Body**:

```json
{
  "fcm_token": "eEGH_-QORtGUz9b...LONG_FCM_TOKEN",
  "device_type": "ANDROID"
}
```

**Device Type Options**:

- `ANDROID`: Android device
- `IOS`: iOS device

**Response (200 OK)**:

```json
{
  "status": "FCM token registered"
}
```

## Map Services

### Create Route Request

**Endpoint**: `POST /map/`

**Description**: Request a route between two points

**Authentication**: Required

**Request Body**:

```json
{
  "start_location": "38.4192,27.1287",
  "end_location": "38.4500,27.1800",
  "waypoints": ["38.4300,27.1400"],
  "avoid_hazards": true
}
```

**Response (201 Created)**:

```json
{
  "id": "9fa85f64-5717-4562-b3fc-2c963f66afb1",
  "user": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "start_location": "38.4192,27.1287",
  "end_location": "38.4500,27.1800",
  "waypoints": ["38.4300,27.1400"],
  "avoid_hazards": true,
  "timestamp": "2025-04-15T11:00:33Z",
  "routes": [
    {
      "id": "10fa85f64-5717-4562-b3fc-2c963f66afb2",
      "polyline": "gpq`FccveEgB}HoA...LONG_POLYLINE_STRING",
      "distance": 5.3,
      "duration": 15.2,
      "timestamp": "2025-04-15T11:00:33Z"
    }
  ]
}
```

## Dashboards

### Citizen Dashboard

**Endpoint**: `GET /dashboards/citizen/`

**Description**: Get dashboard data for citizens

**Authentication**: Required (CITIZEN role)

**Response (200 OK)**:

```json
{
  "username": "john_doe",
  "role": "CITIZEN",
  "recent_notifications": [
    {
      "id": "7fa85f64-5717-4562-b3fc-2c963f66afaf",
      "title": "Emergency Nearby",
      "message": "Emergency reported 0.5km from your location",
      "timestamp": "2025-04-15T10:35:33Z",
      "is_read": false
    }
  ],
  "unread_notifications": 1,
  "profile_completeness": 80,
  "recent_reports": [
    {
      "id": "6fa85f64-5717-4562-b3fc-2c963f66afae",
      "description": "Building collapsed, need urgent help",
      "status": "RESPONDING",
      "timestamp": "2025-04-15T10:30:33Z",
      "reporter_type": "VICTIM"
    }
  ],
  "ongoing_emergencies": 1,
  "total_reports": 3,
  "resolved_reports": 2,
  "chat_sessions": {
    "total": 47,
    "recent": 8
  }
}
```

### Emergency Service Dashboard

**Endpoint**: `GET /dashboards/emergency-service/`

**Description**: Get dashboard data for emergency services

**Authentication**: Required (FIRE_STATION, POLICE, or RED_CRESCENT role)

**Response (200 OK)**:

```json
{
  "username": "central_fire_station",
  "role": "FIRE_STATION",
  "recent_notifications": [],
  "unread_notifications": 0,
  "profile_completeness": 90,
  "pending_emergencies": [
    {
      "id": "11fa85f64-5717-4562-b3fc-2c963f66afb3",
      "description": "Fire in apartment building",
      "status": "PENDING",
      "timestamp": "2025-04-15T11:30:33Z",
      "latitude": 38.42,
      "longitude": 27.13,
      "is_emergency": true
    }
  ],
  "current_status": {
    "pending": 5,
    "responding": 3,
    "on_scene": 2
  },
  "service_type": "FIRE_STATION",
  "recent_activity": {
    "today": 8,
    "this_week": 32
  }
}
```

## Error Handling

### Standard Error Responses

All endpoints return standardized error responses:

**400 Bad Request**:

```json
{
  "error": "Invalid request data",
  "details": {
    "message": ["This field is required."]
  }
}
```

**401 Unauthorized**:

```json
{
  "detail": "Authentication credentials were not provided."
}
```

**403 Forbidden**:

```json
{
  "detail": "You do not have permission to perform this action."
}
```

**404 Not Found**:

```json
{
  "detail": "Not found."
}
```

**500 Internal Server Error**:

```json
{
  "error": "Internal server error",
  "message": "An unexpected error occurred"
}
```

### Chatbot-Specific Errors

**AI Service Unavailable**:

```json
{
  "error": "Failed to process message",
  "details": "I'm sorry, I'm having trouble processing your request right now. For immediate emergencies, please call your local emergency services."
}
```

**Empty Message**:

```json
{
  "error": "Message cannot be empty"
}
```

## Rate Limiting

- **Chatbot endpoints**: 60 requests per minute per user
- **Emergency reporting**: 10 requests per minute per user
- **Authentication endpoints**: 20 requests per minute per IP
- **General API**: 100 requests per minute per authenticated user

## Webhooks

### Emergency Status Updates

ResQ can send webhook notifications when emergency statuses change:

**Webhook URL**: Configure in admin panel

**Payload Example**:

```json
{
  "event": "emergency_status_changed",
  "emergency_id": "6fa85f64-5717-4562-b3fc-2c963f66afae",
  "old_status": "PENDING",
  "new_status": "RESPONDING",
  "timestamp": "2025-04-15T10:45:33Z",
  "location": {
    "latitude": 38.4192,
    "longitude": 27.1287
  }
}
```

## SDK and Integration

### JavaScript SDK

```javascript
// Initialize ResQ client
const resq = new ResQClient({
  baseURL: "http://localhost:8000/api/",
  token: "your_jwt_token",
});

// Send chat message
const response = await resq.chatbot.sendMessage(
  "What should I do in an earthquake?"
);
console.log(response.response);

// Report emergency
const emergency = await resq.emergency.report({
  description: "Building collapse",
  location: { latitude: 38.4192, longitude: 27.1287 },
  reporter_type: "VICTIM",
});
```

### Mobile SDK (React Native)

```javascript
import { ResQMobileClient } from "resq-mobile-sdk";

const client = new ResQMobileClient({
  baseURL: "http://localhost:8000/api/",
  firebaseConfig: {
    /* Firebase config */
  },
});

// Chat with AI
const chatResponse = await client.chat("How to treat burns?");

// Send location
await client.location.update({
  latitude: 38.4192,
  longitude: 27.1287,
});
```

## Social Media Integration

ResQ can automatically share emergency reports to social media platforms to increase visibility and response time.

### Social Post

**Endpoint**: `POST /social/post/`

**Description**: Post a message with a photo or video to social media platforms (Facebook, Telegram, Discord)

**Authentication**: Required

**Request Body** (multipart/form-data):

```json
{
  "content": "Emergency alert: Flooding in downtown area",
  "file": [binary file - photo or video]
}
```

**Response (200 OK)**:

```json
{
  "message": "Posted to all social media platforms",
  "results": [
    {
      "platform": "FACEBOOK",
      "status": "success"
    },
    {
      "platform": "TELEGRAM",
      "status": "success"
    },
    {
      "platform": "DISCORD",
      "status": "success"
    }
  ]
}
```

**Possible Errors**:

- 400 Bad Request: If no file is provided
- 500 Internal Server Error: If there's an issue posting to any platform

### Social Media Emergency Integration

When reporting emergencies using the emergency reporting endpoint, emergency information is automatically shared to social media platforms.

The existing emergency reporting endpoint (`POST /emergency/reports/report_emergency/`) now includes social media integration.

**Additions to Emergency Reporting**:

- You can now include a `media_file` in the multipart/form-data request to attach media to the social posts
- Emergency details, including description, type, and location will be formatted and shared on Facebook, Telegram, and Discord
- The response includes results of social media posting attempts

**Example Request** (multipart/form-data):

```json
{
  "reporter_type": "VICTIM",
  "description": "Building collapsed, need urgent help",
  "latitude": 38.4192,
  "longitude": 27.1287,
  "tags": [
    "3fa85f64-5717-4562-b3fc-2c963f66afab",
    "5fa85f64-5717-4562-b3fc-2c963f66afad"
  ],
  "media_file": [binary file - photo or video]
}
```

**Response (201 Created)**:

```json
{
  "id": "6fa85f64-5717-4562-b3fc-2c963f66afae",
  "reporter": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "reporter_type": "VICTIM",
  "description": "Building collapsed, need urgent help",
  "latitude": 38.4192,
  "longitude": 27.1287,
  "status": "PENDING",
  "is_emergency": true,
  "tags": [
    {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afab",
      "name": "Building Collapse",
      "emergency_type": "EARTHQUAKE"
    },
    {
      "id": "5fa85f64-5717-4562-b3fc-2c963f66afad",
      "name": "Trapped Individuals",
      "emergency_type": "DISASTER"
    }
  ],
  "timestamp": "2025-04-15T10:30:33Z",
  "social_post_results": {
    "facebook": "Post ID or URL",
    "telegram": "Message ID",
    "discord": "Message Link"
  }
}
```

### Get Social Post Status

**Endpoint**: `GET /social/posts/{id}/`

**Description**: Get the status of a specific social media post

**Authentication**: Required

**Response (200 OK)**:

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa9",
  "platform": "FACEBOOK",
  "content": "Emergency alert: Flooding in downtown area",
  "photo": "http://localhost:8000/media/social/photos/flood.jpg",
  "video": null,
  "status": "POSTED",
  "timestamp": "2025-04-15T14:25:33Z"
}
```

### List Social Posts

**Endpoint**: `GET /social/posts/`

**Description**: Get a list of all social media posts made by the user

**Authentication**: Required

**Response (200 OK)**:

```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa9",
    "platform": "FACEBOOK",
    "content": "Emergency alert: Flooding in downtown area",
    "photo": "http://localhost:8000/media/social/photos/flood.jpg",
    "video": null,
    "status": "POSTED",
    "timestamp": "2025-04-15T14:25:33Z"
  },
  {
    "id": "4fa85f64-5717-4562-b3fc-2c963f66afab",
    "platform": "TELEGRAM",
    "content": "Emergency alert: Flooding in downtown area",
    "photo": "http://localhost:8000/media/social/photos/flood.jpg",
    "video": null,
    "status": "POSTED",
    "timestamp": "2025-04-15T14:25:34Z"
  },
  {
    "id": "5fa85f64-5717-4562-b3fc-2c963f66afac",
    "platform": "DISCORD",
    "content": "Emergency alert: Flooding in downtown area",
    "photo": "http://localhost:8000/media/social/photos/flood.jpg",
    "video": null,
    "status": "POSTED",
    "timestamp": "2025-04-15T14:25:35Z"
  }
]
```

### Social Media Format

**Social Media Post Format**:

- **Facebook**: Supports text, photos, and videos. Use the `/social/post/` endpoint to share.
- **Telegram**: Supports text, photos, and videos. Use the `/social/post/` endpoint to share.
- **Discord**: Supports text, photos, and videos. Use the `/social/post/` endpoint to share.

**Note**: Ensure compliance with each platform's content policies and guidelines.
]

```

### Social Media Format

**Social Media Post Format**:

- **Facebook**: Supports text, photos, and videos. Use the `/social/post/` endpoint to share.
- **Telegram**: Supports text, photos, and videos. Use the `/social/post/` endpoint to share.
- **Discord**: Supports text, photos, and videos. Use the `/social/post/` endpoint to share.

**Note**: Ensure compliance with each platform's content policies and guidelines.
```
