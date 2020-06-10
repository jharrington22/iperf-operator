package iperf

import (
	"fmt"
	"strconv"
)

// ClientConfiguration for iPerf client
type ClientConfiguration struct {
	sessionDuration     int
	parallelConnections int
	targetBandwidth     float64
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
