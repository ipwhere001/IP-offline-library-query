# -*- coding: utf-8 -*-

import mmap
import struct
import socket
from IPy import IP as IPI


class IP:
    def __init__(self, file_name):
        self._handle = open(file_name, "rb")
        self.data = mmap.mmap(self._handle.fileno(), 0, access=mmap.ACCESS_READ)
        self.prefArr = {}
        self.record_size = self.unpack_int_4byte(0)
        self.numbers = self.unpack_int_4byte(4)
        i = 0
        while i < self.numbers:
            p = i * 12 + 4 + 4
            self.prefArr[self.unpack_int_4byte(p + 4 + 4)] = [self.unpack_int_4byte(p), self.unpack_int_4byte(p + 4)]
            i += 1
        self.endArr = []
        j = 0
        while j < self.record_size:
            p = self.numbers * 12 + 4 + 4 + (j * 55)
            self.endArr.append(int(self.data[p:p + 50].decode('utf-8').replace("*", "")))
            j += 1

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, exc_tb):
        self.close()

    def close(self):
        self._handle.close()

    def get(self, ip):
        ipdot = ip.split(':')
        prefix = int(ipdot[0], 16)
        try:
            intIP = IPI(ip).int()
        except:
            return "IPV6格式错误"
        if prefix not in self.prefArr:
            return "未知"
        low = self.prefArr[prefix][0]
        high = self.prefArr[prefix][1]
        cur = low if low == high else self.search(low, high, intIP)
        if cur > self.record_size:
            return "未知"
        return self.get_addr(cur)

    def search(self, low, high, k):
        M = 0
        while low <= high:
            mid = (low + high) // 2
            end_ip_num = self.endArr[mid]
            if end_ip_num >= k:
                M = mid
                if mid == 0:
                    break
                high = mid - 1
            else:
                low = mid + 1

        return M

    def get_addr(self, cur):
        p = self.numbers * 12 + 4 + 4 + (cur * 55)
        offset = self.unpack_int_4byte(p + 50)
        length = self.unpack_int_1byte(50 + p + 4)
        return self.data[offset:offset + length].decode('utf-8')

    def ip_to_int(self, ip):
        _ip = socket.inet_aton(ip)
        return struct.unpack("!L", _ip)[0]

    def unpack_int_4byte(self, offset):
        return struct.unpack('<L', self.data[offset:offset + 4])[0]

    def unpack_int_1byte(self, offset):
        return struct.unpack('B', self.data[offset:offset + 1])[0]
