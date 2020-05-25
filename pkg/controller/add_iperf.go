package controller

import (
	"github.com/jharrington22/iperf-operator/pkg/controller/iperf"
)

func init() {
	// AddToManagerFuncs is a list of functions to create controllers and add them to a manager.
	AddToManagerFuncs = append(AddToManagerFuncs, iperf.Add)
}
