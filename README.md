# Secret Santa

Сайт «Тайный Санта» с вишлистами и чатом (Ruby on Rails).

## Схема базы данных

```mermaid
erDiagram
  users ||--o{ wishes : "has"
  users ||--o{ events : "organizes"
  users ||--o{ participations : "joins as santa"
  users ||--o{ participations : "is giftee in"
  events ||--o{ participations : "has"
  participations ||--o{ messages : "has"

  users {
    bigint id PK
    string email
    string encrypted_password
    string nickname
  }
  wishes {
    bigint id PK
    string title
    text description
    string url
    bigint user_id FK
  }
  events {
    bigint id PK
    string name
    text description
    integer budget
    date exchange_date
    string invite_code
    integer status
    bigint organizer_id FK
  }
  participations {
    bigint id PK
    bigint event_id FK
    bigint user_id FK
    bigint giftee_id FK
  }
  messages {
    bigint id PK
    bigint participation_id FK
    boolean from_santa
    text body
  }
```
