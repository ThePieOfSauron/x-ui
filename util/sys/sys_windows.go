//go:build windows
// +build windows

package sys

import (
	"github.com/shirou/gopsutil/net"
)

func GetTCPCount() (int, error) {
	connections, err := net.Connections("tcp")
	if err != nil {
		return 0, err
	}
	return len(connections), nil
}

func GetUDPCount() (int, error) {
	connections, err := net.Connections("udp")
	if err != nil {
		return 0, err
	}
	return len(connections), nil
}
