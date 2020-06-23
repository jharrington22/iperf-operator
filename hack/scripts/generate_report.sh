#!/bin/bash

TOTAL_REQUESTS=0
TIME_STAMP=$(date +%d%m%Y-%H%M%S)
NAMESPACE=iperf-operator


DESIRED_COMPLETED_IPERF_JOBS=$(oc get iperf iperf-test -n "$NAMESPACE" -o json | jq '.spec.clientNum')
DESIRED_COMPLETED_CLIENT_JOBS=$(oc get nodes -l node-role.kubernetes.io/worker="" -o json | jq '[ .items[].metadata.name ] | length')

COMPLETED_IPERF_JOBS=$(oc get jobs -n "$NAMESPACE" -o json | jq '[ .items[] |  select(.metadata.name|test("iperf-client")) | select(.status.succeeded==1) | .metadata.name ] | length')
COMPLETED_CLIENT_JOBS=$(oc get jobs -n "$NAMESPACE" -o json | jq '[ .items[] |  select(.metadata.name|test("testclient")) | select(.status.succeeded==1) | .metadata.name ] | length')

if [ "$COMPLETED_IPERF_JOBS" != "$DESIRED_COMPLETED_IPERF_JOBS" ]; then
    echo "Failed only $COMPLETED_IPERF_JOBS completed out of $DESIRED_COMPLETED_IPERF_JOBS"
    exit 1
fi

if [ "$COMPLETED_CLIENT_JOBS" != "$DESIRED_COMPLETED_CLIENT_JOBS" ]; then
    echo "Failed only $COMPLETED_CLIENT_JOBS completed out of $DESIRED_COMPLETED_CLIENT_JOBS"
    exit 1
fi

IFS='
'

for p in $(oc get jobs -n "$NAMESPACE" | grep testclient | awk '{print $1}')
do
  for log in $(oc logs jobs/"$p" -n "$NAMESPACE" | jq -r '. | "\(.time_total), \(.http_code), \(.num_connects)"')
  do
      echo "$i, $log" >> run_"${TIME_STAMP}".csv
    ((i++))
  done
done



for p in $(oc get jobs -n "$NAMESPACE" | grep testclient | awk '{print $1}')
do
    TOTAL_REQUESTS=$(("$TOTAL_REQUESTS" + $(oc logs jobs/"$p" -n "$NAMESPACE" | wc -l)))
done

echo "Total requests: $TOTAL_REQUESTS"
