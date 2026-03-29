# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.1] - 2026-03-29

### Fixed
- Removed duplicate `data "aws_vpc"` resource
- Removed unused `data "aws_availability_zones"` resource
- Fixed output `ssh_command` to handle null key_name

## [1.5.0] - 2026-03-28

### Added
- Traefik v3 reverse proxy support
- Docker and Docker Compose pre-installed
- Automatic service discovery via Docker socket
- Configurable dashboard with optional basic auth
- Cloudflare SSL integration support
- Security Group with HTTP (80), HTTPS (443), SSH (22)
- Elastic IP association
- GitHub Actions CI workflow
- Example configurations

### Changed
- Updated to Ubuntu 22.04 LTS
- Improved IAM role configuration

## [1.0.0] - 2026-01-01

### Added
- Initial ALB proxy module
- Basic reverse proxy configuration
