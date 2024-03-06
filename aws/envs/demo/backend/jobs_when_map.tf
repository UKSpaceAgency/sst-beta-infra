locals {
  ingestion_schedule = {
    spacetrack    = "0 3/4 * * ? *"  //start at 3am UTC then repeat every 4h
    esadiscos     = "0 4/12 * * ? *" //start at 4am UTC, repeat every cd ..12h
    notifications = "0 8-17 * * ? *" //every 1h between 8-17
  }
}