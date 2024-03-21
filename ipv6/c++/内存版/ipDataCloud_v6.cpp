// #include "stdafx.h"
#include "ipDataCloud_v6.h"
#include "string.h"
#include <stdlib.h>
#include <vector>
#include <iostream>  
#include <sstream>
#include <bitset>
#include <algorithm>
#include <iomanip>
#include <cstdint>
#include "uint128_t.h"


char *IPV6_FILENAME = "F:\\ipv6_city.dat";


geo_ipv6 *ipv6_instance()
{
	geo_ipv6 *ret = (geo_ipv6 *)malloc(sizeof(geo_ipv6));
	if (ipv6_loadDat(ret) >= 0)
	{
		return ret;
	}

	if (ret)
	{
		free(ret);
	}
	return NULL;
}

int deleteChar(char *s, char c)
{
	if (NULL == s)
	{
		return -1;
	}
	else
	{
		char *f = s;
		int i = 0, j = 0;
		while (*s)
		{
			i++;
			if (*s != c)
			{
				j++;
				*f = *s;
				f++;
			}
			s++;
		}
		*f = '\0';
		if (i == j)
			return 0;
		return i - j;
	}
}

int32_t ipv6_loadDat(geo_ipv6 *p)
{
	FILE *file;
	uint8_t *data;
	uint32_t len = 0;
	uint32_t k;
	int i, j;
	uint32_t RecordSize, offset, length;
	errno_t err = fopen_s(&file, IPV6_FILENAME, "rb");
	if (err == 2)
	{
		printf("%s", "There is no such file or directory");
		return -2;
	}
	fseek(file, 0, SEEK_END);
	len = ftell(file);
	fseek(file, 0, SEEK_SET);
	data = (uint8_t *)malloc(len * sizeof(uint8_t));
	fread(data, 1, len, file);
	fclose(file);

	long numbers = ipv6_read_int32(p,data,4);

	for (k = 0; k < numbers; k++)
	{
		i = k * 12 + 4 + 4;
		p->prefStart[ipv6_read_int32(p, data, i+8)] = ipv6_read_int32(p, data, i);
		p->prefEnd[ipv6_read_int32(p, data, i + 8)] = ipv6_read_int32(p, data, i + 4);
	}

	RecordSize = ipv6_read_int32(p, data, 0);
	p->endArr = (char **)malloc(RecordSize * sizeof(char*));
	p->addrArr = (char **)malloc(RecordSize * sizeof(char*));
	for (i = 0; i < RecordSize; i++)
	{
		j = numbers*12 + 4 + 4 + (i * 55);
		
		offset = ipv6_read_int32(p, data, j + 50);
		length = (uint32_t)data[4 + j + 50];

		char *resultEnd = (char *)malloc((50) * sizeof(char));
		memcpy(resultEnd, data + j, 50);
		resultEnd[49] = '\0';
		int delCount = deleteChar(resultEnd, '*');
		//uint128_t resultU128 = uint128_t::uint128_t(resultEnd, 10);

		p->endArr[i] = resultEnd;

		char *result = (char *)malloc((length + 1) * sizeof(char));
		memcpy(result, data + offset, length);
		result[length] = '\0';
		p->addrArr[i] = result;
	}

	return 0;
}

std::vector<std::string> split(const std::string& s, char delimiter) {
	std::vector<std::string> tokens;
	std::string token;
	std::istringstream tokenStream(s);
	while (std::getline(tokenStream, token, delimiter)) {
		tokens.push_back(token);
	}
	return tokens;
}

long getPref(char* ip) {
	std::string str_ip = ip;
	int index = str_ip.find(":");
	str_ip = str_ip.substr(0, index);
	long pref = strtoll(str_ip.c_str(), NULL,16);
	return pref;
}

std::string expandIPv6(const std::string& ipv6) {
	std::vector<std::string> parts = split(ipv6, ':');
	std::string expandedIPv6;

	size_t emptyBlockIndex = ipv6.find("::");
	if (emptyBlockIndex != std::string::npos) {
		std::vector<std::string> firstHalf;
		std::vector<std::string> secondHalf;

		if (emptyBlockIndex > 0) {
			std::string firstPart = ipv6.substr(0, emptyBlockIndex);
			firstHalf = split(firstPart, ':');
		}
		if (emptyBlockIndex + 2 <= parts.size()) {
			std::string secondPart = ipv6.substr(emptyBlockIndex + 2);
			secondHalf = split(secondPart, ':');
		}

		for (const auto& part : firstHalf) {
			if (!part.empty()) {
				std::stringstream ss(part);
				uint16_t value;
				ss >> std::hex >> value;
				std::ostringstream formattedPart;
				formattedPart << std::setw(4) << std::setfill('0') << std::hex << value;
				expandedIPv6 += formattedPart.str() + ":";
			}
		}

		size_t zeroBlocks = 8 - firstHalf.size() - secondHalf.size();
		for (size_t i = 0; i < zeroBlocks; ++i) {
			expandedIPv6 += "0000:";
		}

		for (const auto& part : secondHalf) {
			if (!part.empty()) {
				std::stringstream ss(part);
				uint16_t value;
				ss >> std::hex >> value;
				std::ostringstream formattedPart;
				formattedPart << std::setw(4) << std::setfill('0') << std::hex << value;
				expandedIPv6 += formattedPart.str() + ":";
			}
		}
	}
	else {
		expandedIPv6 = ipv6;
	}

	if (!expandedIPv6.empty() && expandedIPv6.back() == ':') {
		expandedIPv6.pop_back();
	}

	return expandedIPv6;
}

uint128_t ipv6ToInt(const std::string& ipv6) {
	std::vector<uint16_t> parts;
	std::stringstream ss(ipv6);
	std::string part;
	while (std::getline(ss, part, ':')) {
		if (!part.empty()) {
			uint16_t value;
			std::stringstream converter(part);
			converter >> std::hex >> value;
			parts.push_back(value);
		}
	}

	uint128_t result = 0;
	for (const auto& part : parts) {
		result = (result << 16) | part;
	}

	return result;
}

char *ipv6_query(geo_ipv6 *p, char *ip)
{
	uint32_t pref, cur, low, high;
	uint128_t intIP;
	if (NULL == p)
	{
		return NULL;
	}
	
	pref = getPref(ip);;
	intIP = ipv6ToInt(expandIPv6(ip));
	low = p->prefStart[pref];
	high = p->prefEnd[pref];
	cur = (low == high) ? low : ipv6_binary_search(p, low, high, intIP);
	return p->addrArr[cur];
}

long ipv6_binary_search(geo_ipv6 *p, long low, long high, uint128_t k)
{
	long M = 0;
	while (low <= high)
	{
		long mid = (low + high) / 2;

		uint128_t endipNum = uint128_t::uint128_t(p->endArr[mid],10);
		if (endipNum >= k)
		{
			M = mid;
			if (mid == 0)
			{
				break;
			}
			high = mid - 1;
		}
		else
			low = mid + 1;
	}
	return M;
}


uint32_t ipv6_read_int32(geo_ipv6 *p, uint8_t *buf, int pos)
{
	uint32_t result;
	result = (uint32_t)((buf[pos]) | (buf[pos + 1] << 8) | (buf[pos + 2] << 16) | (buf[pos + 3] << 24));
	return result;
}
