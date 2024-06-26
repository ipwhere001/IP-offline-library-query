package ipdatacloud

import (
	"encoding/binary"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"strconv"
	"strings"
	"sync"
)

type IpInfo struct {
	prefStart [256]uint32
	prefEnd   [256]uint32
	endArr    []uint32
	addrArr   []string
	data      []byte
}

var obj *IpInfo
var once sync.Once

func GetObject() *IpInfo {
	once.Do(func() {
		obj = &IpInfo{}
		var err error
		obj, err = LoadFile("your file path")
		if err != nil {
			log.Fatal("the IP Dat loaded failed!")
		}
	})
	return obj
}

func LoadFile(file string) (*IpInfo, error) {
	p := IpInfo{}
	data, err := ioutil.ReadFile(file)
	p.data = data
	if err != nil {
		return nil, err
	}

	for k := 0; k < 256; k++ {
		i := k*8 + 4
		p.prefStart[k] = UnpackInt4byte(data[i], data[i+1], data[i+2], data[i+3])
		p.prefEnd[k] = UnpackInt4byte(data[i+4], data[i+5], data[i+6], data[i+7])
	}

	RecordSize := int(UnpackInt4byte(data[0], data[1], data[2], data[3]))

	p.endArr = make([]uint32, RecordSize)
	for i := 0; i < RecordSize; i++ {
		j := 2052 + (i * 9)
		endipnum := UnpackInt4byte(data[j], data[1+j], data[2+j], data[3+j])

		p.endArr[i] = endipnum
	}
	return &p, err

}

func (p *IpInfo) Get(ip string) (string, error) {
	ips := strings.Split(ip, ".")
	x, _ := strconv.Atoi(ips[0])
	prefix := uint32(x)
	intIP, err := ipToInt(ip)
	if err != nil {
		return "", err
	}

	low := p.prefStart[prefix]
	high := p.prefEnd[prefix]

	var cur uint32
	if low == high {
		cur = low
	} else {
		cur = p.Search(low, high, intIP)
	}
	if cur == 100000000 {
		return "无信息", errors.New("无信息")
	} else {
		return p.getAddr(cur), nil
	}

}

func (p *IpInfo) Search(low uint32, high uint32, k uint32) uint32 {
	var M uint32 = 0
	for low <= high {
		mid := (low + high) / 2
		endipNum := p.endArr[mid]
		if endipNum >= k {
			M = mid
			if mid == 0 {
				break
			}
			high = mid - 1
		} else {
			low = mid + 1
		}
	}

	return M
}

func (p *IpInfo) getAddr(cur uint32) string {
	j := 2052 + (cur * 9)
	offset := UnpackInt4byte(p.data[4+j], p.data[5+j], p.data[6+j], p.data[7+j])
	length := uint32(p.data[8+j])
	return string(p.data[offset:int(offset+length)])
}

func ipToInt(ipstr string) (uint32, error) {
	ip := net.ParseIP(ipstr)
	ip = ip.To4()
	if ip == nil {
		return 0, errors.New("ip 不合法")
	}
	return binary.BigEndian.Uint32(ip), nil
}

func UnpackInt4byte(a, b, c, d byte) uint32 {
	return (uint32(a) & 0xFF) | ((uint32(b) << 8) & 0xFF00) | ((uint32(c) << 16) & 0xFF0000) | ((uint32(d) << 24) & 0xFF000000)
}
