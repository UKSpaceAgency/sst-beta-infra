locals {
  ingestion_schedule = {
    spacetrack    = "0 3/4 * * ? *"  //start at 3am UTC then repeat every 4h
    esadiscos     = "0 2/8 * * ? *"  //start at 2am UTC, repeat every 8h
    notifications = "*/10 * * * ? *" //every 10min
  }
}