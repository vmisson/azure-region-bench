locals {
  regionSizeMappings = jsondecode(file("regionSizeMappings.json"))
  locationList = {
    for location in local.regionSizeMappings : location.name => location.size
  }
}