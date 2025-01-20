locals {
  ingestion_schedule = {
    spacetrack    = "15 3/4 * * ? *"  //start at 3am UTC then repeat every 4h
    esadiscos     = "0 6/12 * * ? *" //start at 2am UTC, repeat every 12h
    notifications = "0 8-17 * * ? *" //every 1h between 8-17
  }
}