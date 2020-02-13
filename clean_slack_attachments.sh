#!/bin/bash
#PARCHEMIN
#NOT FINALIZED

SLACK_TOKEN=''
USER_ID='OWNER_ID' # OR CHANNEL_ID TO CLEAN ATTACHMENT
TREATMENT_FILE="/tmp/${USER_ID}.treatment"
TMP_FILE="/tmp/${USER_ID}.tmp"
if [ -z ${1} ]
then
  CHANNEL_ID='CHANNEL_DEFAULT_ID'
else
  CHANNEL_ID="${1}"
  echo "Launching cleanup on $CHANNEL_ID"
fi
curl "https://slack.com/api/conversations.history?token=${SLACK_TOKEN}&channel=${CHANNEL_ID}&limit=500" | jq . | egrep -A 1 "\"user\": \"${USER_ID}\"" | egrep -o '"ts": "[0-9\.]+"' | sed -r "s@.*\"([0-9\.]+)\".*@\1@" > ${TREATMENT_FILE}
date
while read line; do curl "https://slack.com/api/chat.delete?token=${SLACK_TOKEN}&channel=${CHANNEL_ID}&ts=${line}"; done < ${TREATMENT_FILE}
date
exit

### CLEANING ATTACHMENTS PART
TYPES='all'
TOTAL_PAGE=`curl "https://slack.com/api/files.list?token=${SLACK_TOKEN}&channel=${USER_ID}&count=100&types=${TYPES}" | sed -r "s@.*\"pages\":([0-9]+)\}\}@\1@"`
for PAGE in `eval echo "{${TOTAL_PAGE}..1}"`
do
    echo "Treatment ${PAGE}/${TOTAL_PAGE}"
    curl "https://slack.com/api/files.list?token=${SLACK_TOKEN}&channel=${USER_ID}&types=${TYPES}&count=100&page=${PAGE}" > ${TMP_FILE}
    jq . ${TMP_FILE} | egrep -o '"id": "[A-Z0-9]+"' | sed -e 's@ @@' -e 's@id@file@' > ${TREATMENT_FILE}
    while read line; do curl -X POST 'https://slack.com/api/files.delete' -H "Authorization: Bearer ${SLACK_TOKEN}" -H 'Content-type: application/json; charset=utf-8' --data "{ ${line} }"; done < ${TREATMENT_FILE}
done
