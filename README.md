# Cafe Shop

This repository contains a full-stack coffee shop management system for a mobile and backend assignment.

## Technology and versions

### Mobile application

- Flutter: stable channel
- Dart SDK: `^3.12.0`
- Application version: `1.0.0+1`

Flutter packages declared in `frontend/pubspec.yaml`:

| Package | Version |
|---|---|
| `cupertino_icons` | `^1.0.8` |
| `device_preview` | `^1.3.1` |
| `flutter_lints` (development) | `^6.0.0` |

`flutter` and `flutter_test` are provided by the Flutter SDK.

### API backend

- PHP: `^8.3`
- Laravel Framework: `^13.17`
- Laravel Tinker: `^3.0`
- Database: MySQL 8.0+ or another database supported by Laravel

Composer packages declared in `laravel_api/composer.json`:

| Package | Version |
|---|---|
| `laravel/framework` | `^13.17` |
| `laravel/tinker` | `^3.0` |
| `fakerphp/faker` (development) | `^1.23` |
| `laravel/boost` (development) | `^2.10` |
| `laravel/pail` (development) | `^1.2.5` |
| `laravel/pao` (development) | `^1.0.6` |
| `laravel/pint` (development) | `^1.27` |
| `mockery/mockery` (development) | `^1.6` |
| `nunomaduro/collision` (development) | `^8.6` |
| `phpunit/phpunit` (development) | `^12.5.12` |

## Project structure

- `frontend/` - Flutter mobile application for staff and cashier workflows
- `laravel_api/` - Laravel API backend for authentication, catalog, inventory, orders, payments, and reports
- `COFFEE_SHOP_ARCHITECTURE.md` - backend and database architecture specification
- `FLUTTER_ARCHITECTURE.md` - Flutter app architecture specification

## Overview

The system is designed around a coffee shop management workflow with:

- user authentication and role-based access
- product and category management
- inventory tracking and low-stock monitoring
- table and customer management
- order creation and payment processing
- employee and shift management
- sales reporting

## Backend setup

From the repository root:

```bash
cd laravel_api
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

The Laravel API exposes the restaurant management endpoints used by the mobile app.

## Frontend setup

From the repository root:

```bash
cd frontend
flutter pub get
flutter run
```

The Flutter app connects to the Laravel backend and provides the coffee shop interface for staff users.

## Notes

- Backend uses Laravel and MySQL-friendly conventions.
- Frontend uses Flutter and follows a small feature-based architecture.
- Project requirements and app structure are documented in the architecture files in the repository root.

## Main documentation

- [COFFEE_SHOP_ARCHITECTURE.md](./COFFEE_SHOP_ARCHITECTURE.md)
- [FLUTTER_ARCHITECTURE.md](./FLUTTER_ARCHITECTURE.md)
