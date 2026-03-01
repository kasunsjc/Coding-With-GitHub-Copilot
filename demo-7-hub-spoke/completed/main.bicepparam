// ============================================================
// Demo 7: Hub & Spoke VNet - Parameter File
// Update values below before deploying
// ============================================================

using './main.bicep'

// Azure region for deployment (set to your preferred region)
param location = 'australiaeast'

// Short location code matching the region above (used in resource names)
// Examples: aue (Australia East), eus (East US), weu (West Europe)
param locationCode = 'aue'

// Environment: dev, staging, or prod
param environmentName = 'prod'

// Log retention in days (min 30, max 730)
param logRetentionDays = 30
