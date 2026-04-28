# sinhvien-app Documentation Index

**Type:** monorepo with 2 parts  
**Primary Language:** Dart, TypeScript  
**Architecture:** Flutter feature-first + Riverpod + Cloudflare Worker REST API  
**Last Updated:** 2026-04-28T01:39:41+07:00

## Project Overview

`sinhvien-app` la repo ung dung sinh vien theo huong local-first. App Flutter o root quan ly cache cuc bo, dong bo du lieu truong, ghi chu, attachment va UI chinh; Worker o `cloudflare-worker/` luu note, task, snapshot va file dinh kem qua Firebase-authenticated REST API.

## Project Structure

This project consists of 2 parts:

### mobile-app

- **Type:** mobile
- **Location:** `.`
- **Tech Stack:** Flutter, Dart, Firebase Auth, Riverpod, SharedPreferences, local notifications
- **Entry Point:** `lib/main.dart`

### worker-api

- **Type:** backend
- **Location:** `cloudflare-worker/`
- **Tech Stack:** Cloudflare Worker, TypeScript, D1, KV, R2, jose
- **Entry Point:** `cloudflare-worker/src/index.ts`

## Cross-Part Integration

- `mobile-app` goi truc tiep API truong de lay du lieu hoc vu.
- `mobile-app` goi `worker-api` bang Firebase ID token de luu du lieu ca nhan va snapshot.
- `worker-api` dung D1 cho metadata, KV cho snapshot, R2 cho file dinh kem.

## Quick Reference

### mobile-app Quick Ref

- **Stack:** Flutter + Riverpod + Firebase Auth + SharedPreferences
- **Entry:** `lib/main.dart`
- **Pattern:** feature-first layered architecture

### worker-api Quick Ref

- **Stack:** Cloudflare Worker + D1 + KV + R2
- **Entry:** `cloudflare-worker/src/index.ts`
- **Pattern:** single-file REST worker voi JWT verification

## Generated Documentation

### Core Documentation

- [Project Standardization Mindmap](./project-standardization-mindmap.md) - Mindmap chuan hoa cau truc, sync flow, test va standards
- [Project Overview](./project-overview.md) - Executive summary va phan loai repo
- [Source Tree Analysis](./source-tree-analysis.md) - Cay thu muc co chu giai
- [Feature-First Target Tree](./feature-first-target-tree.md) - Cay muc tieu va trang thai migration hien tai

### Part-Specific Documentation

#### mobile-app

- [Architecture](./architecture-mobile-app.md) - Kien truc app Flutter
- [Components](./component-inventory-mobile-app.md) - Inventory man hinh va widget chinh
- [Development Guide](./development-guide-mobile-app.md) - Setup, run, test app Flutter
- [API Contracts](./api-contracts-mobile-app.md) - Cac API ma app tieu thu
- [Data Models](./data-models-mobile-app.md) - Model du lieu va local cache

#### worker-api

- [Architecture](./architecture-worker-api.md) - Kien truc backend Worker
- [Development Guide](./development-guide-worker-api.md) - Setup, dev, deploy Worker
- [API Contracts](./api-contracts-worker-api.md) - REST endpoints cua Worker
- [Data Models](./data-models-worker-api.md) - D1/KV/R2 data model

### Integration

- [Integration Architecture](./integration-architecture.md) - Cach cac part va he ngoai giao tiep

### Optional Documentation

- [Deployment Guide](./deployment-guide.md) - Quy trinh cau hinh va deploy hien tai

## Existing Documentation

- [README goc](../README.md) - Gioi thieu san pham va cach chay nhanh
- [Cloudflare Worker README](../cloudflare-worker/README.md) - Ghi chu tham khao cho Worker

## Getting Started

### mobile-app Setup

**Prerequisites:** Flutter SDK, Android Studio hoac VS Code

**Install & Run:**

```bash
flutter pub get
flutter run
```

### worker-api Setup

**Prerequisites:** Node.js, npm, Cloudflare resources neu muon chay that

**Install & Run:**

```bash
cd cloudflare-worker
npm install
npm run dev
```

## For AI-Assisted Development

This documentation was generated specifically to enable AI agents to understand and extend this codebase.

### When Planning New Features

**UI-only features:**  
→ Reference: `architecture-mobile-app.md`, `component-inventory-mobile-app.md`

**API/Backend features:**  
→ Reference: `architecture-worker-api.md`, `api-contracts-worker-api.md`, `data-models-worker-api.md`

**Full-stack features:**  
→ Reference: tat ca tai lieu kien truc + `integration-architecture.md`

**Deployment changes:**  
→ Reference: `deployment-guide.md`

---

_Documentation index updated to match the current feature-first repo state._
