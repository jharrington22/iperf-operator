package iperf

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
)

const (
	iperfServerImage        = "quay.io/jharrington22/network-toolbox:latest"
	iperfClientImage        = "quay.io/jharrington22/network-toolbox:latest"
	iperfCmd                = "iperf"
	nodeSelectorKey         = "kubernetes.io/hostname"
	nodeWorkerSelectorKey   = "node-role.kubernetes.io/worker"
	nodeWorkerSelectorValue = ""
)

var (
	gracePeriodSeconds = int64(0)
	selector           = map[string]string{
		"app": "iperf-server",
	}
)

func generateServerPod(namespacedName types.NamespacedName, nodeSelectorValue string) *corev1.Pod {
	return &corev1.Pod{
		TypeMeta: metav1.TypeMeta{
			Kind:       "Pod",
			APIVersion: "v1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      namespacedName.Name,
			Namespace: namespacedName.Namespace,
			Labels:    selector,
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				{
					Name:    "iperf-server",
					Image:   iperfServerImage,
					Command: []string{"/bin/bash"},
					//Command: []string{iperfCmd},
					//Args:    []string{"-c", "sleep 10 && iperf -s -p 5001 -B $(ifconfig | grep -oE \\ 10\\.[0-9]+\\.[0-9]+\\.[0-9]+\\ )"},
					Args: []string{"-c", "sleep 10 && iperf -s -p 5001 -B 0.0.0.0"},
					//Args: []string{"iperf", "-s", "-p", "5001", "-B", "0.0.0.0"},
					Ports: []corev1.ContainerPort{
						{
							ContainerPort: 5001,
							Protocol:      corev1.ProtocolTCP,
						},
					},
				},
			},
			NodeSelector: map[string]string{
				nodeSelectorKey: nodeSelectorValue,
			},
			TerminationGracePeriodSeconds: &gracePeriodSeconds,
		},
	}

}

func generateClientPod(namespacedName types.NamespacedName, podIP, nodeSelectorValue, sessionDuration, concurrentConnections string) *corev1.Pod {
	return &corev1.Pod{
		TypeMeta: metav1.TypeMeta{
			Kind:       "Pod",
			APIVersion: "v1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      namespacedName.Name,
			Namespace: namespacedName.Namespace,
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				{
					Name:    "iperf-client",
					Image:   iperfClientImage,
					Command: []string{iperfCmd},
					Args:    []string{"-c", podIP, "-t", sessionDuration, "-P", concurrentConnections},
				},
			},
			NodeSelector: map[string]string{
				nodeSelectorKey: nodeSelectorValue,
			},
			TerminationGracePeriodSeconds: &gracePeriodSeconds,
		},
	}

}

func generateIperfService() *corev1.Service {
	return &corev1.Service{
		TypeMeta: metav1.TypeMeta{
			Kind:       "Service",
			APIVersion: "v1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      "iperf-service",
			Namespace: "iperf-operator",
		},
		Spec: corev1.ServiceSpec{
			Selector: selector,
			Ports: []corev1.ServicePort{
				{
					Port: 5001,
				},
			},
		},
	}
}
