#!/bin/bash
JENKINS_URL="http://***"
JOB_NAME="terraform-autoscale"
API_TOKEN="******"
JENKINS_USER="="******""
 
if [[ "$AMX_STATUS" == "firing" ]]; then
        curl  -X POST $JENKINS_URL/job/$JOB_NAME/buildWithParameters?NODE_STATUS=fire   --user $JENKINS_USER:$API_TOKEN
fi
if [[ "$AMX_STATUS" == "resolved" ]]; then
        curl  -X POST $JENKINS_URL/job/$JOB_NAME/buildWithParameters?NODE_STATUS=resolve  --user $JENKINS_USER:$API_TOKEN