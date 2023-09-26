locals {
  ingestion_schedule = {
    spacetrack    = "0 3/2 * * ? *"  //start at 3am UTC then repeat every 2h
    esadiscos     = "0 2/12 * * ? *"  //start at 2am UTC, repeat every 12h
    notifications = "0 8-17 * * ? *" //every 1h between 8-17
  }
}
