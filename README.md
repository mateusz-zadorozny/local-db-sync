# GridPane to LocalWP 0.1

Script for updating and rewriting the LocalWP database

## Installation

1. Download to your LocalWP WordPress folder or other destination
2. Copy the run_script_default and rename it to run_script_local - this way it will be automatically ignored by git
3. At define settings - use your domain names, ip, key name, etc.

## Usage

1. Open the LocalWP site shell (important!)
2. cd local-db-sync (or the path where you downloaded the script)
3. bash run_script_local.sh
4. Go with the and answer questions if needed
5. Remove backup.sql only manually for safety reasons (rm backup.sql)

