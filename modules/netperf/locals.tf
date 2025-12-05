locals {
  regionSizeMappings = jsondecode(file("regionSizeMappings.json"))

  locations = sort([
    for location in local.regionSizeMappings :
    location.name
  ])

  location = sort([
    for location in local.regionSizeMappings :
    location.name
  ])[ var.index % length(local.regionSizeMappings) ]


  locationSize = {
    for location in local.regionSizeMappings :
    location.name => location.size
  }
}
