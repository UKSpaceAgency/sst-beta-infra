#locals {
#  ingestion_schedule = {
#    spacetrack    = "0 3/4 * * ? *"  //start at 3am UTC then repeat every 4h
#    esadiscos     = "0 2/12 * * ? *"  //start at 2am UTC, repeat every 12h
#    notifications = "0 8-17 * * ? *" //every 1h between 8-17
#  }
#}

locals {
  ingestion_schedule = {
    spacetrack    = "0 0 1 1 ? *"  //start at 3am UTC then repeat every 4h
    esadiscos     = "0 0 1 1 ? *"  //start at 2am UTC, repeat every 12h
    notifications = "0 0 1 1 ? *" //every 1h between 8-17
  }
}