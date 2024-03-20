package ipv6distreet

import (
	"errors"
	"io/ioutil"
	"log"
	"math/big"
	"net"
	"strconv"
	"strings"
	"sync"
)

type IpInfoV6 struct {
	prefStart map[uint32]uint32
	prefEnd   map[uint32]uint32
	endArr    []*big.Int
	addrArr   []string
}

var objV6 *IpInfoV6
var onceV6 sync.Once

func GetDistrictObjectV6() *IpInfoV6 {
	onceV6.Do(func() {
		objV6 = &IpInfoV6{}
		var err error
		objV6, err = LoadFileV6("conf/ipv6_district.dat")
		if err != nil {
			log.Fatal("the IP Dat loaded failed!ipv6_district.dat")
		}
	})
	return objV6
}

func LoadFileV6(file string) (*IpInfoV6, error) {
	p := IpInfoV6{}
	data, err := ioutil.ReadFile(file)
	if err != nil {
		return nil, err
	}

	numbers := UnpackInt4byteV6(data[4], data[5], data[6], data[7])
	p.prefStart = make(map[uint32]uint32)
	p.prefEnd = make(map[uint32]uint32)
	for k := uint32(0); k < numbers; k++ {
		i := k*12 + 4 + 4
		p.prefStart[UnpackInt4byteV6(data[i+8], data[i+9], data[i+10], data[i+11])] = UnpackInt4byteV6(data[i], data[i+1], data[i+2], data[i+3])
		p.prefEnd[UnpackInt4byteV6(data[i+8], data[i+9], data[i+10], data[i+11])] = UnpackInt4byteV6(data[i+4], data[i+5], data[i+6], data[i+7])

	}

	RecordSize := UnpackInt4byteV6(data[0], data[1], data[2], data[3])

	p.endArr = make([]*big.Int, RecordSize)
	p.addrArr = make([]string, RecordSize)
	for i := uint32(0); i < RecordSize; i++ {
		j := numbers*12 + 4 + 4 + (i * 55)
		
		offset := UnpackInt4byteV6(data[j+50], data[1+j+50], data[2+j+50], data[3+j+50])
		length := uint32(data[50+j+4])
		endipnum := new(big.Int)
		endipnumInt, _ := endipnum.SetString(strings.ReplaceAll(string(data[j:j+50]), "*", ""), 10)

		p.endArr[i] = endipnumInt
		p.addrArr[i] = string(data[offset:int(offset+length)])
	}
	return &p, err

}

func (p *IpInfoV6) GetV6(ip string) (string, error) {
	ips := strings.Split(ip, ":")

	parseUint, _ := strconv.ParseUint(ips[0], 16, 32)

	
	prefix := uint32(parseUint)

	intIP, err := ipToIntV6(ip)
	if err != nil {
		return "", err
	}

	low := p.prefStart[prefix]
	high := p.prefEnd[prefix]

	var cur uint32
	if low == high {
		cur = low
	} else {
		cur = p.SearchV6(low, high, intIP)
	}

	return p.addrArr[cur], nil

}

func (p *IpInfoV6) SearchV6(low uint32, high uint32, k *big.Int) uint32 {
	var M uint32 = 0
	for low <= high {
		mid := (low + high) / 2
		endipNum := p.endArr[mid]
		if endipNum.Cmp(k) == 0 || endipNum.Cmp(k) == 1 {
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

func ipToIntV6(ipstr string) (*big.Int, error) {
	ip := net.ParseIP(ipstr)
	ip = ip.To16()
	
	if ip == nil {
		return big.NewInt(0), errors.New("invalid ipv6")
	}
	IPv6Int := big.NewInt(0)
	IPv6Int.SetBytes(ip)
	return IPv6Int, nil
}

func UnpackInt4byteV6(a, b, c, d byte) uint32 {
	return (uint32(a) & 0xFF) | ((uint32(b) << 8) & 0xFF00) | ((uint32(c) << 16) & 0xFF0000) | ((uint32(d) << 24) & 0xFF000000)
}
