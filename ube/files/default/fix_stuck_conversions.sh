#!/bin/bash

mongo shodogg <<'EOF'
var minutesBeforeError = 25;
db.asset.update({ "repoMetadata.status": {$exists : true},
                  "repoMetadata.status"  : {$in: ["QUEUED", "CONVERTING"] },
                  "createdAt" : {$lte : (new Date(new Date() - minutesBeforeError*60*1000))}
                },
                { $set : {"repoMetadata.status" : "ERROR",
                          "repoMetadata.displayMessage": "A timeout occurred trying to convert this file"
                         }
                },
                {multi: true})
EOF


