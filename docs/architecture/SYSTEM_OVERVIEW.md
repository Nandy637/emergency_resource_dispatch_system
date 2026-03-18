# Emergency Resource Dispatch System - Architecture Overview

## 📋 Project Overview

The **Emergency Resource Dispatch System** is a real-time platform designed to connect citizens in emergencies with the nearest available emergency responders (ambulance, fire truck, police). The system prioritizes **speed, reliability, and accuracy** in life-critical situations.

---

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           USER LAYER                                      │
│  ┌─────────────────┐         ┌─────────────────────────┐                │
│  │   Citizen App   │         │   Responder Mobile App  │                │
│  │  (Report Emergency)        │  (Receive & Update Status)│               │
│  └────────┬────────┘         └────────────┬────────────┘                │
└───────────┼─────────────────────────────────┼───────────────────────────┘
            │                                 │
            ▼                                 ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                      LOAD BALANCER LAYER                                  │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │               AWS ALB / NGINX / HAProxy                            │  │
│  │    • Traffic Distribution  • Health Checks  • SSL Termination    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY LAYER                                   │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                      API Gateway (Kong/AWS API Gateway)            │  │
│  │    • Rate Limiting  • Authentication  • Request Routing            │  │
│  │    • IP Filtering   • CAPTCHA Protection  • Circuit Breaker      │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                      EVENT BUS LAYER (Kafka/EventBridge)                  │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                    Event Streaming Bus                              │  │
│  │    • Decoupled Services  • Event Replay  • Scalability             │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                      MICROSERVICES LAYER                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │   Incident   │  │   Dispatch   │  │  Location    │  │   Tracking  │  │
│  │   Service    │  │   Engine     │  │   Service    │  │   Service   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │   Severity   │  │   Resource   │  │    User      │  │  Analytics  │  │
│  │   Engine     │  │   Manager    │  │   Service    │  │   Service   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘  │
│  ┌──────────────┐                                                        │
│  │ Notification │                                                        │
│  │   Service    │                                                        │
│  └──────────────┘                                                        │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                      MESSAGE QUEUE LAYER (RabbitMQ)                       │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │              Async Processing & Background Jobs                   │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │ PostgreSQL   │  │    Redis     │  │   MongoDB    │  │   RabbitMQ  │  │
│  │ (Primary DB) │  │  (Caching)   │  │ (Logs/Audit) │  │   (Queue)   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                     EXTERNAL INTEGRATIONS                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │
│  │ Google Maps   │  │    Twilio    │  │   Firebase   │                   │
│  │   API        │  │  (SMS/Voice) │  │   (Push)     │                   │
│  └──────────────┘  └──────────────┘  └──────────────┘                   │
└───────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                     MONITORING LAYER                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │
│  │  Prometheus   │  │   Grafana    │  │   ELK Stack  │                   │
│  │  (Metrics)   │  │  (Dashboards)│  │   (Logs)     │                   │
│  └──────────────┘  └──────────────┘  └──────────────┘                   │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

### Frontend
| Layer | Technology | Purpose |
|-------|------------|---------|
| Citizen App | **Flutter** | Mobile app for emergency reporting (Panic Button) |
| Responder App | **Flutter** | Mobile app for responders with background GPS |
| Dispatch Dashboard | React + TypeScript | Web dashboard for dispatchers |
| Admin Portal | Next.js | Admin management console |

### Backend
| Layer | Technology | Purpose |
|-------|------------|---------|
| Load Balancer | AWS ALB / NGINX / HAProxy | Traffic distribution |
| API Gateway | Kong / AWS API Gateway | Entry point, routing, auth |
| Event Streaming | Apache Kafka / AWS EventBridge | Event-driven communication |
| REST API | Node.js (Express) / Java Spring Boot | RESTful services |
| WebSocket | Socket.io | Real-time tracking |
| Message Queue | RabbitMQ / AWS SQS | Async processing |
| Caching | Redis | Session & data caching |

### Database
| Type | Technology | Purpose |
|------|------------|---------|
| Primary | PostgreSQL | Transactional data |
| Document | MongoDB | Logs, audit trails |
| Cache | Redis | Real-time status |
| Geospatial | PostGIS (PostgreSQL) | Location queries |

### Infrastructure
| Component | Technology |
|-----------|------------|
| Container | Docker |
| Orchestration | Kubernetes (EKS/GKE) |
| Cloud Provider | AWS / Azure / GCP |
| CDN | CloudFront |
| Monitoring | Prometheus + Grafana + ELK |

---

## 🔄 API Versioning Strategy

We use **URI Versioning** to ensure backward compatibility and prevent breaking changes for client applications.

### Versioning Policy

| Aspect | Rule |
|--------|------|
| Format | `/api/v1/...`, `/api/v2/...` |
| Support Duration | v1 supported for **12 months** |
| Breaking Changes | Require new version |
| Non-breaking Changes | Same version |

### Version Lifecycle

```
/api/v1/incidents     → Current stable version
       │
       │  (12 months)
       ↓
/api/v2/incidents     → New version (when needed)
       │
       ↓
   Deprecated
       │
       ↓
   Removed after 6 months
```

### Best Practices

- Mobile apps reference specific versions
- API responses include `X-API-Version` header
- Deprecated versions return `Warning: 299` header
- All endpoints follow consistent versioning

### Example Endpoints

| Version | Endpoint |
|---------|----------|
| v1 | `GET /api/v1/incidents/:id` |
| v1 | `POST /api/v1/incidents` |
| v2 | `GET /api/v2/incidents/:id` |
| v2 | `POST /api/v2/incidents` |

---

## 📁 Project Directory Structure

```
emergency_resource_dispatch_system/
├── 📂 docs/                          # Architecture & Design Documents
│   ├── architecture/
│   │   ├── SYSTEM_OVERVIEW.md
│   │   ├── COMPONENT_DESIGN.md
│   │   ├── DATABASE_SCHEMA.md
│   │   ├── API_DESIGN.md
│   │   ├── DISPATCH_ALGORITHM.md
│   │   └── DEPLOYMENT.md
│   └── diagrams/
│       ├── architecture.drawio
│       ├── sequence-diagrams.drawio
│       └── database-models.drawio
│
├── 📂 src/                           # Source Code
│   ├── 📂 citizen-app/              # Citizen Mobile App
│   │   ├── src/
│   │   │   ├── screens/
│   │   │   ├── components/
│   │   │   ├── services/
│   │   │   └── store/
│   │   └── tests/
│   │
│   ├── 📂 responder-app/            # Responder Mobile App
│   │   ├── src/
│   │   ├── android/
│   │   ├── ios/
│   │   └── tests/
│   │
│   ├── 📂 backend/                  # Backend Services
│   │   ├── 📂 api-gateway/          # API Gateway Service
│   │   ├── 📂 incident-service/     # Incident Management
│   │   ├── 📂 dispatch-engine/      # Dispatch Algorithm
│   │   ├── 📂 location-service/     # GPS & Tracking
│   │   ├── 📂 notification-service/ # Push & SMS
│   │   ├── 📂 severity-engine/      # Priority Calculation
│   │   ├── 📂 resource-manager/     # Responder Management
│   │   └── 📂 user-service/          # Authentication
│   │
│   └── 📂 web-dashboard/            # Dispatcher Dashboard
│       ├── src/
│       └── public/
│
├── 📂 infrastructure/               # Infrastructure as Code
│   ├── 📂 kubernetes/              # K8s manifests
│   ├── 📂 terraform/               # Terraform configs
│   └── 📂 docker/                  # Dockerfiles
│
├── 📂 tests/                        # Testing Suites
│   ├── 📂 unit-tests/
│   ├── 📂 integration-tests/
│   ├── 📂 e2e-tests/
│   └── 📂 load-tests/
│
└── README.md
```

---

## 🔄 Data Flow

### Emergency Reporting Flow
```
1. Citizen opens app
2. App captures GPS location (automatic)
3. Citizen selects emergency type
4. Citizen submits report
5. → Incident Service creates incident record
6. → Severity Engine calculates priority
7. → Dispatch Engine finds best responder
8. → Notification Service alerts responder
9. → Responder accepts/declines
10. → Live tracking begins
11. → Status updates (Assigned → En Route → On Scene → Closed)
```

---

## 🎯 Key Non-Functional Requirements

| Requirement | Target |
|-------------|--------|
| Response Time | < 2 seconds |
| Availability | 99.99% (24/7) |
| Concurrent Users | 100,000+ |
| Location Accuracy | < 10 meters |
| Max Dispatch Time | < 30 seconds |
| Data Encryption | AES-256 |
| SLA | 99.9% uptime |

---

## 📡 Connectivity (Offline Strategy)

Emergency responders often operate in areas with limited or no connectivity - elevators, basements, rural areas, or buildings with poor cellular reception. The system must handle these "Dead Zones" gracefully.

### MQTT as Primary Real-Time Protocol

We recommend **MQTT (Message Queuing Telemetry Transport)** via **AWS IoT Core** or **EMQX** as an alternative or supplement to WebSockets for mobile device communications. MQTT is often more resilient than Socket.io for mobile devices that frequently switch between 4G, 5G, and Wi-Fi networks.

| Feature | MQTT | Socket.io |
|---------|------|----------|
| Connection Overhead | Very Low (2 bytes) | Higher |
| Battery Efficiency | Excellent | Good |
| Network切换 Tolerance | Automatic reconnection | Manual handling |
| Message QoS | 3 levels | 1 level |
| Pub/Sub Model | Native | Custom implementation |
| Mobile Optimization | Purpose-built | General purpose |

### QoS Levels for Critical Communications

| Level | Use Case | Guarantees |
|-------|----------|------------|
| QoS 0 (At most once) | Location updates | Fire and forget |
| QoS 1 (At least once) | Status acknowledgments | Duplicates possible |
| QoS 2 (Exactly once) | Critical dispatch commands | Guaranteed delivery |

### Offline Queue Strategy

```
Mobile App loses connectivity
         │
         ▼
┌─────────────────────────┐
│  Local Offline Queue    │
│  • Store pending events │
│  • Store location data  │
└────────────┬────────────┘
             │
             ▼
   Connectivity restored
             │
             ▼
┌─────────────────────────┐
│  Sync with Server       │
│  • Batch upload events  │
│  • Priority-based order│
│  • Deduplication       │
└─────────────────────────┘
```

### Hybrid Approach

The system uses a hybrid communication strategy:
- **MQTT over AWS IoT Core/EMQX**: Primary channel for responder mobile apps
- **WebSocket (Socket.io)**: Secondary channel for web dashboards and real-time tracking
- **REST API**: For request-response operations
- **Local Storage**: Offline queue in mobile apps for sync when connectivity returns

---

## 🔐 Security Architecture

```
┌─────────────────────────────────────────┐
│         SECURITY LAYER                   │
├─────────────────────────────────────────┤
│ • OAuth 2.0 / JWT Authentication         │
│ • API Key Management                     │
│ • Role-Based Access Control (RBAC)      │
│ • End-to-End Encryption (TLS 1.3)       │
│ • Data Encryption at Rest               │
│ • Input Validation & Sanitization       │
│ • Rate Limiting & DDoS Protection        │
│ • CAPTCHA for Repeated Requests          │
│ • Audit Logging                         │
└─────────────────────────────────────────┘
```

### Rate Limiting By Role

Different user roles have different rate limits to prevent abuse while allowing legitimate high-volume access:

| Role | Rate Limit | Use Case |
|------|------------|----------|
| Citizen | 10 requests/min | Emergency reporting |
| Responder | 100 requests/min | Status updates, location |
| Dispatcher | 500 requests/min | Dashboard operations |
| Admin | Unlimited | System management |
| Public API | 50 requests/min | Third-party integrations |

### Rate Limit Headers

All rate-limited responses include headers:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
Retry-After: 60
```

### Idempotency Protection

To prevent duplicate emergency reports, all POST endpoints support idempotency keys:

```http
POST /api/v1/incidents
Idempotency-Key: abc123-unique-token
Content-Type: application/json
```

If the same key is used within 24 hours, the server returns the previous response instead of creating a duplicate.

---

## 🏥 Health Check Endpoints

Microservices expose health check endpoints for Kubernetes and load balancer monitoring:

| Endpoint | Purpose | Used By |
|----------|---------|----------|
| `GET /health` | Service is running | Kubernetes liveness probe |
| `GET /ready` | Service ready to receive traffic | Kubernetes readiness probe |
| `GET /health/dependencies` | External service connectivity | Deep health checks |

### Health Check Response

```json
{
  "status": "healthy",
  "timestamp": "2026-03-13T10:00:00Z",
  "dependencies": {
    "database": "up",
    "redis": "up",
    "kafka": "up"
  },
  "version": "1.0.0"
}
```

---

## 📊 Data Retention Policy

Emergency systems generate significant data. We implement strict retention policies:

| Data Type | Retention | Justification |
|-----------|-----------|----------------|
| Incidents | 5 years | Legal compliance, investigations |
| Location History | 30 days | Privacy vs. analytics balance |
| System Logs | 90 days | Debugging, security audit |
| Analytics Aggregates | Forever | Trend analysis, reporting |
| Audit Logs | 7 years | Regulatory compliance |
| Push Notification Logs | 90 days | Delivery verification |

### Data Archival

- Data older than retention period is archived to cold storage
- Archived data can be retrieved within 48 hours for legal requests
- Automatic purging runs weekly

---

## 🔒 Privacy Protection (PII)

Since this system handles sensitive citizen data, we implement comprehensive privacy controls:

### Encryption

| Layer | Method |
|-------|--------|
| In Transit | TLS 1.3 |
| At Rest | AES-256 |
| Database Fields | Column-level encryption for PII |

### PII Protection Measures

| Data | Protection |
|------|------------|
| Phone Numbers | Encrypted at rest, masked in UI |
| Citizen Identity | Pseudonymized in analytics |
| Location History | Access restricted by role |
| Medical Details | HIPAA-compliant encryption |

### Access Control

- All PII access is logged
- Role-based access restricts sensitive data
- Time-limited access tokens for location data
- Automatic session expiry

---

## 🔄 Resilience Patterns

### Circuit Breaker Pattern

The circuit breaker pattern prevents cascading failures between services:

```
Service A                    Service B
    │                           │
    │  ───── Request ─────────►│
    │                           │
    │  ◄─── Success ────────── │
    │                           │
    │  ───── Request ─────────►│
    │                           │
    │  ◄─── Failure ────────── │
    │                           │
    │  ───── Request ─────────►│
    │                           │
    │  ◄─ Circuit Open ─────── │ (rejecting requests)
    │                           │
    │  ◄─── Fallback ───────── │ (use cached data)
```

| Pattern | Implementation | Purpose |
|---------|----------------|--------|
| Circuit Breaker | Resilience4j (Java) / Polka (Node) | Prevent cascading failures |
| Retry Policy | Exponential backoff | Handle transient failures |
| Fallback Cache | Redis | Use cached data if service unavailable |
| Bulkhead | Thread pool isolation | Prevent resource exhaustion |

### Service-Level Circuit Breakers

| Service Pair | Fallback Behavior |
|--------------|-------------------|
| Dispatch → Location | Use cached responder locations |
| Incident → User | Return cached user profile |
| Notification → SMS | Queue for retry, use push fallback |
| Tracking → Analytics | Buffer events, batch process |

---

## 🌐 Disaster Recovery & Multi-Region Deployment

Emergency systems **cannot fail**. The system deploys across multiple regions for high availability.

### Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                     GLOBAL LOAD BALANCER                         │
│                  (Route 53 / CloudFlare)                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌─────────────────────┐     ┌─────────────────────┐
│   PRIMARY REGION    │     │   BACKUP REGION     │
│    (India-Mumbai)    │     │   (Singapore)       │
│                     │     │                     │
│  ┌───────────────┐  │     │  ┌───────────────┐  │
│  │ K8s Cluster   │  │     │  │ K8s Cluster   │  │
│  │ (EKS)         │  │     │  │ (EKS)         │  │
│  └───────────────┘  │     │  └───────────────┘  │
│                     │     │                     │
│  ┌───────────────┐  │     │  ┌───────────────┐  │
│  │ PostgreSQL    │  │     │  │ PostgreSQL    │  │
│  │ (Primary)    │◄─┼─────┼─►│ (Replica)     │  │
│  └───────────────┘  │     │  └───────────────┘  │
│                     │     │                     │
└─────────────────────┘     └─────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│         DATA REPLICATION                 │
│   • Async replication (RPO < 1 min)    │
│   • Cross-region backup (S3)           │
└─────────────────────────────────────────┘
```

### Failover Strategy
| Scenario | Action |
|----------|--------|
| Primary Region Down | DNS自动切换到 Backup Region |
| Database Failure | 自动故障转移到 Replica |
| Service Crash | K8s 自动重启 + Load Balancer 健康检查 |
| Network Issue | 流量自动路由到健康节点 |

### RTO/RPO Targets
| Metric | Target | Description |
|--------|--------|-------------|
| RTO | < 5 minutes | Recovery Time Objective |
| RPO | < 1 minute | Recovery Point Objective |

---

## 🆔 Global Incident ID Generation Strategy

High-scale distributed systems require unique IDs that work across regions without database bottlenecks. We use **UUIDv7** (time-sortable UUIDs):

```
incident_id = UUIDv7

Example: 0191a2b3-c4d5-6789-abcd-ef0123456789
```

| Property | Value |
|----------|-------|
| Format | UUIDv7 (time-sortable) |
| Length | 36 characters |
| Uniqueness | 122-bit randomness |
| Generation | Client-side (no DB call) |

### Benefits

| Benefit | Description |
|---------|-------------|
| Sortable by time | Queries can sort by creation time |
| Unique across regions | No collision between data centers |
| No database bottleneck | Generated client-side |
| Distributed-ready | Works without coordination |

### Alternatives Considered

| Method | Pros | Cons |
|--------|------|------|
| UUIDv7 | Time-sortable, client-side | Longer than numeric IDs |
| Snowflake IDs | Compact, time-ordered | Requires ID generation service |
| KSUID | Time-ordered, readable | Less common |

---

## 🔄 Multi-Region Data Replication

Emergency systems cannot have single points of failure. We implement active-active multi-region database replication:

### Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Global Load Balancer                     │
│                  (Route 53 / CloudFlare)                   │
└────────────────────────┬───────────────────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          │                             │
          ▼                             ▼
┌─────────────────────┐       ┌─────────────────────┐
│   PRIMARY REGION    │       │   SECONDARY REGION  │
│    (Mumbai)         │       │    (Singapore)       │
│                     │       │                     │
│  ┌───────────────┐  │       │  ┌───────────────┐  │
│  │ PostgreSQL    │  │◄─────►│  │ PostgreSQL    │  │
│  │ Primary       │  │       │  │ Read Replica  │  │
│  └───────────────┘  │       │  └───────────────┘  │
│         │          │       │         │            │
│         ▼          │       │         ▼            │
│  ┌───────────────┐  │       │  ┌───────────────┐  │
│  │ Redis Cluster │  │       │  │ Redis Cluster │  │
│  └───────────────┘  │       │  └───────────────┘  │
└─────────────────────┘       └─────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│                  Data Replication                        │
│   • Async replication (RPO < 1 minute)                  │
│   • Cross-region backup (S3)                           │
│   • Conflict resolution (last-write-wins)              │
└─────────────────────────────────────────────────────────┘
```

### Replication Strategy

| Aspect | Configuration |
|--------|---------------|
| Replication Type | Logical replication (PostgreSQL) |
| RPO (Recovery Point Objective) | < 1 minute |
| RTO (Recovery Time Objective) | < 5 minutes |
| Failover | Automatic with health checks |

### Conflict Resolution Strategy

In active-active multi-region deployments, conflict resolution is critical when both Mumbai and Singapore regions update the same data simultaneously.

#### Approach: Global Tables with Last-Write-Wins (LWW)

We use **AWS Aurora Global Database** or **DynamoDB Global Tables** for conflict resolution:

| Aspect | Implementation |
|--------|---------------|
| Conflict Detection | Timestamp-based vector clocks |
| Resolution Strategy | Last-Write-Wins (LWW) with deterministic tie-breaking |
| Incident IDs | UUIDv7 (time-sortable, practically collision-free) |
| Responder Status | Regional primary with async replication |

```
Region A updates responder status
         │
         ▼
Both regions receive update
         │
         ▼
Compare timestamps (UTC-synchronized)
         │
         ▼
┌─────────────────────────┐
│ Latest timestamp wins  │
│ (with NTP sync)        │
└─────────────────────────┘
```

#### Alternative: CRDTs for Specific Data Types

For certain data types requiring stronger consistency guarantees, we can implement **CRDTs (Conflict-free Replicated Data Types)**:

| Data Type | CRDT Approach |
|-----------|----------------|
| Responder Availability | G-Counter (increment-only) |
| Incident Counters | PN-Counter (positive/negative) |
| Status Flags | LWW-Register |

#### Current Decision

For this implementation, we use **AWS Aurora Global Database** with Last-Write-Wins (LWW) because:
- UUIDv7 makes incident ID conflicts virtually impossible
- Responder status conflicts are rare and resolve naturally with LWW
- Aurora Global provides automatic conflict detection and resolution
- Simpler operational overhead compared to implementing custom CRDTs

### Failover Process

```
Primary Region fails
        │
        ▼
DNS自动切换到 Secondary Region
        │
        ▼
Secondary Region promotes to Primary
        │
        ▼
Application reconnects
        │
        ▼
Service continues (with brief interruption)
```

### Tools

| Tool | Purpose |
|------|---------|
| AWS Aurora Global Database | Managed cross-region replication |
| pglogical | PostgreSQL logical replication |
| RDS Multi-AZ | Automatic failover |

---

## 📊 SLA Monitoring & Metrics

Track critical system metrics for emergency response quality.

### Key Metrics
| Metric | Target | Description |
|--------|--------|-------------|
| Dispatch Time | < 30 seconds | Time from incident to responder assigned |
| Response Time | < 2 seconds | API response time |
| Arrival Time | < 15 minutes | Time from dispatch to on-scene arrival |
| System Uptime | 99.99% | Overall availability |
| Dispatch Success | > 95% | First-attempt successful dispatch |

### Monitoring Dashboard
```
┌─────────────────────────────────────────────────────────┐
│              GRAFANA DASHBOARD                           │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Current   │  │   Average   │  │   Active    │    │
│  │  Incidents  │  │  Dispatch   │  │  Responders  │    │
│  │     12      │  │    18s      │  │     45       │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  Response Time (last 24h)  [████████░░] 1.8s           │
│  System Health  [██████████] 99.99%                    │
└─────────────────────────────────────────────────────────┘
```

---

## ⚠️ Error Handling

Handling failures gracefully in a life-critical system.

| Scenario | Handling Strategy |
|----------|------------------|
| No responder available | Expand search radius (5km→10km→20km), queue for next available |
| Responder declines | Auto-assign to next best responder (10s timeout) |
| Network failure | Offline queue with sync when reconnected |
| GPS failure | Manual address entry fallback |
| Database outage | Read from replica, queue writes |
| API timeout | Retry with exponential backoff (3 attempts) |

### Dispatch Timeout Flow
```
Send request to responder
        ↓
    Wait 10 seconds
        ↓
   ┌────┴────┐
   │ Responds? │
   └────┬────┘
    Yes    No
     │      ↓
     │  Try next responder
     ↓      ↓
Update status  Send to queue
```

---

## 📊 Next Steps

1. **Component Design** - Detailed design of each microservice
2. **Database Schema** - Table designs with relationships
3. **API Design** - RESTful endpoints and WebSocket events
4. **Dispatch Algorithm** - Matching logic implementation
5. **Deployment Architecture** - Cloud infrastructure setup

---

*Last Updated: 2026-03-13*
*Version: 1.0*
