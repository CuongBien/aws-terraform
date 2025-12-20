# Infrastructure Modules

## Module Structure

```
modules/
├── core/              # Core infrastructure
│   ├── networking/    # VPC, subnets, routing
│   ├── security/      # Security groups, NACLs
│   └── monitoring/    # CloudWatch, alarms
│
├── compute/           # Application layer
│   ├── web-tier/      # Web servers (Blue/Green)
│   ├── app-tier/      # App servers (Blue/Green)
│   └── bastion/       # Bastion host
│
├── data/              # Data layer
│   ├── rds/           # Database
│   └── s3/            # Object storage
│
└── edge/              # Edge services
    ├── alb/           # Load balancer
    └── route53/       # DNS
```

## Module Guidelines

### Naming Convention
- Use lowercase with hyphens: `web-tier`, `app-tier`
- Prefix with layer: `core/`, `compute/`, `data/`, `edge/`

### Required Files
Each module must have:
- `main.tf` - Resource definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `README.md` - Documentation (optional)

### Blue/Green Support
Modules supporting Blue/Green deployment:
- `compute/web-tier`
- `compute/app-tier`
- `edge/alb`

### Dependencies
```
networking → security → compute → edge
                     ↘ data ↗
```

## Usage Example

```hcl
module "networking" {
  source = "./modules/core/networking"
  
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  # ...
}

module "web_tier" {
  source = "./modules/compute/web-tier"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_web_subnet_ids
  # ...
}
```

## Migration Status

- [x] Phase 1: Module structure created
- [ ] Phase 2: Code migration in progress
- [ ] Phase 3: Root configuration
- [ ] Phase 4: Testing
- [ ] Phase 5: Documentation
