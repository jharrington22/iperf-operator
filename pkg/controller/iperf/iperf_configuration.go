package iperf

import (
	"fmt"
	"strconv"

	iperfv1alpha1 "github.com/jharrington22/iperf-operator/pkg/apis/iperf/v1alpha1"
)

// ClientConfiguration for iPerf client
type ClientConfiguration struct {
	sessionDuration     int
	parallelConnections int
	targetBandwidth     float64
	clientNum           int
	serverNum           int
}

func newClientConfiguration(workerNodeCount int, cr *iperfv1alpha1.Iperf) *ClientConfiguration {
	var clientNum int
	var serverNum int
	if cr.Spec.ClientNum == 0 {
		clientNum = 1
	} else {
		clientNum = cr.Spec.ClientNum
	}
	if cr.Spec.ServerNum == 0 {
		serverNum = 1
	} else {
		serverNum = cr.Spec.ServerNum
	}

	parallelConnections := cr.Spec.ParallelConnections / clientNum

	// Fetch configuration for iPerf client/server's
	return &ClientConfiguration{
		clientNum:           clientNum,
		serverNum:           serverNum,
		sessionDuration:     cr.Spec.SessionDuration,
		parallelConnections: parallelConnections / (workerNodeCount * clientNum),
		// Set target bandwidth per paralel connecitons per client
		targetBandwidth: float64(cr.Spec.TargetBandwidth) / float64(parallelConnections),
	}

}

// buildIperfClientCmd returns a slice containing iPerf client arguments
func (i *ClientConfiguration) buildIClientCmd(iperfServerAddress string) []string {
	args := []string{
		// Client flag
		"-c",
		// Client endpoint
		iperfServerAddress,
		// Session durtation in seconds
		"-t",
		strconv.Itoa(i.sessionDuration),
		// Number of parallel conecctions for this client
		"-P",
		strconv.Itoa(i.parallelConnections),
	}

	targetBandwidth := []string{
		// Target bandwidth for this client in Mbits per second
		"-b",
		fmt.Sprintf("%.2f", i.targetBandwidth) + "M",
	}

	// Add target bandwdith argument if set
	if i.targetBandwidth > 0 {
		args = append(args, targetBandwidth...)
	}

	return args
}
