# Component Design - Emergency Resource Dispatch System

## 📦 Microservices Architecture

The system is composed of **9 core microservices**, each responsible for a specific domain. This separation ensures **scalability, maintainability, and fault isolation**.

---

## 1️⃣ Incident Service

**Purpose**: Manages the lifecycle of emergency incidents from creation to closure.

### Responsibilities
- Create new incident records
- Update incident status
- Track incident history
- Store incident metadata (photos, descriptions)

### API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/incidents` | Create new incident |
| GET | `/api/v1/incidents/:id` | Get incident details |
| PATCH | `/api/v1/incidents/:id` | Update incident |
| GET | `/api/v1/incidents` | List incidents (paginated) |
| DELETE | `/api/v1/incidents/:id` | Cancel incident |

### Data Model
```typescript
interface Incident {
  id: string;
  citizen_id: string;
  type: 'ACCIDENT' | 'FIRE' | 'MEDICAL' | 'CRIME' | 'OTHER';
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  status: 'PENDING' | 'ASSIGNED' | 'EN_ROUTE' | 'ON_SCENE' | 'CLOSED' | 'CANCELLED';
  location: {
    latitude: number;
    longitude: number;
    address: string;
  };
  description: string;
  evidence_urls: string[];
  created_at: Date;
  updated_at: Date;
  resolved_at: Date | null;
}
```

### Technology Stack
- **Runtime**: Node.js with Express
- **Database**: PostgreSQL
- **Cache**: Redis (for status lookups)

---

## 2️⃣ Dispatch Engine Service (Enhanced)

**Purpose**: The brain of the system - matches incidents with the best available responders using intelligent algorithms.

### Enhanced Features

#### 🔄 Radius Expansion Logic
The dispatch engine now automatically expands the search radius if no responders are available:

```
Step 1: Find responders within 5 km
        ↓
   ┌────┴────┐
   │Found?   │
   └────┬────┘
    Yes   No
     │     │
     │     ↓
     │  Expand to 10 km
     │     ↓
     │  ┌────┴────┐
     │  │Found?  │
     │  └────┬────┘
     │   Yes   No
     │    │     │
     │    │     ↓
     │    │  Expand to 20 km
     │    │     ↓
     │    │  ┌────┴────┐
     │    │  │Found?  │
     │    │  └────┬────┘
     │    │   Yes   No
     │    │    │     │
     │    │    │     ↓
     │    │    │  Queue for later
     │    │    ↓
     │    └───► Select best match
     ↓
```

#### ⏱️ Responder Acceptance Timeout
When a responder is selected, the system waits for acceptance:

```
1. Send dispatch request to responder
         ↓
   Wait 10 seconds
         ↓
   ┌────┴────┐
   │Accepts? │ ──► Update status to ASSIGNED
   └────┬────┘
    Yes   No
     │     │
     │     ↓
     │  Try next best responder
     │     ↓
     │  (max 3 attempts)
     ↓
   If all decline → Queue incident
```

#### 🎯 Manual Override (Dispatcher Dashboard)
Real emergencies may require manual intervention. The dispatcher dashboard provides override capabilities:

```
Automated dispatch fails
        │
        ▼
┌───────────────────────────┐
│  Incident Queued          │
│  → Visible on Dashboard  │
└────────────┬─────────────┘
             │
             ▼
   ┌─────────────────┐
   │ Dispatcher Views│
   │ Queued Incidents│
   └────────┬────────┘
            │
            ▼
   ┌────────────────────────┐
   │ Manual Assignment:     │
   │ • Select responder    │
   │ • Override priority   │
   │ • Add notes           │
   └────────┬───────────────┘
            │
            ▼
   ┌─────────────────────────┐
   │ Dispatcher confirms    │
   │ → Notification sent    │
   └─────────────────────────┘
```

| Override Action | Authorization | Audit Log |
|-----------------|---------------|-----------|
| Manual assignment | DISPATCHER, ADMIN | Always |
| Skip priority queue | ADMIN only | Always |
| Cancel dispatch | Any responder | Always |
| Reassign to different type | DISPATCHER | Always |

#### 🔇 Responder Silence Handling
If a responder receives notification but doesn't respond:

```
Responder notified (Push + SMS)
          ↓
    Wait 10 seconds
          ↓
    ┌────┴────┐
    │Accepted?│
    └────┬────┘
     Yes    No
      │      │
      ▼      ▼
  Assign   ┌────────────────────┐
           │ Network issue?     │
           │ (Check device status)│
           └────────┬───────────┘
                    │
                    ▼
            Try next responder
                    │
                    ▼
            (max 3 attempts)
                    │
                    ▼
            Escalate to dashboard
            (Manual override required)
```

### Core Scoring Algorithm
```typescript
interface ResponderScore {
  responder_id: string;
  score: number; // Lower is better
  
  // Score components
  distance_score: number;    // Distance × 2.0
  time_score: number;       // Estimated arrival time × 1.5
  availability_score: number; // Ready to respond × 3.0
  type_match_score: number;   // Correct vehicle type × 4.0
}

function calculateScore(responder: Responder, incident: Incident): number {
  const distance = getDistance(responder.location, incident.location);
  const arrivalTime = estimateArrivalTime(distance, trafficConditions);
  
  const score = 
    (distance * 2.0) +           // Distance factor
    (arrivalTime * 1.5) +        // Time factor  
    (responder.isReady ? 0 : 50) + // Availability penalty
    (typeMatch ? 0 : 100);       // Type mismatch penalty
    
  return score;
}
```

### Event Flow
```
1. Receive incident from Event Bus
2. Add to Dispatch Queue (priority-based)
3. Worker picks up from queue
4. Query available responders (start with 5km radius)
5. If no responders → expand radius (10km → 20km)
6. Calculate scores for each responder
7. Select best match
8. Send dispatch notification (10s timeout)
9. On accept: Update incident → Start tracking
10. On decline: Try next best (max 3 attempts)
11. If all fail: Queue incident for retry
```

#### Dedicated Dispatch Queue

To prevent overload during spike scenarios (e.g., earthquake generating 5000 incidents in 30 seconds), dispatch requests are queued separately:

```
Incident Created
        │
        ▼
Kafka Event: incident.created
        │
        ▼
Dispatch Request Queue (Kafka topic: dispatch.requests)
        │
        ▼
┌───────────────────────────────┐
│ Dispatch Worker Pool          │
│ • Scales based on queue size │
│ • Pulls requests sequentially │
│ • Processes with backpressure│
└───────────────────────────────┘
```

| Component | Configuration |
|-----------|---------------|
| Queue | Kafka topic `dispatch.requests` |
| Partitioning | By incident severity |
| Retention | 24 hours |
| Consumer Groups | 3-5 workers (auto-scale) |

**Benefits:**
- Backpressure handling during spikes
- Smoother load distribution
- Easier horizontal scaling
- Queue depth monitoring for alerts

#### Priority Queue Dispatching

Incidents are processed based on severity priority, not arrival order. This ensures life-threatening cases are handled immediately:

```
Priority Queue Structure

[CRITICAL] ← Highest priority (1)
   ↓
[HIGH]      ← Priority (2)
   ↓
[MEDIUM]    ← Priority (3)
   ↓
[LOW]       ← Lowest priority (4)
```

| Severity | Priority | Processing |
|----------|----------|------------|
| CRITICAL | 1 | Immediate, dedicated workers |
| HIGH | 2 | Next available worker |
| MEDIUM | 3 | Standard queue |
| LOW | 4 | Background processing |

Dispatch workers always pull from **highest priority first**, ensuring critical emergencies are never delayed by minor incidents.

#### Priority-Based Dispatch Modes

For extreme emergencies where every second counts (e.g., Cardiac Arrest, Severe Trauma, Active Shooter), the standard sequential polling approach may be too slow. We implement **Multicast Dispatching** as an additional mode:

```
CRITICAL Incident Detected (e.g., Cardiac Arrest)
         │
         ▼
┌─────────────────────────┐
│  Enable Multicast Mode  │
└────────────┬────────────┘
             │
             ▼
Find TOP 3 closest responders
within expanded radius
             │
             ▼
┌─────────────────────────┐
│  Send SIMULTANEOUS      │
│  dispatch alerts to     │
│  all 3 responders       │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  First to ACCEPT wins   │
│  (Race condition ok)   │
└────────────┬────────────┘
             │
             ▼
 Others auto-cancelled
 upon first acceptance
```

| Dispatch Mode | Use Case | Behavior |
|---------------|----------|----------|
| Sequential (Default) | Normal emergencies | Try one responder at a time (10s timeout) |
| Multicast | Life-threatening emergencies | Alert top 3 closest simultaneously |

| Parameter | Sequential Mode | Multicast Mode |
|-----------|-----------------|----------------|
| Responders Contacted | 1 | 3 |
| Timeout | 10 seconds | 5 seconds each |
| Target Response Time | < 30 seconds | < 15 seconds |
| Cancellation | Manual next attempt | Auto on first accept |

**When Multicast is Triggered:**
- Incident severity = CRITICAL
- Emergency type in [CARDIAC_ARREST, SEVERE_TRAUMA, ACTIVE_SHOOTER, MASS_CASUALTY]
- Dispatcher manually enables multicast mode

This approach significantly reduces response time for the most critical emergencies while maintaining the standard sequential approach for normal incidents.

#### Responder Reservation System

To prevent race conditions where two dispatch workers assign the same responder simultaneously, we implement a reservation lock:

```
Candidate responder found
        │
        ▼
┌──────────────────────────┐
│ Acquire Redis Lock       │
│ Key: responder_lock:{id} │
│ TTL: 10 seconds          │
└────────────┬─────────────┘
             │
        ┌────┴────┐
        │ Acquired?│
        └────┬────┘
        Yes   No
         │      │
         ▼      ▼
    Send    Try next
 dispatch   responder
    request
         │
         ▼
   ┌─────┴─────┐
   │ Responds? │
   └─────┬─────┘
    Yes    No
     │      │
     ▼      ▼
Confirm   Release
lock      lock
```

| Lock Parameter | Value |
|----------------|-------|
| Key Format | `responder_lock:{responder_id}` |
| TTL | 10 seconds |
| Retry | 3 attempts |

This prevents **double assignment race conditions** during high concurrency.

### Technology Stack
- **Runtime**: Java Spring Boot (for compute-heavy operations)
- **Algorithm**: Custom Java implementation
- **Event Bus**: Kafka consumer

---

## 3️⃣ Location Service

**Purpose**: Handles all geospatial operations including GPS coordinates, proximity searches, and route calculations.

### Responsibilities
- Store and update responder GPS coordinates
- Find nearest responders to incidents using PostGIS
- Calculate distances and travel times
- Provide route information from map providers

### High-Volume Location Ingestion Pipeline

Location updates are extremely frequent - a responder might send 1 location update per second. For 10,000 responders, that's 10,000 writes/sec. We use a Kafka-based ingestion pipeline:

```
┌─────────────────┐
│  Responder App  │
│  (GPS Updates)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Tracking Service │
│ (WebSocket/HTTP) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Kafka       │
│ location.updates│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Location Service│
│  (Consumer)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│   Redis GEO     │ ←── │  PostgreSQL     │
│ (fast queries)  │     │   + PostGIS     │
└────────┬────────┘     │ (persistent)    │
         │             └─────────────────┘
         ▼
┌─────────────────────────┐
│ Dispatch Engine Query   │
└─────────────────────────┘
```

| Storage | Purpose | Query Speed |
|---------|---------|-------------|
| Redis GEO | Nearest-neighbor search | < 5ms |
| PostgreSQL + PostGIS | Historical data, analytics | < 100ms |

**Why Redis GEO first?**
- Redis GEO queries are **extremely fast** for nearest-neighbor search
- Dramatically reduces database load
- Dispatch Engine flow:
  1. Incident occurs
  2. Query Redis GEO for nearby responders
  3. Fetch metadata from PostgreSQL
  4. Return results

| Component | Benefit |
|-----------|---------|
| Kafka | Burst protection, smooth writes |
| Consumer groups | Scalable processing |
| Batch processing | Reduced DB load |
| Replay capability | Recover from failures |

### Key Features
| Feature | Implementation |
|---------|----------------|
| Geocoding | Google Maps Geocoding API |
| Distance Calculation | Haversine formula + PostGIS |
| Nearest Search | PostGIS KNN queries |
| Route Optimization | Google Directions API |

### API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/locations/update` | Update device location |
| GET | `/api/v1/locations/responders` | Get nearby responders |
| GET | `/api/v1/locations/route` | Calculate route to incident |
| GET | `/api/v1/locations/history/:responderId` | Location history |

### Technology Stack
- **Runtime**: Node.js with Express
- **Database**: PostgreSQL with PostGIS extension
- **Cache**: Redis (for live locations)

---

## 4️⃣ Tracking Service (NEW)

**Purpose**: Handles real-time WebSocket connections and live location updates to apps.

### Why Separate from Location Service?
- **Performance**: WebSocket connections are resource-intensive
- **Scalability**: Can scale independently from location queries
- **Focus**: Location Service handles queries, Tracking Service handles live updates

### Responsibilities
- Maintain WebSocket connections with mobile apps
- Push real-time location updates to citizen and responder apps
- Handle connection lifecycle (connect, disconnect, reconnect)
- Broadcast incident status changes

### WebSocket Events
```typescript
// Server → Client Events
interface WSEvents {
  // Tracking updates
  'responder:location': { responder_id, lat, lng, timestamp };
  'incident:status': { incident_id, status, responder_id };
  
  // Dispatch notifications
  'dispatch:new': { incident_id, location, type, severity };
  'dispatch:accepted': { incident_id, responder_id, eta };
  
  // System
  'connection:ack': { session_id };
  'error': { code, message };
}

// Client → Server Events
interface ClientEvents {
  'location:update': { lat, lng };
  'dispatch:accept': { incident_id };
  'dispatch:decline': { incident_id, reason };
  'status:update': { status };
}
```

### Connection Management
```
Client connects
     ↓
Authenticate via JWT
     ↓
Subscribe to channels (user-specific)
     ↓
┌────────────────────────────┐
│    WebSocket Connected     │
│  • Push location updates   │
│  • Receive status changes  │
│  • Handle reconnections    │
└────────────────────────────┘
     ↓
Client disconnects → Clean up subscriptions
```

### Technology Stack
- **Runtime**: Node.js with Socket.io
- **Pub/Sub**: Redis for broadcasting
- **Connection State**: In-memory + Redis for persistence

### WebSocket Gateway Layer

For 50,000+ concurrent connections, we add a dedicated WebSocket gateway layer for horizontal scaling:

```
┌──────────────────────────────────────────────────────┐
│                    Clients                            │
│  (Citizen App, Responder App, Dispatch Dashboard)    │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│              NGINX WebSocket Gateway                  │
│  • Connection management                              │
│  • Load balancing                                     │
│  • SSL termination                                    │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│              Redis Pub/Sub                            │
│  • Cross-node message broadcasting                   │
│  • Connection state sync                              │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│            Tracking Service Cluster                   │
│  • Multiple service instances                         │
│  • Socket.io cluster mode                             │
│  • Horizontal scaling                                │
└──────────────────────────────────────────────────────┘
```

| Component | Technology |
|-----------|------------|
| Gateway | NGINX with WebSocket support |
| Pub/Sub | Redis Cluster |
| Service | Socket.io with Redis adapter |

**Benefits:**
- Handle 100k+ concurrent connections
- Horizontal scaling of WebSocket servers
- Automatic reconnection handling
- Message broadcasting across nodes

---

## 5️⃣ Severity Engine Service

**Purpose**: Automatically calculates the priority level of incidents based on multiple factors.

### Responsibilities
- Analyze incident details
- Calculate severity score (0-100)
- Assign priority level (LOW, MEDIUM, HIGH, CRITICAL)
- Learn from historical data (ML enhancement)

### Severity Factors
| Factor | Weight | Description |
|--------|--------|-------------|
| Emergency Type | 30% | Type of emergency (Fire = higher) |
| Location Type | 15% | Urban vs Rural, near hospital/school |
| Time of Day | 10% | Rush hour = higher |
| Number of Victims | 25% | Multiple casualties = critical |
| Citizen Input | 20% | User's perceived severity |

### Severity Levels
```
CRITICAL (80-100): Multiple casualties, life-threatening
HIGH (60-79): Serious emergency, potential life threat
MEDIUM (30-59): Moderate emergency, requires attention
LOW (0-29): Minor emergency, can wait
```

### Technology Stack
- **Runtime**: Python (for ML capabilities)
- **ML Framework**: TensorFlow (future enhancement)
- **Rules Engine**: Drools

---

## 6️⃣ Resource Manager Service

**Purpose**: Manages emergency responders (ambulances, fire trucks, police units) and their availability.

### Responsibilities
- CRUD operations for responders
- Track responder status (AVAILABLE, BUSY, OFF_DUTY, MAINTENANCE)
- Manage responder schedules
- Track vehicle information and capacity
- Handle shift management

### Responder Types
| Type | Code | Vehicles |
|------|------|----------|
| Ambulance | MEDICAL | Ambulance |
| Fire Truck | FIRE | Fire Engine, Ladder Truck |
| Police | CRIME | Patrol Car |
| Combined | COMBINED | Multi-unit response |

### Status Flow
```
OFF_DUTY → AVAILABLE → ASSIGNED → EN_ROUTE → ON_SCENE → COMPLETED → AVAILABLE
                                      ↓
                                   BUSY (if additional assignment needed)
```

### Technology Stack
- **Runtime**: Node.js with Express
- **Database**: PostgreSQL

---

## 7️⃣ Notification Service

**Purpose**: Handles all communications - push notifications, SMS, and voice calls.

### Responsibilities
- Send push notifications to mobile apps
- Send SMS alerts to responders
- Initiate voice calls for critical incidents
- Manage notification templates
- Handle delivery status and retries

### Notification Types
| Type | Channel | Use Case |
|------|---------|----------|
| New Assignment | Push + SMS | Dispatch new emergency |
| Status Update | Push | Incident status change |
| Critical Alert | Push + SMS + Voice | Mass emergency |
| System Alert | Email | System notifications |

#### Notification Escalation for High-Severity Incidents

For responders, a push notification is easily missed especially when the device is in silent mode or the responder is in a noisy environment. We implement an **automated escalation system** for high-severity incidents:

```
Dispatch sent to responder
         │
         ▼
Wait 15 seconds for acknowledgment
         │
         ▼
┌─────────────────────────┐
│ Acknowledged within    │
│ 15 seconds?             │
└────────────┬────────────┘
      Yes           No
       │             │
       ▼             ▼
   Continue    ┌─────────────────────┐
               │ ESCALATION TRIGGER  │
               │ - Severity: HIGH    │
               │   or CRITICAL      │
               │ - No acknowledgment│
               └──────────┬──────────┘
                          │
                          ▼
┌─────────────────────────────────────────┐
│  Step 1: Send SMS (already sent)        │
│  Step 2: Send Push notification retry   │
│  Step 3: Initiate VoIP/Automated Call   │
└─────────────────────────────────────────┘
                          │
                          ▼
         ┌────────────────────────────────┐
         │ Automated Voice Message:       │
         │ "EMERGENCY: Cardiac Arrest at   │
         │ [address]. Press 1 to accept,   │
         │ Press 2 to decline."            │
         └────────────────────────────────┘
```

| Escalation Level | Channel | Delay | Use Case |
|------------------|---------|-------|----------|
| Level 1 | Push Notification | Immediate | All dispatches |
| Level 2 | SMS | Immediate | All dispatches |
| Level 3 | Push Retry | 15 seconds | No acknowledgment |
| Level 4 | **VoIP/Automated Voice Call** | 15 seconds | HIGH/CRITICAL severity |
| Level 5 | Dispatcher Dashboard Alert | 30 seconds | All levels failed |

| Parameter | Value |
|-----------|-------|
| Acknowledgment Timeout | 15 seconds |
| Voice Call Provider | Twilio (Programmable Voice) |
| Max Voice Call Attempts | 2 |
| Escalation Trigger | Severity = HIGH or CRITICAL |

**Implementation Notes:**
- Voice calls are initiated via **Twilio Programmable Voice** API
- The automated voice message uses text-to-speech (TWIML) for immediate response
- Responder can press keypad (DTMF) to accept or decline
- If voice call fails or is declined, escalation continues to dispatcher dashboard

### Technology Stack
- **Runtime**: Node.js with Express
- **Queue**: RabbitMQ consumer
- **Providers**: Firebase, Twilio

### Emergency Broadcast Mode

Large-scale disasters (gas leaks, floods, earthquakes) require mass notifications to all users within an affected area:

```
Admin triggers broadcast
        │
        ▼
┌─────────────────────────┐
│  Broadcast Service      │
│  • Define geofence      │
│  • Query affected users │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Kafka: broadcast.events │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Notification Workers   │
│  (Scalable pool)        │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Push to all users      │
│  within 10km radius     │
└─────────────────────────┘
```

| Feature | Configuration |
|---------|---------------|
| Geofencing | Radius: 1-50km (configurable) |
| Channel Priority | Push → SMS → Voice |
| Rate Limiting | 10,000 notifications/minute |
| Batch Size | 500 per batch |

**Use Cases:**
- Gas leak evacuation alerts
- Flood warning notifications
- Earthquake emergency broadcasts
- Area-wide safety announcements

---

## 8️⃣ User Service

**Purpose**: Manages authentication, authorization, and user profiles.

### Responsibilities
- User registration and login
- JWT token management
- Role-based access control
- Profile management
- Device registration for push notifications

### User Roles
| Role | Permissions |
|------|-------------|
| CITIZEN | Report emergency, view own incidents |
| RESPONDER | Accept dispatches, update status |
| DISPATCHER | View all incidents, assign responders |
| ADMIN | Full system access |

### Technology Stack
- **Runtime**: Node.js with Express
- **Auth**: JWT + bcrypt
- **Database**: PostgreSQL

---

## 9️⃣ Analytics Service

**Purpose**: Provides insights, reporting, and real-time dashboards.

### Responsibilities
- Aggregate incident data
- Calculate response time metrics
- Generate reports
- Power dashboards
- Anomaly detection

### Metrics Tracked
| Metric | Description |
|--------|-------------|
| Average Response Time | Time from incident to responder arrival |
| Dispatch Success Rate | % of successful first-attempt dispatches |
| Responder Utilization | % of time responders are busy |
| Incident Volume | Incidents per hour/day/week |
| Peak Hours | Busiest times for emergencies |

### Technology Stack
- **Runtime**: Python (for data processing)
- **Database**: PostgreSQL + MongoDB (for logs)
- **Visualization**: Custom React charts

---

## 🔄 Service Communication

### Event-Driven Architecture (Kafka/EventBridge)
```
                    ┌─────────────────┐
                    │    EVENT BUS     │
                    │ (Kafka/EventBridge)│
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   Incident    │    │    Dispatch   │    │  Analytics    │
│   Service     │    │    Engine     │    │   Service     │
│  (Producer)   │    │  (Consumer)   │    │  (Consumer)   │
└───────────────┘    └───────────────┘    └───────────────┘
        │                    │                    │
        │                    ▼                    │
        │            ┌───────────────┐            │
        │            │ Notification  │            │
        │            │   Service     │            │
        │            └───────────────┘            │
        │                    │                    │
        ▼                    ▼                    ▼
                 Tracking Service
                 (WebSocket + Push)
```

### Event Types
| Event | Topic | Producer | Consumers |
|-------|-------|----------|----------|
| Incident Created | `incident.created` | Incident Service | Dispatch Engine, Analytics |
| Dispatch Assigned | `dispatch.assigned` | Dispatch Engine | Notification, Tracking |
| Location Updated | `location.updated` | Location Service | Tracking, Analytics |
| Status Changed | `incident.status` | Incident Service | Analytics, Tracking |

### Dead Letter Queue (DLQ)

Failed events must not disappear. We implement a Dead Letter Queue for failed message processing:

```
Event Processing
       │
       ▼
┌──────────────┐
│ Process Event│
└──────┬───────┘
       │
       ▼
   ┌────┴────┐
   │Success? │
   └────┬────┘
    Yes    No
     │      │
     │      ▼
     │ ┌─────────────────┐
     │ │ Retry (3 times) │
     │ │ with backoff    │
     │ └────────┬────────┘
     │          │
     │          ▼
     │    ┌─────┴─────┐
     │    │ All fail? │
     │    └─────┬─────┘
     │     Yes   No
     │      │     │
      │     │     ▼
      │     │  Continue
      ▼     ▼
┌─────────────┐
│  Send to DLQ │
│  (Kafka DLQ) │
└──────┬───────┘
       │
       ▼
┌─────────────────────────┐
│ • Log for debugging     │
│ • Alert on DLQ size    │
│ • Manual inspection UI  │
│ • Replay capability    │
└─────────────────────────┘
```

| DLQ Topic | Purpose | Retention |
|-----------|---------|-----------|
| `dlq.incidents` | Failed incident events | 7 days |
| `dlq.dispatch` | Failed dispatch events | 7 days |
| `dlq.notifications` | Failed notification events | 3 days |

### Idempotency Protection

Emergency reporting can be accidentally duplicated. We implement idempotency keys to prevent duplicates:

```http
POST /api/v1/incidents
Idempotency-Key: abc123-unique-token
Content-Type: application/json

{
  "type": "MEDICAL",
  "location": {...},
  "description": "Chest pain"
}
```

Server checks:
```
If Idempotency-Key exists in last 24 hours
  → Return previous response (don't create duplicate)
Else
  → Process request, store key
```

| Endpoint | Idempotency TTL | Use Case |
|----------|-----------------|----------|
| POST /incidents | 24 hours | Prevent duplicate reports |
| POST /dispatch | 1 hour | Prevent duplicate assignments |
| POST /notifications | 1 hour | Retry safety |

### Synchronous (REST)
- API Gateway → Services
- User Service → Auth validation

---

## 🔌 API Gateway Responsibilities

The API Gateway serves as the single entry point and handles:

1. **Load Balancing** - Distribute to healthy instances
2. **Authentication** - Validate JWT tokens
3. **Rate Limiting** - Prevent abuse (1000 req/min default)
4. **IP Filtering** - Block malicious IPs
5. **CAPTCHA** - Prevent spam attacks
6. **Routing** - Forward to appropriate services
7. **Circuit Breaker** - Fault tolerance

---

## 📈 SRE Monitoring Metrics & Alerts

We track specific SRE (Site Reliability Engineering) metrics for production reliability:

### Key Metrics

| Metric | Description | Target | Alert Threshold |
|--------|-------------|--------|-----------------|
| `dispatch_latency` | Time to assign responder | < 5 seconds | > 10 seconds |
| `incident_creation_rate` | Incidents created per minute | Varies | Spike > 3x normal |
| `responder_accept_rate` | % responders accepting | > 90% | < 70% |
| `system_error_rate` | Failed API calls | < 0.1% | > 1% |
| `websocket_connections` | Active connections | < 50,000 | > 45,000 |
| `location_update_latency` | Time to process location | < 100ms | > 500ms |
| `notification_delivery_rate` | Successful notifications | > 99% | < 95% |

### Alert Rules

```yaml
groups:
  - name: emergency dispatch
    rules:
      - alert: HighDispatchLatency
        expr: dispatch_latency_seconds > 10
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Dispatch latency exceeded 10 seconds"

      - alert: LowResponderAcceptance
        expr: responder_accept_rate < 0.70
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Responder acceptance rate below 70%"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.01
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "System error rate above 1%"

      - alert: DispatchQueueBacklog
        expr: dispatch_queue_size > 100
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Dispatch queue backlog detected"
```

### Dashboard Panels

| Panel | Visualization | Data Source |
|-------|---------------|-------------|
| Dispatch Latency (P50, P95, P99) | Line chart | Prometheus |
| Active Incidents | Stat | PostgreSQL |
| Responder Status Distribution | Pie chart | Redis |
| System Health | Gauge | Health checks |
| Error Rate by Service | Heatmap | Prometheus |

---

## 📊 Summary of Key Improvements

| Feature | Before | After |
|---------|--------|-------|
| Load Balancer | ❌ Missing | ✅ Added (AWS ALB/NGINX) |
| Tracking Service | Combined with Location | ✅ Separate Service |
| Event Bus | RabbitMQ only | ✅ Kafka/EventBridge added |
| Dispatch Radius | Fixed | ✅ Expands (5→10→20 km) |
| Acceptance Timeout | None | ✅ 10-second timeout |
| Manual Override | None | ✅ Dispatcher dashboard control |
| Responder Silence | Not handled | ✅ Escalation to dashboard |
| Location Scaling | Direct writes | ✅ Kafka ingestion pipeline |
| Failed Events | Lost | ✅ Dead Letter Queue (DLQ) |
| Duplicate Prevention | None | ✅ Idempotency keys |
| Rate Limiting | Flat 1000/min | ✅ Per-role limits |
| Health Checks | None | ✅ /health + /ready endpoints |
| Circuit Breaker | API Gateway only | ✅ Service-to-service |
| Monitoring | Basic | ✅ SRE metrics + alerts |
| Data Retention | None | ✅ Policy documented |
| Privacy | Basic | ✅ PII protection + encryption |

---

*Next: Database Schema Design →*
